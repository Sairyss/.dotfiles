"""Keep the Agents panel and the sidebar rows in step with what runs in the panes.
Usage: sidebar.py reconcile | watch | apply | restart | config

  reconcile  one idempotent pass (see below); also a plugin action
  watch      long-lived: subscribes to pane events and runs reconcile after bursts of them. Started detached by
             the plugin's startup hook, because plugin event hooks can't see pane.updated, which is what a
             changing terminal title emits. One instance only; exits when the herdr socket goes away.
  apply      install the sort view that orders the Agents panel by kind: job, nvim, then untagged agents
  restart    stop the running watcher and start a new one (to pick up a changed script; settings need no restart)
  config     print the effective settings as JSON

reconcile:
- nvim panes (terminal title "<file> (<dir>[ claude:<state>]) - Nvim", see nvim/lua/config/title.lua) are
  registered as agent `nvim` with the pane token kind=nvim. The claude:<idle|working|blocked> part is the
  state of the claude running inside that nvim: it becomes the agent state (the name stays "nvim").
  The registration is released when the title stops looking like nvim (exit, crash, closed window).
- slow-command entries reported by hooks.zsh and herdr-run-hold are tagged kind=job. A job is any reported agent that
  herdr doesn't know as a coding agent and that isn't nvim.
- the [jobs] settings are written to shell.env in the state dir, for hooks.zsh and herdr-run-hold.
- workspace row tokens: title, app, tabs, tasks, cmd, branch, uncommitted.

Settings: config.default.toml in the plugin, overridden by the user's config.toml in the plugin's config dir
(see the top of the default file). Logs go to sidebar.log in the plugin's state dir ($HERDR_TASK_RUNNER_DEBUG=1: verbose).
Needs python 3.11+ and git; talks to herdr through its CLI ($HERDR_BIN_PATH, else PATH) and socket."""
import fcntl
import json
import logging
import logging.handlers
import os
import re
import select
import shlex
import signal
import socket
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from types import SimpleNamespace

try:
    import tomllib
except ImportError:  # python < 3.11
    sys.exit("sidebar.py needs python 3.11+ (tomllib)")

HERDR = os.environ.get("HERDR_BIN_PATH") or "herdr"
XDG_CONFIG = os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")
XDG_STATE = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
ROOT = os.environ.get("HERDR_PLUGIN_ROOT") or os.path.join(XDG_CONFIG, "herdr/local-plugins/herdr-task-runner")
CONFIG_DIR = os.environ.get("HERDR_PLUGIN_CONFIG_DIR") or os.path.join(XDG_CONFIG, "herdr/plugins/config/herdr-task-runner")
STATE_DIR = os.environ.get("HERDR_PLUGIN_STATE_DIR") or os.path.join(XDG_STATE, "herdr/plugins/herdr-task-runner")
# set by herdr for plugin processes; a manual `sidebar.py restart` from a plain shell has no such variable
SOCKET = os.environ.get("HERDR_SOCKET_PATH") or os.path.join(XDG_CONFIG, "herdr/herdr.sock")
DEFAULT_CONFIG = os.path.join(ROOT, "config.default.toml")
USER_CONFIG = os.environ.get("HERDR_TASK_RUNNER_CONFIG") or os.path.join(CONFIG_DIR, "config.toml")
STATE_FILE = os.path.join(STATE_DIR, "nvim-panes.json")

log = logging.getLogger("sidebar")
C = SimpleNamespace()  # the settings of the current pass, filled by load_settings()
warned = set()  # config problems already logged, since the settings are read on every pass
git_deadline = 0.0


# ---- settings ----------------------------------------------------------------------------------------------

def warn_once(msg, *args):
    if (msg, args) not in warned:
        warned.add((msg, args))
        log.warning(msg, *args)


def merge(base, extra, path=""):
    """`extra` over `base`, table by table; lists and values replace. Unknown keys are logged and dropped, so
    a typo in the user's file shows up in the log instead of silently doing nothing."""
    out = dict(base)
    for key, value in extra.items():
        if key not in base:
            warn_once("config: unknown setting %s%s ignored", path, key)
        elif isinstance(base[key], dict) and isinstance(value, dict):
            out[key] = merge(base[key], value, f"{path}{key}.")
        elif isinstance(base[key], dict) or type(value) is not type(base[key]) and not (
                isinstance(base[key], float) and isinstance(value, int)):
            warn_once("config: %s%s has the wrong type, ignored", path, key)
        else:
            out[key] = value
    return out


def build(raw):
    """Settings as attributes, with the regexes compiled and the formats checked, so a bad value fails here
    (and falls back to the defaults) rather than half way through a pass."""
    def ns(d):
        return SimpleNamespace(**{k: ns(v) if isinstance(v, dict) else v for k, v in d.items()})

    s = ns(raw)
    s.raw = raw
    s.nvim.title_re = re.compile(s.nvim.title, re.I)
    s.nvim.claude_re = re.compile(s.nvim.claude_state, re.I)
    s.command.prompt_re = re.compile(s.command.prompt_title)
    s.agents.known_set = set(s.agents.known)
    s.command.skip_set = set(s.command.skip_words)
    s.command.runner_set = set(s.command.runners)
    s.command.shell_set = set(s.command.shells)
    s.jobs.ignore_set = {a.lower() for a in s.jobs.ignore}
    s.jobs.ignore_bare_set = {a.lower() for a in s.jobs.ignore_bare}
    s.tokens.title_format.format(workspace="w", app="a")
    s.tokens.tabs_format.format(n=2)
    s.tokens.uncommitted_format.format(n=2)
    s.tokens.tasks_format.format(n=2)
    if s.jobs.label_style not in ("program", "command"):
        raise ValueError("jobs.label_style must be program or command")
    if not s.jobs.source or s.jobs.source == s.herdr.source:
        # the sidebar's reports use nanosecond seqs, the hooks' microseconds: one source would drown the other
        raise ValueError("jobs.source must be set and differ from herdr.source")
    for k in ("terminal_threshold", "run_threshold"):
        if float(getattr(s.jobs, k)) < 0:
            raise ValueError(f"jobs.{k} must not be negative")
    if not re.fullmatch(r"[0-9]+[smhd]?", str(s.jobs.linger)):
        raise ValueError("jobs.linger must look like 90, 90s, 1m, 1h or 1d")
    return s


def read_toml(path):
    with open(path, "rb") as f:
        return tomllib.load(f)


def load_settings():
    """Read the defaults and the user's file again (cheap) so edits apply without a restart. A broken user
    file is logged and ignored, never fatal: the sidebar keeps working with the defaults."""
    global C
    base = read_toml(DEFAULT_CONFIG)
    try:
        C = build(merge(base, read_toml(USER_CONFIG)))
    except FileNotFoundError:
        C = build(base)
    except Exception as e:  # whatever is wrong with the file (a bad format string raises IndexError, ...)
        if ("bad", str(e)) not in warned:
            warned.add(("bad", str(e)))
            log.error("config: %s unusable (%s), using the defaults", USER_CONFIG, e)
        C = build(base)


def write_shell_env():
    """The [jobs] settings as shell variables, for hooks.zsh and the bash tools, which can't parse TOML.
    Only rewritten when they changed, so shells never see a half-written file."""
    j = C.jobs

    def q(v):
        return "'" + str(v).replace("'", "'\\''") + "'"

    lines = {
        "source": j.source, "terminal_threshold": j.terminal_threshold, "run_threshold": j.run_threshold,
        "report": str(j.report).lower(),
        "label_style": j.label_style, "linger": j.linger, "ignore": " ".join(j.ignore), "ignore_bare": " ".join(j.ignore_bare), "wrappers": " ".join(C.command.skip_words),
    }
    text = "# written by sidebar.py from the settings, don't edit\n" + "".join(f"_tr_{k}={q(v)}\n" for k, v in lines.items())
    path = os.path.join(STATE_DIR, "shell.env")
    try:
        with open(path) as f:
            if f.read() == text:
                return
    except OSError:
        pass
    os.makedirs(STATE_DIR, exist_ok=True)
    tmp = f"{path}.{os.getpid()}"
    with open(tmp, "w") as f:
        f.write(text)
    os.replace(tmp, path)


def setup_logging():
    os.makedirs(STATE_DIR, exist_ok=True)
    handler = logging.handlers.RotatingFileHandler(os.path.join(STATE_DIR, "sidebar.log"), maxBytes=200_000, backupCount=1)
    handler.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
    log.addHandler(handler)
    if sys.stderr.isatty():
        log.addHandler(logging.StreamHandler())
    log.setLevel(logging.DEBUG if os.environ.get("HERDR_TASK_RUNNER_DEBUG") else logging.INFO)


# ---- herdr -------------------------------------------------------------------------------------------------

def run(*args):
    log.debug("herdr %s", " ".join(args))
    return subprocess.run([HERDR, *args], capture_output=True, text=True, timeout=C.herdr.call_timeout).stdout


def seq():
    return str(time.time_ns())  # above any earlier report from any source, whatever clock unit it used


def lock_file(name, block):
    """Take an exclusive lock on STATE_DIR/name for the life of the process; None if `block` is off and taken."""
    os.makedirs(STATE_DIR, exist_ok=True)
    f = open(os.path.join(STATE_DIR, name), "a+")
    try:
        fcntl.flock(f, fcntl.LOCK_EX | (0 if block else fcntl.LOCK_NB))
    except OSError:
        f.close()
        return None
    return f


# ---- command / app detection -------------------------------------------------------------------------------

def cmd_of(p):
    """Command running in a pane without an agent, from the terminal title (zsh's title is the command while
    one runs, and TUIs like yazi set their own, "Yazi: dir"), so it shows before the [jobs] threshold."""
    t = (p.get("terminal_title_stripped") or "").strip()
    if not t or C.command.prompt_re.match(t):
        return ""
    return t.split()[0].rstrip(":").lower()


def detail_of(p):
    """Arguments of the command running in a pane, without the program itself: "npm run test" -> "test",
    "yarn test --watch" -> "test --watch". The full command comes from herdr-run's `cmd` pane token, else from
    the terminal title (the command while one runs). Empty when there are no arguments or it isn't a command."""
    text = (p.get("tokens") or {}).get("cmd") or (p.get("terminal_title_stripped") or "").strip()
    if not text or C.command.prompt_re.match(text):
        return ""
    text = text.split("; rc=$?")[0]  # herdr-run types "<cmd>; rc=$?; herdr-run-hold <label> $rc" around the command
    try:
        words = shlex.split(text)  # unquotes what herdr-run quoted: npm run 'docker:env:reset'
    except ValueError:
        words = text.split()
    while words and (words[0] in C.command.skip_set or "=" in words[0] or words[0].startswith("-")):
        words.pop(0)
    if not words or words[0].endswith(":"):  # a TUI title like "Yazi: dir", not a command line
        return ""
    prog = words.pop(0).rsplit("/", 1)[-1].lower()
    if prog in C.command.runner_set and words[:1] == ["run"]:
        words.pop(0)
    out = " ".join(words)
    limit = C.command.max_length
    return out if len(out) <= limit else out[:limit - 1] + "…"


def job_app(p):
    """The app of a pane with an agent. A job's label can be its whole command (jobs.label_style), so its app
    is the program of the display name, which holds the command."""
    agent = p.get("agent") or ""
    shown = (p.get("display_agent") or "").split()
    if agent in C.agents.known_set or not shown:
        return agent
    return shown[0].rsplit("/", 1)[-1].lower()


def is_task(p):
    """A pane that runs a task: a job that is working or a command, not a shell prompt, a coding agent, a
    finished job still marked, or an interactive app from [jobs] ignore."""
    agent = (p.get("agent") or "").lower()
    if agent and p.get("agent_status") not in ("working", "unknown", None):
        return False  # done/failed marks stay in the sidebar after the command has ended
    name = agent or cmd_of(p)
    return bool(name) and name not in C.jobs.ignore_set and name not in C.jobs.ignore_bare_set \
        and name not in C.agents.known_set and name not in C.command.shell_set


def fg_cmd(p):
    """Foreground program of a pane, for apps that set no terminal title and run without a shell around
    them (herdr-run's fast path, e.g. lazygit). Empty when the pane's shell is in front."""
    try:
        info = json.loads(run("pane", "process-info", "--pane", p["pane_id"]))["result"]["process_info"]
    except (ValueError, KeyError):
        return ""
    for proc in info.get("foreground_processes") or []:
        name = (proc.get("name") or "").lstrip("-").lower()
        if name and name not in C.command.shell_set:
            return name
    return ""


# ---- git ---------------------------------------------------------------------------------------------------

def git(cwd, *args):
    """stdout of `git -C cwd ...`: "" outside a repo, None when git was too slow, failed to start or the
    run's time budget is used up (callers keep the token they have then instead of clearing it)."""
    if not cwd or time.monotonic() >= git_deadline:
        return None
    try:
        return subprocess.run(["git", "-C", cwd, "--no-optional-locks", *args],
                              capture_output=True, text=True, timeout=C.git.timeout).stdout
    except (OSError, subprocess.SubprocessError):
        log.debug("git %s in %s: too slow or failed", args[0], cwd)
        return None


def uncommitted_files(cwd):
    """Number of changed or untracked files in the git repo containing cwd; 0 outside a repo, None if unknown."""
    out = git(cwd, "status", "--porcelain")
    return None if out is None else len(out.splitlines())


def git_branch(cwd):
    """Current branch (short hash when detached) of the git repo containing cwd; "" outside a repo, None if unknown."""
    for args in (["branch", "--show-current"], ["rev-parse", "--short", "HEAD"]):
        out = git(cwd, *args)
        if out is None or out.strip():
            return None if out is None else out.strip()
    return ""


# ---- reconcile ---------------------------------------------------------------------------------------------

def sync_panes(panes):
    """nvim registration and job tags, per pane."""
    try:
        with open(STATE_FILE) as f:
            known = json.load(f)  # pane_id -> [state, display] last reported for nvim panes
    except (OSError, ValueError):
        known = {}

    src, kind, nvim = C.herdr.source, C.kinds.token, C.nvim.name
    live = set()
    for p in panes:
        pid = p["pane_id"]
        agent = p.get("agent")
        tokens = p.get("tokens") or {}
        title = p.get("terminal_title") or ""
        live.add(pid)

        legacy = any(title == t or title.startswith(t + " ") for t in C.nvim.legacy_titles)
        if C.nvim.enabled and (C.nvim.title_re.search(title) or legacy):
            m = C.nvim.claude_re.search(title)
            want = [m.group(1) if m else "idle", ""]
            status = {"done": "idle"}.get(p.get("agent_status"), p.get("agent_status"))
            if agent == nvim and status == want[0] and known.get(pid) == want and tokens.get(kind) == C.kinds.nvim:
                continue
            run("pane", "report-agent", pid, "--source", src, "--agent", nvim, "--state", want[0], "--seq", seq())
            meta = ["pane", "report-metadata", pid, "--source", src, "--agent", nvim, "--token", f"{kind}={C.kinds.nvim}"]
            meta += ["--display-agent", want[1]] if want[1] else ["--clear-display-agent"]
            run(*meta)
            known[pid] = want
            continue

        if pid in known:  # was nvim, isn't anymore
            run("pane", "release-agent", pid, "--source", src, "--agent", nvim, "--seq", seq())
            run("pane", "report-metadata", pid, "--source", src, "--clear-display-agent", "--clear-token", kind)
            del known[pid]
            continue

        is_job = bool(agent) and agent not in C.agents.known_set
        if is_job and tokens.get(kind) != C.kinds.job:
            run("pane", "report-metadata", pid, "--source", src, "--token", f"{kind}={C.kinds.job}")
        elif not is_job and tokens.get(kind) == C.kinds.job:
            run("pane", "report-metadata", pid, "--source", src, "--clear-token", kind)

    for pid in set(known) - live:  # pane closed
        del known[pid]
    with open(STATE_FILE, "w") as f:
        json.dump(known, f)


def sync_workspaces(panes):
    """Workspace row tokens. The row title is "<workspace>·<app>" (token $title, see [ui.sidebar.spaces] rows):
    app is the agent of the focused pane in the active tab, else of any pane in it."""
    global git_deadline
    git_deadline = time.monotonic() + C.git.budget
    wss = json.loads(run("workspace", "list"))["result"]["workspaces"]
    names = C.tokens

    def tab_of(ws):
        tab = [p for p in panes if p["tab_id"] == ws.get("active_tab_id")]
        tab.sort(key=lambda p: not p.get("focused"))
        return tab

    def cwd_of(tab):
        return (tab[0].get("foreground_cwd") or tab[0].get("cwd")) if tab else None

    def report(ws, which, value):
        """Set the workspace token `which` (a key of [tokens]) to value, or clear it when value is empty; only
        calls herdr on a change. None means unknown (git too slow): keep what is shown. A token whose name is
        empty is off."""
        token = getattr(names, which)
        if not token:
            return
        have = (ws.get("tokens") or {}).get(token) or ""
        if value is None or value == have:
            return
        flag = ["--token", f"{token}={value}"] if value else ["--clear-token", token]
        run("workspace", "report-metadata", ws["workspace_id"], "--source", C.herdr.source, *flag)

    # git is the slow part: start it for every workspace at once, the loop below only collects the results
    with ThreadPoolExecutor(max_workers=C.git.workers) as pool:
        git_jobs = {}
        for ws in wss:
            c = cwd_of(tab_of(ws))
            if C.git.enabled and c and c not in git_jobs:  # workspaces sharing a directory share the answer
                git_jobs[c] = (pool.submit(git_branch, c), pool.submit(uncommitted_files, c))

        for ws in wss:
            tab = tab_of(ws)
            app = next((job_app(p) for p in tab if p.get("agent")), "") or next((cmd_of(p) for p in tab if cmd_of(p)), "")
            if not app and tab:  # only the focused pane: one extra call, and only when nothing else names the app
                app = fg_cmd(tab[0])
            report(ws, "title", names.title_format.format(workspace=ws["label"], app=app) if app else ws["label"])
            # $app: just the app, for a layout that styles it apart from the workspace name
            report(ws, "app", app)
            # $tabs: only when the workspace has several tabs
            n = ws.get("tab_count") or 1
            report(ws, "tabs", names.tabs_format.format(n=n) if n > 1 else "")
            # $tasks: how many tasks run in all tabs of the workspace, shown from [tasks] min_count on
            running = sum(1 for p in panes if p["workspace_id"] == ws["workspace_id"] and is_task(p))
            report(ws, "tasks", names.tasks_format.format(n=running) if running >= C.tasks.min_count else "")
            # $cmd: the arguments of the command that gave the app (see detail_of); none for agents and nvim
            # (a job registered by hooks.zsh/herdr-run counts as a command: its agent name is just the program)
            src = next((p for p in tab if p.get("agent")), None) or next((p for p in tab if cmd_of(p)), None)
            detail = detail_of(src) if src and (src.get("agent") or "") not in C.agents.known_set else ""
            report(ws, "cmd", detail)
            # $branch goes away while a command runs: the command's arguments (row 2, $cmd) need the room more
            branch_job, uncommitted_job = git_jobs.get(cwd_of(tab), (None, None))
            branch = "" if detail else (branch_job.result() if branch_job else None)
            report(ws, "branch", branch)
            # $uncommitted: n uncommitted files (changed or untracked) in the focused pane's repo. herdr's git_status
            # only counts ahead/behind. Refreshed on pane events, so an edit shows up with the next one.
            n_uncommitted = uncommitted_job.result() if uncommitted_job else None
            report(ws, "uncommitted", None if n_uncommitted is None else names.uncommitted_format.format(n=n_uncommitted) if n_uncommitted else "")


def reconcile():
    lock = lock_file("reconcile.lock", block=True)  # a manual action and the watcher can overlap
    try:
        load_settings()
        write_shell_env()
        started = time.monotonic()
        panes = json.loads(run("pane", "list"))["result"]["panes"]
        sync_panes(panes)
        sync_workspaces(panes)
        log.debug("reconciled %d panes in %.2fs", len(panes), time.monotonic() - started)
    finally:
        if lock:
            lock.close()


# ---- watch -------------------------------------------------------------------------------------------------

def recv(s):
    """Read from the herdr socket; a connection reset counts as the server being gone (b"")."""
    try:
        return s.recv(65536)
    except OSError:
        return b""


def watch():
    lock = lock_file("watcher.lock", block=False)
    if lock is None:
        return  # already running
    lock.seek(0)
    lock.truncate()
    lock.write(str(os.getpid()))  # for `restart`
    lock.flush()
    last_run = 0.0

    def reconcile_throttled():
        nonlocal last_run
        time.sleep(max(0.0, last_run + C.watch.min_gap - time.monotonic()))  # events queue up in the socket meanwhile
        last_run = time.monotonic()
        try:
            reconcile()
        except Exception:  # a daemon must outlive one bad pass (herdr busy or restarting): the next burst retries
            log.exception("reconcile failed")

    while True:
        try:
            s = socket.socket(socket.AF_UNIX)
            s.connect(SOCKET)
        except (OSError, KeyError):
            log.info("herdr socket gone, exiting")
            return
        req = {"id": "sidebar-watch", "method": "events.subscribe",
               "params": {"subscriptions": [{"type": t} for t in C.watch.events]}}
        s.sendall((json.dumps(req) + "\n").encode())
        buf = recv(s)
        if b'"error"' in buf.split(b"\n", 1)[0]:
            log.error("subscription refused: %s", buf.decode(errors="replace").strip())
            s.close()
            time.sleep(C.watch.retry_delay)  # not a retry loop: that would be polling by accident
            load_settings()
            continue
        log.info("watching (pid %d)", os.getpid())
        reconcile_throttled()
        buf = b""
        while True:
            chunk = recv(s)
            if not chunk:
                break  # server gone, or events_lost closed us: resubscribe
            buf += chunk
            deadline = time.monotonic() + C.watch.max_wait
            while time.monotonic() < deadline and select.select([s], [], [], C.watch.quiet)[0]:  # debounce bursts
                more = recv(s)
                if not more:
                    break
                buf += more
            if b"events_lost" in buf:
                break
            buf = b""
            reconcile_throttled()
        s.close()


def restart():
    """Stop the running watcher (its pid is in the lock file) and start a new one."""
    free = lock_file("watcher.lock", block=False)
    if free:  # nobody holds the lock: the pid in the file is stale and may belong to another process now
        free.close()
    else:
        try:
            with open(os.path.join(STATE_DIR, "watcher.lock")) as f:
                os.kill(int(f.read().strip()), signal.SIGTERM)
        except (OSError, ValueError):
            pass
    for _ in range(30):  # until the old one has let go of the lock
        lock = lock_file("watcher.lock", block=False)
        if lock:
            lock.close()
            break
        time.sleep(0.1)
    subprocess.Popen([sys.executable, "-I", os.path.abspath(__file__), "watch"], start_new_session=True,
                     stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    log.info("watcher restarted")


# ---- apply -------------------------------------------------------------------------------------------------

def apply():
    """Sort by pane token `kinds.token` ascending, so jobs come first, then nvim, then panes without the token
    (real agents). Remaining ties keep the order of [view].then_by. Agent views are transient (lost when the
    server exits), so this runs on startup."""
    view = {
        "source": "plugin:" + os.environ.get("HERDR_PLUGIN_ID", "herdr-task-runner"),
        "label": C.view.label,
        "sort": [{"field": {"token": C.kinds.token}, "order": "asc"}]
                + [{"field": f, "order": "asc"} for f in C.view.then_by],
    }
    s = socket.socket(socket.AF_UNIX)
    s.connect(SOCKET)
    s.sendall((json.dumps({"id": "sidebar-apply", "method": "agent.view.set", "params": view}) + "\n").encode())
    print(s.recv(4096).decode())


def show_config():
    print(json.dumps(C.raw, indent=2, ensure_ascii=False))


COMMANDS = {"reconcile": reconcile, "watch": watch, "apply": apply, "restart": restart, "config": show_config}

if __name__ == "__main__":
    if len(sys.argv) != 2 or sys.argv[1] not in COMMANDS:
        sys.exit("usage: sidebar.py reconcile | watch | apply | restart | config")
    setup_logging()
    load_settings()
    COMMANDS[sys.argv[1]]()
