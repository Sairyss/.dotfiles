"""A global broot sidebar for herdr.
Usage: sidebar.py toggle | on | off | sync | focus | watch

  toggle/on/off  switch the sidebar for ALL workspaces (the file `enabled` in the runtime dir, see below), then sync
  sync           one idempotent pass: every tab of every workspace gets exactly one sidebar pane (label "broot-sidebar") on its
                 right, created ahead of time so switching tabs or workspaces is instant; broot is told to :focus the directory of
                 the tab's focused pane. When switched off, all sidebar panes are closed. A tab left with only its sidebar
                 (the last real pane closed) loses the sidebar too, so the tab closes: it is transparent.
  focus          focus this tab's sidebar; from the sidebar itself, back to the pane next to it
  watch          long-lived: runs sync after bursts of tab/workspace/pane events. Started detached by the plugin.

Without a sidebar in the focused tab (SKIP_NVIM: tabs with an nvim have none) `toggle` and `focus` drive that nvim's
neo-tree instead, through its socket (nvim/lua/plugins/herdr/neotree.lua): toggle it, focus it, or from it go back.

Tabs that have an nvim are driven by nvim (nvim/lua/plugins/herdr/broot.lua sends the open file to the sidebar through
panes.json in the runtime dir: pane id -> broot socket name of its tab), so the cwd following is skipped there.
Unless HERDR_BROOT_SIDEBAR_NVIM_FOLLOW=1 none of that happens: no panes.json, no looking for nvims, the cwd is followed
everywhere.

The sidebar is a declarative plugin pane (see the manifest): herdr starts broot itself, with no shell. A restored
session (plain shells with the label, no tokens) is healed on the next pass: see sync().

Everything it keeps (the on/off switch, locks, panes.json, last directories) is in $XDG_RUNTIME_DIR/herdr-broot-sidebar, i.e.
memory: nothing is written to disk. The sidebar is on by default; only an explicit `off` (cleared by a reboot) switches it off.

Settings (environment): HERDR_BROOT_SIDEBAR_RATIO (width of the sidebar, default 0.20), HERDR_BROOT_SIDEBAR_SIDE (right, the default, or left),
HERDR_BROOT_SIDEBAR_HIDE_FOR (programs that take over the terminal, like yazi or btop: no sidebar in a tab while one
runs; by default a built-in list of file managers, monitors and git UIs, see DEFAULT_HIDE; empty means never),
HERDR_BROOT_SIDEBAR_SKIP_NVIM (default 1; 0 turns it off. 1: no sidebar in tabs that run nvim, which keeps its own file tree; then nvim does
not talk to broot at all, and files opened from broot elsewhere still go to the right nvim),
HERDR_BROOT_SIDEBAR_NVIM_FOLLOW (default 0; 1 turns on the following of nvim's open file, see above; nvim reads it too),
HERDR_BROOT_SIDEBAR_CMD (the broot executable, no arguments; default: $BROOT_BIN, then broot from PATH).
Needs python 3.11+, broot and herdr. A pane is one tab's split, so "global" means one pane per tab, all switched together; a pane you exit by hand comes back on the next event (use toggle to hide it).
Note: the sidebar is a normal pane; the directory follows the focused non-sidebar pane's foreground cwd."""
import fcntl
import json
import os
import re
import select
import secrets
import shutil
import socket
import subprocess
import sys
import time

HERDR = os.environ.get("HERDR_BIN_PATH") or shutil.which("herdr") or "herdr"
XDG_CONFIG = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
# Everything this plugin keeps is small, changes often and is worthless after a reboot (sockets, locks, which
# sidebar belongs to which tab), so it lives in the runtime dir, which is memory (tmpfs): nothing reaches the disk.
# nvim/lua/plugins/herdr/broot.lua builds the same path. $XDG_RUNTIME_DIR, else a per-user dir under the temp dir.
_runtime = os.environ.get("XDG_RUNTIME_DIR")
RUN_DIR = os.path.join(_runtime, "herdr-broot-sidebar") if _runtime else os.path.join(
    os.environ.get("TMPDIR") or "/tmp", "herdr-broot-sidebar-%d" % os.getuid())
SOCKET = os.environ.get("HERDR_SOCKET_PATH") or os.path.join(XDG_CONFIG, "herdr/herdr.sock")
# The sidebar's width as a share of the split it is created in (it opens at half and is resized to this)
WIDTH = float(os.environ.get("HERDR_BROOT_SIDEBAR_RATIO", "0.20"))
# which side of the tab the sidebar is on: right (default) or left
LEFT = os.environ.get("HERDR_BROOT_SIDEBAR_SIDE", "right").lower() == "left"
PLUGIN_ID = os.environ.get("HERDR_PLUGIN_ID") or "herdr-broot-sidebar"
# Tabs that run nvim get no sidebar (nvim has its own file tree there, e.g. neo-tree): HERDR_BROOT_SIDEBAR_SKIP_NVIM
# on by default; 0/false/no/off turns it off. nvim/lua/plugins/herdr/broot.lua reads the same variable and default, so set it where both see it.
SKIP_NVIM = os.environ.get("HERDR_BROOT_SIDEBAR_SKIP_NVIM", "1").lower() not in ("0", "false", "no", "off", "")
# nvim sends its open file to the sidebar (nvim/lua/plugins/herdr/broot.lua reads the same variable and default). Off (default):
# no panes.json is written and tabs with an nvim are not told apart (unless SKIP_NVIM needs that), so there is no
# per-pane socket probing for it.
NVIM_FOLLOW = os.environ.get("HERDR_BROOT_SIDEBAR_NVIM_FOLLOW", "0").lower() in ("1", "true", "yes", "on")
# Programs that take over the terminal: a tab where one of them runs gets no sidebar (it comes back when the program
# exits). File managers (broot itself too: a second tree beside ours is noise) and full-screen monitors and git UIs;
# not nvim (HERDR_BROOT_SIDEBAR_SKIP_NVIM decides about it) and not the short-lived pagers and pickers (less, man,
# fzf ...), which would make the sidebar blink away and back with every `git log` or history search.
# HERDR_BROOT_SIDEBAR_HIDE_FOR replaces the list (space or comma separated names; empty = never).
DEFAULT_HIDE = ("broot yazi ranger nnn lf mc vifm xplr ncdu btop htop top btm glances nvtop lazygit lazydocker "
                "k9s tig")


def hide_for():
    env = os.environ.get("HERDR_BROOT_SIDEBAR_HIDE_FOR")
    return {w.lower() for w in re.split(r"[\s,]+", DEFAULT_HIDE if env is None else env) if w}


LABEL = "broot-sidebar"
# pane token that tells herdr-run (herdr-task-runner) this pane is not where you work: its tab still counts as idle
# and commands go to the pane next to it. Set on every sidebar pane; the token is gone when herdr restarts, like the pane.
TRANSPARENT = ("--source", LABEL, "--token", "transparent=1")
EVENTS = ["tab.focused", "tab.created", "tab.closed", "workspace.created", "workspace.focused",
          "workspace.closed", "pane.focused", "pane.updated", "pane.closed", "pane.exited"]
# events that must not wait for the debounce: a tab that comes into view (a focused sidebar must not greet you), a pane that closes may leave its tab with only the sidebar (which has to
# go now), and a new tab or workspace should get its sidebar at once, not after the quiet period
URGENT_EVENTS = (b"tab.focused", b"tab_focused", b"pane.closed", b"pane_closed", b"pane.exited", b"pane_exited",
                 b"tab.created", b"tab_created", b"workspace.created", b"workspace_created")
OFF = os.path.join(RUN_DIR, "off")  # the switch: on by default, off only while this exists (after an explicit `off`)
PANES = os.path.join(RUN_DIR, "panes.json")  # pane id -> socket name of the sidebar in its tab (read by nvim)
ACTIVE = os.path.join(RUN_DIR, "active-tab")  # the tab that was in view at the last pass
LAST = os.path.join(RUN_DIR, "last-dir.json")  # sidebar pane id -> directory broot was last pointed at
INSTANCE_KEY = "_instance"  # in LAST: the herdr server the ids belong to


def herdr(*args, check=True):
    """Run the herdr CLI and return its parsed JSON `result` (None when it printed nothing)."""
    p = subprocess.run([HERDR, *args], capture_output=True, text=True)
    if p.returncode != 0:
        if check:
            raise RuntimeError(f"herdr {' '.join(args)}: {p.stderr.strip() or p.stdout.strip()}")
        return None
    try:
        return json.loads(p.stdout).get("result")
    except ValueError:
        return None


def broot_cmd():
    """The broot executable (no arguments: put those in broot's own config); the caller adds a short socket name."""
    return os.environ.get("HERDR_BROOT_SIDEBAR_CMD") or os.environ.get("BROOT_BIN") or shutil.which("broot") or "broot"


def new_sock():
    """The name a new sidebar's broot listens on. Chosen before the pane exists (herdr starts broot itself), so it
    cannot be derived from the pane id any more: the registry keeps it. Short, as the whole path must fit SUN_LEN."""
    return "hbs-" + secrets.token_hex(4)


def sock_name(pane_id):
    # sidebars of older versions: typed into a shell, listening on a name made from their pane id
    # broot puts the socket in its own directory but the whole path must fit SUN_LEN, so keep the name short
    return "hbs-" + re.sub(r"[^A-Za-z0-9]", "", pane_id)


def runs_broot(pane_id):
    """Is broot (or whatever HERDR_BROOT_SIDEBAR_CMD is) already the foreground process of the pane?"""
    want = os.path.basename(broot_cmd())
    info = herdr("pane", "process-info", "--pane", pane_id, check=False) or {}
    procs = (info.get("process_info") or {}).get("foreground_processes") or []
    return any((q.get("name") or "").lstrip("-") == want for q in procs)


def nvim_sock(pane_id):
    d = os.environ.get("XDG_RUNTIME_DIR") or os.environ.get("TMPDIR") or "/tmp"
    return f"{d}/herdr-nvim-{re.sub(r'[^A-Za-z0-9]', '_', pane_id)}.sock"


def nvim_alive(pane_id):
    """Is an nvim running in this pane? The nvim config of this repo (nvim/lua/plugins/herdr/server.lua, which defines
    the socket naming convention) listens on a socket named after the pane id, from the first moment of startup: no
    waiting for the terminal title, no guessing from process names (wrappers, aliases). Without that config there is
    no such socket and the sidebar simply stays. A crashed nvim leaves the file behind, so only a socket that accepts
    a connection counts."""
    try:
        with socket.socket(socket.AF_UNIX) as c:
            c.settimeout(0.2)
            c.connect(nvim_sock(pane_id))
        return True
    except OSError:
        return False


def runs_hidden_app(p):
    """Does a pane run one of the hide_for() programs in the foreground? The foreground processes are asked, not the
    terminal title: many file managers (broot, nnn, lf ...) never set one, so a title still showing the shell prompt
    proves nothing."""
    names = hide_for()
    if not names:
        return False
    info = herdr("pane", "process-info", "--pane", p["pane_id"], check=False) or {}
    procs = (info.get("process_info") or {}).get("foreground_processes") or []
    return any((q.get("name") or "").lstrip("-").lower() in names for q in procs)


def is_on():
    """The sidebar is on unless it was switched off (the marker lives in memory, so a reboot turns it on again)."""
    return not os.path.exists(OFF)


def run_dir():
    """Create the runtime dir (private to the user) and return it."""
    os.makedirs(RUN_DIR, mode=0o700, exist_ok=True)
    if os.stat(RUN_DIR).st_uid != os.getuid():  # a shared temp dir: never use someone else's directory
        raise RuntimeError(f"{RUN_DIR} belongs to another user")
    return RUN_DIR


def write_if_changed(path, text):
    """Replace a file atomically (readers never see half of it), but only when its content differs."""
    try:
        with open(path) as f:
            if f.read() == text:
                return
    except OSError:
        pass
    tmp = f"{path}.{os.getpid()}"
    try:
        with open(tmp, "w") as f:
            f.write(text)
        os.replace(tmp, path)
    except OSError:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def server_instance():
    """Identifies the running herdr server: its socket file is new with every start. Pane ids are not stable across
    restarts (a restored pane may get the id a sidebar had before), so the registry is only trusted for the server
    that wrote it."""
    try:
        st = os.stat(SOCKET)
        return "%d-%d" % (st.st_ino, st.st_ctime_ns)
    except OSError:
        return ""


def load_last():
    """The registry of our sidebars: pane id -> {"cwd": where broot was last pointed, "sock": its --listen name}.
    Empty when it was written by another herdr server (see server_instance()). The older formats (no instance mark,
    pane id -> cwd) are read too: their sockets are the ones sock_name() makes."""
    try:
        with open(LAST) as f:
            raw = json.load(f)
    except (OSError, ValueError):
        return {}
    if not isinstance(raw, dict):
        return {}
    inst = raw.pop(INSTANCE_KEY, None)
    if inst is not None and inst != server_instance():
        return {}
    return {k: v if isinstance(v, dict) else {"cwd": v, "sock": sock_name(k)} for k, v in raw.items()}


def save_last(d):
    write_if_changed(LAST, json.dumps({**d, INSTANCE_KEY: server_instance()}, sort_keys=True))


def open_sidebar(ref_id, cwd, last):
    """A sidebar next to ref_id (on its right, or left with HERDR_BROOT_SIDEBAR_SIDE=left): a declarative plugin pane (see the manifest), so herdr starts broot itself."""
    sock = new_sock()
    res = herdr("plugin", "pane", "open", "--plugin", PLUGIN_ID, "--entrypoint", "sidebar", "--placement", "split",
                "--target-pane", ref_id, "--direction", "right", "--cwd", cwd,
                "--env", "HBS_SOCK=" + sock, "--env", "HBS_BROOT=" + broot_cmd(), "--no-focus")
    pid = res["plugin_pane"]["pane"]["pane_id"]
    last[pid] = {"cwd": cwd, "sock": sock}
    save_last(last)  # before anything else can fail or race
    herdr("pane", "rename", pid, LABEL, check=False)  # herdr calls it "Sidebar"; sync() puts the label back if it changes
    herdr("pane", "report-metadata", pid, *TRANSPARENT, check=False)
    if LEFT:  # panes can only be split towards the right or down, so swap the two
        herdr("pane", "swap", "--source-pane", pid, "--target-pane", ref_id, check=False)
        # The focus stays with the place, not the pane, so the sidebar now has it. Giving it back needs the tab to
        # be the one in view (herdr would switch to the tab otherwise): sync() does it once that is the case.
        last[pid]["fresh"] = True
        save_last(last)
    # it opens at half the split: move the divider so it gets WIDTH (a share of the split, as herdr counts it).
    # "right"/"left" is the way the divider moves
    delta = 0.5 - WIDTH
    shrink = "left" if LEFT else "right"
    if abs(delta) > 0.005:
        herdr("pane", "resize", "--pane", pid, "--direction", shrink if delta > 0 else ("right" if LEFT else "left"),
              "--amount", "%.3f" % abs(delta), check=False)
    return pid


def is_sidebar(p, last):
    """Our sidebar? The ids in the registry (valid for this herdr server only), the label, or the transparent mark
    on a pane that another plugin has renamed after its program."""
    return (p["pane_id"] in last or p.get("label") == LABEL
            or ((p.get("tokens") or {}).get("transparent") == "1" and p.get("label") == "broot"))


def sync():
    lock = open(os.path.join(run_dir(), "sync.lock"), "a+")
    fcntl.flock(lock, fcntl.LOCK_EX)  # a toggle and the watcher must not both create panes
    snap = herdr("api", "snapshot")["snapshot"]
    panes = snap["panes"]
    last = load_last()  # sidebar pane id -> directory broot was last pointed at
    side = [p for p in panes if is_sidebar(p, last)]
    if not is_on():
        for p in side:
            herdr("pane", "close", p["pane_id"], check=False)
        save_last({})
        save_panes([], [], [], {})
        return
    layouts = {l["tab_id"]: l for l in snap.get("layouts", [])}
    live = {p["pane_id"] for p in side}
    swapped = False

    def close(p, tab_side):
        herdr("pane", "close", p["pane_id"], check=False)
        live.discard(p["pane_id"])
        last.pop(p["pane_id"], None)
        tab_side.remove(p)

    # One sidebar per tab, created ahead of time: switching tabs then needs no work at all (moving a pane
    # between tabs was visibly slow). Closed tabs take their sidebar with them.
    for tab in snap.get("tabs", []):
        tid = tab["tab_id"]
        mine = [p for p in side if p["tab_id"] == tid]
        others = [p for p in panes if p["tab_id"] == tid and p not in side]
        try:
            if not others:
                # Transparent: the sidebar never keeps a tab alive. When the last real pane is gone (claude exited,
                # the shell was closed) it goes too, and with it the tab.
                for p in list(mine):
                    close(p, mine)
            else:
                swapped = sync_tab(snap, layouts, tid, mine, others, last, live, close) or swapped
        except Exception as e:  # one tab's trouble must not keep the others (or the saved state) from being updated
            print("sync of tab %s failed: %s" % (tid, e), file=sys.stderr)
        side = [p for p in side if p["tab_id"] != tid or p in mine]
    save_last({k: v for k, v in last.items() if k in live})
    save_panes(snap["tabs"], panes, side, last)
    # Coming back to a tab you left with the sidebar focused (prefix+u, then another tab): the focus goes to the pane
    # next to it again. Only when the tab has just come into view, so focusing the sidebar on purpose stays.
    active = snap.get("focused_tab_id")
    try:
        with open(ACTIVE) as f:
            before = f.read()
    except OSError:
        before = None
    if active and active != before:
        write_if_changed(ACTIVE, active)
        sidebars = {p["pane_id"] for p in side}
        if layouts.get(active, {}).get("focused_pane_id") in sidebars:
            herdr("pane", "focus", "--pane", layouts[active]["focused_pane_id"], "--direction",
                  "right" if LEFT else "left", check=False)
    if swapped and snap.get("focused_tab_id"):
        # swapping panes in a tab out of sight also switches to that tab: go back to where you were
        now = (herdr("api", "snapshot", check=False) or {}).get("snapshot") or {}
        if now.get("focused_tab_id") not in (None, snap["focused_tab_id"]):
            herdr("tab", "focus", snap["focused_tab_id"], check=False)


def sync_tab(snap, layouts, tid, mine, others, last, live, close):
    """One tab of sync(): make sure it has exactly one sidebar, or none while it runs nvim or a hide_for() program,
    and point broot at the directory of the focused pane. `mine` (the tab's sidebars) is updated in place. Returns
    whether it swapped panes."""
    focus_id = layouts.get(tid, {}).get("focused_pane_id")
    ref = next((p for p in others if p["pane_id"] == focus_id), others[0])
    cwd = ref.get("foreground_cwd") or ref.get("cwd") or os.path.expanduser("~")
    has_nvim = (SKIP_NVIM or NVIM_FOLLOW) and any(nvim_alive(p["pane_id"]) for p in others)
    # also takes the sidebar away when such a program is started in a tab that has one
    if (SKIP_NVIM and has_nvim) or any(runs_hidden_app(p) for p in others):
        for p in list(mine):
            close(p, mine)
        return False
    for extra in mine[1:]:
        close(extra, mine)
    if mine and (mine[0].get("tokens") or {}).get("transparent") != "1":
        # A sidebar this herdr run did not start. Either broot still runs in it (started by an older version,
        # which typed it into a shell) and it only lacks its mark; or it was restored with the session: herdr
        # keeps a pane's layout, directory and label, but not what ran in it nor its tokens, so it is a plain
        # shell now, and gets replaced by a fresh one in the same place. Only panes that really are ours get here
        # (is_sidebar): ids of the registry are only trusted for the server that wrote them.
        pid = mine[0]["pane_id"]
        if runs_broot(pid):
            herdr("pane", "report-metadata", pid, *TRANSPARENT, check=False)
            last.setdefault(pid, {"cwd": cwd, "sock": sock_name(pid)})
        else:
            close(mine[0], mine)
    swapped = False
    if not mine:
        sid = open_sidebar(ref["pane_id"], cwd, last)
        live.add(sid)
        swapped = LEFT
        had_focus = focus_id == ref["pane_id"]
    else:
        sid, had_focus = mine[0]["pane_id"], focus_id == mine[0]["pane_id"]
        if mine[0].get("label") != LABEL:  # another plugin renamed it: the label is what a restored session finds it by
            herdr("pane", "rename", sid, LABEL, check=False)
        live.add(sid)
    if last.get(sid, {}).get("fresh") and tid == snap.get("focused_tab_id"):
        last[sid].pop("fresh")
        if had_focus:  # a new sidebar on the left took the focus along: back to the pane next to it
            herdr("pane", "focus", "--pane", sid, "--direction", "right", check=False)
    if has_nvim and NVIM_FOLLOW:
        return swapped  # nvim tells broot which file is open (nvim/lua/plugins/herdr/broot.lua): the cwd would fight it
    entry = last.setdefault(sid, {"cwd": None, "sock": sock_name(sid)})
    if entry.get("cwd") != cwd:
        try:
            subprocess.run([broot_cmd(), "--send", entry["sock"], "-c", ":focus " + cwd],
                           capture_output=True, timeout=5)
            entry["cwd"] = cwd
        except (OSError, subprocess.SubprocessError) as e:  # broot missing or stuck: try again on the next pass
            print("broot --send failed:", e, file=sys.stderr)
    return swapped


def save_panes(tabs, panes, side, last):
    """Tell the panes of each tab which broot socket is theirs, so nvim can send its current file to it."""
    if not NVIM_FOLLOW:
        write_if_changed(PANES, "{}")
        return
    sock = {p["tab_id"]: last.get(p["pane_id"], {}).get("sock") or sock_name(p["pane_id"]) for p in side}
    out = {p["pane_id"]: sock[p["tab_id"]] for p in panes if p["tab_id"] in sock and p not in side}
    write_if_changed(PANES, json.dumps(out, sort_keys=True))  # nvim may read it at any moment
    # nvim's selection checks (out/<socket>.sel symlinks) of sidebars that are gone
    keep = {v + ".sel" for v in sock.values()}
    try:
        for name in os.listdir(os.path.join(RUN_DIR, "out")):
            if name not in keep:
                os.unlink(os.path.join(RUN_DIR, "out", name))
    except OSError:
        pass


def tab_nvim(snap):
    """(pane id of an nvim in the focused tab, whether it is the focused pane, the tab's sidebar pane or None). The
    focused pane wins, else the first nvim; None when the tab has no nvim."""
    tid = snap.get("focused_tab_id")
    last = load_last()
    panes = [p for p in snap["panes"] if p["tab_id"] == tid]
    sidebar = next((p["pane_id"] for p in panes if p.get("label") == LABEL or p["pane_id"] in last), None)
    focused = next((l.get("focused_pane_id") for l in snap.get("layouts", []) if l["tab_id"] == tid), None)
    nvims = [p["pane_id"] for p in panes if p["pane_id"] != sidebar and nvim_alive(p["pane_id"])]
    if not nvims:
        return None, False, sidebar
    pane = focused if focused in nvims else nvims[0]
    return pane, pane == focused, sidebar


def neotree(pane, call):
    """Run plugins.herdr.neotree.<call> (a Lua expression such as "toggle()") in the nvim of `pane`, through its socket."""
    nvim = shutil.which("nvim") or "nvim"
    expr = "execute('lua require(\"plugins.herdr.neotree\").%s')" % call
    try:
        subprocess.run([nvim, "--server", nvim_sock(pane), "--remote-expr", expr], capture_output=True, timeout=5)
    except (OSError, subprocess.SubprocessError) as e:
        print("nvim neo-tree call failed:", e, file=sys.stderr)


def focus_pane(pane):
    """Focus a pane by id: the herdr CLI only moves the focus to a neighbour, the socket API has pane.focus."""
    try:
        with socket.socket(socket.AF_UNIX) as s:
            s.settimeout(2)
            s.connect(SOCKET)
            s.sendall((json.dumps({"id": "broot-sidebar", "method": "pane.focus", "params": {"pane_id": pane}}) + "\n").encode())
            recv(s)
    except OSError as e:
        print("pane.focus failed:", e, file=sys.stderr)


def toggle(force=None):
    if force is None and SKIP_NVIM:
        # A tab with an nvim has no sidebar (SKIP_NVIM): the key controls nvim's own neo-tree there instead
        pane = tab_nvim(herdr("api", "snapshot")["snapshot"])[0]
        if pane:
            return neotree(pane, "toggle()")
    on = (not is_on()) if force is None else force
    run_dir()
    if on:
        if os.path.exists(OFF):
            os.remove(OFF)
    else:
        open(OFF, "a").close()
    sync()


def recv(s):
    try:
        return s.recv(65536)
    except OSError:
        return b""


def watch():
    lock = open(os.path.join(run_dir(), "watcher.lock"), "a+")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        return  # already running
    last_run = 0.0
    while True:
        try:
            s = socket.socket(socket.AF_UNIX)
            s.connect(SOCKET)
        except OSError:
            return  # herdr is gone
        req = {"id": "broot-sidebar", "method": "events.subscribe",
               "params": {"subscriptions": [{"type": t} for t in EVENTS]}}
        try:
            s.sendall((json.dumps(req) + "\n").encode())
        except OSError:  # dropped right away: start over (the connect above ends the watcher when herdr is gone)
            s.close()
            time.sleep(0.2)
            continue
        # a first pass right away: herdr has just started (or this watcher has), and nothing may happen for a while
        try:
            if is_on():
                sync()
        except Exception as e:
            print("sync failed:", e, file=sys.stderr)
        while True:
            data = recv(s)
            if not data:
                break
            # A pane that closes may have been the last real one of its tab (the sidebar left alone has to go now) and a
            # new tab wants its sidebar now: no debounce and no pause for these.
            urgent = any(e in data for e in URGENT_EVENTS)
            while not urgent and select.select([s], [], [], 0.4)[0]:  # debounce bursts...
                more = recv(s)
                if not more:
                    break
                urgent = any(e in more for e in URGENT_EVENTS)  # ...unless one of these turns up in the middle of one
            if not urgent:
                time.sleep(max(0.0, last_run + 1.0 - time.monotonic()))
            try:
                if is_on():
                    sync()
            except Exception as e:
                print("sync failed:", e, file=sys.stderr)
            last_run = time.monotonic()
        s.close()
        # The connection ended: herdr stopped, or dropped us for being slow. Look again right away: if herdr is gone
        # the connect at the top of the loop fails and this watcher exits, which hands over to the one the plugin's
        # startup hook starts with the next server (a watcher lingering here would hold the lock and make that one
        # quit, so a restored session would wait for it to wake up). The pause only keeps a flapping socket from spinning.
        time.sleep(0.2)


def focus():
    """Put the focus on this tab's sidebar; from the sidebar itself, back to the pane next to it."""
    snap = herdr("api", "snapshot")["snapshot"]
    tid = snap.get("focused_tab_id")
    last = load_last()
    sidebar = next((p["pane_id"] for p in snap["panes"]
                    if p["tab_id"] == tid and (p.get("label") == LABEL or p["pane_id"] in last)), None)
    if not sidebar:
        # no broot here: in a tab with an nvim the key focuses (or leaves) nvim's neo-tree instead
        pane, is_focused, _ = tab_nvim(snap)
        if pane and is_focused:
            neotree(pane, "focus()")
        elif pane:
            focus_pane(pane)
            neotree(pane, "focus(false)")
        return
    focused = next((l.get("focused_pane_id") for l in snap.get("layouts", []) if l["tab_id"] == tid), None)
    if focused == sidebar:
        herdr("pane", "focus", "--pane", sidebar, "--direction", "right" if LEFT else "left", check=False)
    else:
        herdr("plugin", "pane", "focus", sidebar, check=False)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    {"toggle": toggle, "on": lambda: toggle(True), "off": lambda: toggle(False), "sync": sync, "focus": focus, "watch": watch}.get(
        cmd, lambda: sys.exit(__doc__))()
