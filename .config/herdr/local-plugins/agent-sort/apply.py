"""Install the Agents panel sort view: pane token `kind` ascending, so `job` (slow commands, tagged by
reconcile.py) comes first, then `nvim` (registered by reconcile.py from the nvim terminal title), then panes
without the token (real agents). Remaining ties keep space/tab/pane order."""
import json
import os
import socket

view = {
    "source": "plugin:" + os.environ.get("HERDR_PLUGIN_ID", "agent-sort"),
    "label": "jobs, nvim, agents",
    "sort": [
        {"field": {"token": "kind"}, "order": "asc"},
        {"field": "workspace_order", "order": "asc"},
        {"field": "tab_order", "order": "asc"},
        {"field": "pane_order", "order": "asc"},
    ],
}
s = socket.socket(socket.AF_UNIX)
s.connect(os.environ["HERDR_SOCKET_PATH"])
s.sendall((json.dumps({"id": "agent-sort", "method": "agent.view.set", "params": view}) + "\n").encode())
print(s.recv(4096).decode())
