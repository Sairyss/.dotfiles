"""Long-lived event watcher, started detached by the plugin's startup hook (plugin event hooks can't see
pane.updated, which is what a changing terminal title emits). Runs reconcile.py after bursts of pane events:
it waits for QUIET seconds without events, but at most MAX_WAIT so a pane that changes its title nonstop can't
postpone it forever, and runs at most once per MIN_GAP. One instance only; exits when the herdr socket goes away."""
import fcntl
import json
import os
import select
import socket
import subprocess
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
STATE_DIR = os.environ.get("HERDR_PLUGIN_STATE_DIR") or "/tmp"
os.makedirs(STATE_DIR, exist_ok=True)
lock = open(os.path.join(STATE_DIR, "watcher.lock"), "w")
try:
    fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
except OSError:
    sys.exit(0)  # already running

EVENTS = ["pane.created", "pane.updated", "pane.exited", "pane.closed", "pane.agent_detected", "pane.agent_status_changed"]


QUIET = 0.5
MAX_WAIT = 2.0
MIN_GAP = 2.0
last_run = 0.0


def reconcile():
    global last_run
    time.sleep(max(0.0, last_run + MIN_GAP - time.monotonic()))  # events queue up in the socket meanwhile
    last_run = time.monotonic()
    try:
        subprocess.run([sys.executable, "-I", os.path.join(HERE, "reconcile.py")], capture_output=True, timeout=20)
    except subprocess.SubprocessError:
        pass  # a slow run (big repo, busy machine) must not kill the watcher; the next burst of events retries


while True:
    try:
        s = socket.socket(socket.AF_UNIX)
        s.connect(os.environ["HERDR_SOCKET_PATH"])
    except OSError:
        sys.exit(0)
    req = {"id": "agent-sort-watch", "method": "events.subscribe",
           "params": {"subscriptions": [{"type": t} for t in EVENTS]}}
    s.sendall((json.dumps(req) + "\n").encode())
    reconcile()
    buf = b""
    while True:
        chunk = s.recv(65536)
        if not chunk:
            break  # server gone, or events_lost closed us: resubscribe
        buf += chunk
        deadline = time.monotonic() + MAX_WAIT
        while time.monotonic() < deadline and select.select([s], [], [], QUIET)[0]:  # debounce bursts
            more = s.recv(65536)
            if not more:
                break
            buf += more
        if b"events_lost" in buf:
            break
        buf = b""
        reconcile()
    s.close()
