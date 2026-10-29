# herdr

Config for [herdr](https://herdr.dev). The repo-wide rules are in `AGENTS.md`;
this page covers what is specific to this directory.

## Layout

| Path | What it holds |
| --- | --- |
| `config.toml` | Theme, sidebar rows and key bindings |
| `plugins.list` | The plugins to install, each pinned to a commit |
| `scripts/sync-plugins.sh` | Installs everything in `plugins.list` |
| `local-plugins/` | Plugins of our own, linked into herdr by the sync script |
| `which-key/keys.toml` | The key tree of the which-key plugin |
| `.gitignore` | Runtime state herdr writes next to the config |

## Plugins

- `plugins.list` is the only list of plugins. A `github` line is
  `owner/repo` and a commit, a `local` line is a directory in `local-plugins/`.
- To add or update one, edit its line (a new commit for an update) and run
  `scripts/sync-plugins.sh`. It skips what is installed already. With an ssh
  target (`scripts/sync-plugins.sh <host>`) it does the same on another
  machine.
- The sync script also links `which-key/keys.toml` into the which-key plugin's
  config directory, so edits to the tracked file apply without copying it.
- Each local plugin has a `herdr-plugin.toml`. `herdr-task-runner` has its own
  README, see `local-plugins/herdr-task-runner/README.md`.

## Things to be aware of

- **`~/.config/herdr` holds runtime state** (plugin installs, session
  snapshots, sockets, logs). It is ignored by git, so it can't simply be a link
  to this directory. The sync script links `local-plugins` into it where
  needed.
- **Paths in key bindings are absolute-ish.** A binding runs with whatever
  `PATH` the server started with, so they call
  `$HOME/.config/herdr/local-plugins/herdr-task-runner/bin/herdr-run` by its
  full path. Use `$HOME`, not a real home directory.
- **The server keeps the `PATH` of the shell that started it.** After adding
  `local-plugins/herdr-task-runner/shell.sh` to the shell config for the first
  time, stop the server (`herdr server stop`) so it picks up the new `PATH`.
- **Config changes** to `config.toml` apply after `herdr server reload-config`.
- **The sidebar rows depend on `herdr-task-runner/sidebar.py`.** The workspace
  rows use tokens that script sets (`$app`, `$cmd`, `$branch`, `$uncommitted`,
  `$tabs`) and the agents panel uses the agent names it registers. Renaming a
  token in one place without the other leaves a row empty.
- **A plugin action is bound as `<plugin id>.<action>`**, with
  `type = "plugin_action"`. Popups (`type = "popup"`) can only be opened from a
  native key binding, not from a script.
- **Start commands with `herdr-run`**, not by typing into panes. It decides
  between the focused pane, a new tab and a workspace; see the
  herdr-task-runner README. Television channels use it too.
- **Everything works on one machine.** herdr's socket API only controls its
  own server and can't move this client's view to another machine, so scripts
  such as `herdr-jump-done` only look at the machine they run on.

## Checking a change

- `bash -n` on a script. For `herdr-run`, `--dry-run` shows what it would do
  without touching the live session, so don't open workspaces or tabs to test.
- `herdr plugin list` shows what is installed and linked.
- Key bindings, sidebar rows and the theme can only be seen in a running
  herdr. Say so when a change wasn't tried there.
