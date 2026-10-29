"""Keep the Agents panel in step with what runs in the panes. Runs from event hooks; idempotent.

- nvim panes (terminal title "<file> (<dir>[ claude:<state>]) - Nvim", see nvim/lua/config/title.lua) are
  registered as agent `nvim` with the pane token kind=nvim. The claude:<idle|working|blocked> part is the
  state of the claude running inside that nvim: it becomes the agent state (the name stays "nvim").
  The registration is released when the title stops looking like nvim (exit, crash, closed window).
- slow-command entries reported by herdr-ohmyzsh are tagged kind=job. A job is any reported agent that
  herdr doesn't know as a coding agent and that isn't nvim.

apply.py installs the sort view that orders by kind: job, nvim, then untagged agents."""
import fcntl
import json
import os
import re
import shlex
import subprocess
import time

HERDR = os.environ.get("HERDR_BIN_PATH") or "herdr"
SOURCE = "agent-sort"
STATE_DIR = os.environ.get("HERDR_PLUGIN_STATE_DIR") or "/tmp"
STATE_FILE = os.path.join(STATE_DIR, "nvim-panes.json")

# coding agents herdr tracks itself (and herdr-ohmyzsh's ignore list); everything else is a job
AGENTS = {
    "pi", "omp", "claude", "claude-code", "codex", "copilot", "devin", "droid", "kimi", "opencode", "kilo",
    "hermes", "qodercli", "qwen", "cursor", "mastracode", "antigravity-cli", "grok", "letta", "gemini",
    "agy", "cline", "kiro", "amp", "maki", "nvim",
}
NVIM = re.compile(r" - Nvim$", re.I)
CLAUDE = re.compile(r" claude:(idle|working|blocked)\) - Nvim$", re.I)


def run(*args):
    return subprocess.run([HERDR, *args], capture_output=True, text=True, timeout=5).stdout


def seq():
    return str(time.time_ns())  # above any earlier report from any source, whatever clock unit it used


os.makedirs(STATE_DIR, exist_ok=True)
lock = open(os.path.join(STATE_DIR, "reconcile.lock"), "w")
fcntl.flock(lock, fcntl.LOCK_EX)  # event hooks can overlap

try:
    known = json.load(open(STATE_FILE))  # pane_id -> [state, display] last reported for nvim panes
except (OSError, ValueError):
    known = {}

panes = json.loads(run("pane", "list"))["result"]["panes"]
live = set()
for p in panes:
    pid = p["pane_id"]
    agent = p.get("agent")
    tokens = p.get("tokens") or {}
    title = p.get("terminal_title") or ""
    live.add(pid)

    if NVIM.search(title) or title.startswith("nvim ") or title == "nvim":  # the latter: older nvim config
        m = CLAUDE.search(title)
        want = [m.group(1) if m else "idle", ""]
        status = {"done": "idle"}.get(p.get("agent_status"), p.get("agent_status"))
        if agent == "nvim" and status == want[0] and known.get(pid) == want and tokens.get("kind") == "nvim":
            continue
        run("pane", "report-agent", pid, "--source", SOURCE, "--agent", "nvim", "--state", want[0], "--seq", seq())
        meta = ["pane", "report-metadata", pid, "--source", SOURCE, "--agent", "nvim", "--token", "kind=nvim"]
        meta += ["--display-agent", want[1]] if want[1] else ["--clear-display-agent"]
        run(*meta)
        known[pid] = want
        continue

    if pid in known:  # was nvim, isn't anymore
        run("pane", "release-agent", pid, "--source", SOURCE, "--agent", "nvim", "--seq", seq())
        run("pane", "report-metadata", pid, "--source", SOURCE, "--clear-display-agent", "--clear-token", "kind")
        del known[pid]
        continue

    is_job = bool(agent) and agent not in AGENTS
    if is_job and tokens.get("kind") != "job":
        run("pane", "report-metadata", pid, "--source", SOURCE, "--token", "kind=job")
    elif not is_job and tokens.get("kind") == "job":
        run("pane", "report-metadata", pid, "--source", SOURCE, "--clear-token", "kind")

for pid in set(known) - live:  # pane closed
    del known[pid]
json.dump(known, open(STATE_FILE, "w"))

SHELL_TITLE = re.compile(r"^[^\s@]+@[^\s:]+:")  # the prompt title "user@host:dir"


def cmd_of(p):
    """Command running in a pane without an agent, from the terminal title (zsh's title is the command while
    one runs, and TUIs like yazi set their own, "Yazi: dir"), so it shows before herdr-ohmyzsh's delay."""
    t = (p.get("terminal_title_stripped") or "").strip()
    if not t or SHELL_TITLE.match(t):
        return ""
    return t.split()[0].rstrip(":").lower()


SKIP_WORDS = {"sudo", "doas", "command", "builtin", "exec", "nohup", "time", "nice", "env", "caffeinate"}
RUNNERS = {"npm", "pnpm", "yarn", "bun"}  # `<runner> run <script>`: "run" says nothing, show the script


def detail_of(p):
    """Arguments of the command running in a pane, without the program itself: "npm run test" -> "test",
    "yarn test --watch" -> "test --watch". The full command comes from herdr-run's `cmd` pane token, else from
    the terminal title (the command while one runs). Empty when there are no arguments or it isn't a command."""
    text = (p.get("tokens") or {}).get("cmd") or (p.get("terminal_title_stripped") or "").strip()
    if not text or SHELL_TITLE.match(text):
        return ""
    text = text.split("; rc=$?")[0]  # herdr-run types "<cmd>; rc=$?; herdr-run-hold <label> $rc" around the command
    try:
        words = shlex.split(text)  # unquotes what herdr-run quoted: npm run 'docker:env:reset'
    except ValueError:
        words = text.split()
    while words and (words[0] in SKIP_WORDS or "=" in words[0] or words[0].startswith("-")):
        words.pop(0)
    if not words or words[0].endswith(":"):  # a TUI title like "Yazi: dir", not a command line
        return ""
    prog = words.pop(0).rsplit("/", 1)[-1].lower()
    if prog in RUNNERS and words[:1] == ["run"]:
        words.pop(0)
    out = " ".join(words)
    return out if len(out) <= 40 else out[:39] + "…"


SHELLS = {"bash", "zsh", "sh", "dash", "fish", "ksh", "nu", "elvish", "xonsh", "tcsh", "csh"}


def fg_cmd(p):
    """Foreground program of a pane, for apps that set no terminal title and run without a shell around
    them (herdr-run's fast path, e.g. lazygit). Empty when the pane's shell is in front."""
    try:
        info = json.loads(run("pane", "process-info", "--pane", p["pane_id"]))["result"]["process_info"]
    except (ValueError, KeyError):
        return ""
    for proc in info.get("foreground_processes") or []:
        name = (proc.get("name") or "").lstrip("-").lower()
        if name and name not in SHELLS:
            return name
    return ""


def dirty_files(cwd):
    """Number of changed or untracked files in the git repo containing cwd; 0 outside a repo or on error."""
    if not cwd:
        return 0
    try:
        out = subprocess.run(["git", "-C", cwd, "--no-optional-locks", "status", "--porcelain"],
                             capture_output=True, text=True, timeout=3).stdout
    except (OSError, subprocess.SubprocessError):
        return 0
    return len(out.splitlines())


def git_branch(cwd):
    """Current branch (short hash when detached) of the git repo containing cwd; empty outside a repo."""
    if not cwd:
        return ""
    for args in (["branch", "--show-current"], ["rev-parse", "--short", "HEAD"]):
        try:
            out = subprocess.run(["git", "-C", cwd, "--no-optional-locks", *args],
                                 capture_output=True, text=True, timeout=3).stdout.strip()
        except (OSError, subprocess.SubprocessError):
            return ""
        if out:
            return out
    return ""


# workspace row title "<workspace>·<app>" (token $title, see [ui.sidebar.spaces] rows): app is the agent
# of the focused pane in the active tab, else of any pane in it
wss = json.loads(run("workspace", "list"))["result"]["workspaces"]
for ws in wss:
    tab = [p for p in panes if p["tab_id"] == ws.get("active_tab_id")]
    tab.sort(key=lambda p: not p.get("focused"))
    app = next((p["agent"] for p in tab if p.get("agent")), "") or next((cmd_of(p) for p in tab if cmd_of(p)), "")
    if not app and tab:  # only the focused pane: one extra call, and only when nothing else names the app
        app = fg_cmd(tab[0])
    want = f"{ws['label']}·{app}" if app else ws["label"]
    if (ws.get("tokens") or {}).get("title") != want:
        run("workspace", "report-metadata", ws["workspace_id"], "--source", SOURCE, "--token", f"title={want}")
    # token $app: just the app, for a layout that styles it apart from the workspace name
    have = (ws.get("tokens") or {}).get("app")
    if app and have != app:
        run("workspace", "report-metadata", ws["workspace_id"], "--source", SOURCE, "--token", f"app={app}")
    elif not app and have:
        run("workspace", "report-metadata", ws["workspace_id"], "--source", SOURCE, "--clear-token", "app")
    # token $tabs: "⧉ <n>" when the workspace has several tabs, none for a single one
    n = ws.get("tab_count") or 1
    have = (ws.get("tokens") or {}).get("tabs")
    if n > 1 and have != f"⧉ {n}":
        run("workspace", "report-metadata", ws["workspace_id"], "--source", SOURCE, "--token", f"tabs=⧉ {n}")
    elif n <= 1 and have:
        run("workspace", "report-metadata", ws["workspace_id"], "--source", SOURCE, "--clear-token", "tabs")
    # token $cmd: the arguments of the command that gave the app (see detail_of); none for agents and nvim
    # (a job registered by herdr-run/herdr-ohmyzsh counts as a command: its agent name is just the program)
    src = next((p for p in tab if p.get("agent")), None) or next((p for p in tab if cmd_of(p)), None)
    detail = detail_of(src) if src and (src.get("agent") or "") not in AGENTS else ""
    have = (ws.get("tokens") or {}).get("cmd")
    if detail and have != detail:
        run("workspace", "report-metadata", ws["workspace_id"], "--source", SOURCE, "--token", f"cmd={detail}")
    elif not detail and have:
        run("workspace", "report-metadata", ws["workspace_id"], "--source", SOURCE, "--clear-token", "cmd")
    # token $branch: herdr's own `branch` token can't be hidden, so this one stands in for it and goes away while
    # a command runs: the command's arguments (row 2, $cmd) need the room more
    cwd = (tab[0].get("foreground_cwd") or tab[0].get("cwd")) if tab else None
    branch = "" if detail else git_branch(cwd)
    have = (ws.get("tokens") or {}).get("branch")
    if branch and have != branch:
        run("workspace", "report-metadata", ws["workspace_id"], "--source", SOURCE, "--token", f"branch={branch}")
    elif not branch and have:
        run("workspace", "report-metadata", ws["workspace_id"], "--source", SOURCE, "--clear-token", "branch")
    # token $dirty: "✚ <n>" for n uncommitted files (changed or untracked) in the focused pane's repo. herdr's
    # git_status only counts ahead/behind. Refreshed on pane events, so an edit shows up with the next one.
    want = dirty_files(cwd)
    have = (ws.get("tokens") or {}).get("dirty")
    if want and have != f"✚ {want}":
        run("workspace", "report-metadata", ws["workspace_id"], "--source", SOURCE, "--token", f"dirty=✚ {want}")
    elif not want and have:
        run("workspace", "report-metadata", ws["workspace_id"], "--source", SOURCE, "--clear-token", "dirty")
