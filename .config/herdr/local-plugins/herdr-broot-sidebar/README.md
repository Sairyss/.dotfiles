# herdr-broot-sidebar

A global [broot](https://dystroy.org/broot/) sidebar for herdr: one pane on the
right of every workspace's active tab (or the left), about 20% wide, showing
the directory of the pane you are working in.

- **Toggle** (`toggle` action) switches it on or off for all workspaces at
  once. Off closes every sidebar pane.
- **Focus** (`focus` action) puts the focus on the sidebar of the current tab;
  from the sidebar it goes back to the pane next to it. Bind it to a key that
  is not the one you move between panes with. When you come back to a tab you
  left with the sidebar focused, the focus goes to the pane next to it.
- **Started directly**: the sidebar is a declarative plugin pane (`[[panes]]`
  in the manifest, opened with `herdr plugin pane open`), so herdr runs broot
  itself. There is no shell around it: nothing is typed into a pane, the
  terminal title stays broot's own, and no shell hook (such as the
  task-runner's) ever sees it. It opens at half the split and is resized to its
  width right away. Its `--listen` name is chosen beforehand and kept in a
  registry; `panes.json` tells nvim which one belongs to which tab.
- **One per tab**: herdr panes belong to a tab, so every tab of every workspace
  gets its own sidebar pane, created ahead of time. Switching tabs or
  workspaces then does no work, so it is instant. New tabs and workspaces get
  theirs at once: creation events, like closes, skip the debounce.
- **Follows the directory**: when the focused pane's directory changes, broot
  is told `:focus <dir>` through its `--listen`/`--send` socket.
- **Follows neovim**: in a tab that has an nvim (with
  `HERDR_BROOT_SIDEBAR_NVIM_FOLLOW=1` and `HERDR_BROOT_SIDEBAR_SKIP_NVIM=0`,
  see below) the sidebar shows the tree of
  nvim's directory with the open file selected, like the file tree of an
  editor. broot cannot expand a directory in place, so for a file deep in a big
  tree the root moves down towards it one directory at a time, only as far as
  needed. nvim does this itself (`nvim/lua/plugins/herdr/broot.lua`); the plugin
  only writes `panes.json` (pane id to the broot socket of its tab) and stops
  following the focused pane's directory in such tabs. Without a sidebar in the
  tab there is no entry for the pane and nvim does nothing.
- **Keeps nvim's own file tree** (on by default; `0`, `false`, `no` or `off` in
  `HERDR_BROOT_SIDEBAR_SKIP_NVIM` turns it off): tabs that run nvim get no
  sidebar. It goes away when nvim starts in a tab that has one and comes back
  when nvim exits. broot in the other tabs still opens files in the nvim of the
  workspace and jumps to it. An nvim is found by its socket, which the nvim
  config of this repo (`nvim/lua/plugins/herdr/server.lua`, which defines the
  naming) opens from the first moment of startup. Without that config the
  sidebar stays in such tabs.
- **Falls back to nvim's neo-tree**: in a tab without a sidebar because it runs
  nvim (`SKIP_NVIM`), the `toggle` action toggles nvim's neo-tree and `focus`
  focuses it, or from it goes back to the previous window (from another pane
  it focuses the nvim pane first). It talks to nvim through its socket and
  `nvim/lua/plugins/herdr/neotree.lua`, which nvim's `<leader>e` and
  `<leader>B` use too. Tabs without nvim and sidebar do nothing, as before.
- **Steps aside for full-screen programs**: a tab where a file manager
  (`yazi`, `ranger`, `nnn`, `lf`, `mc`, `vifm`, `xplr`, `ncdu`, and broot
  itself), a monitor (`btop`, `htop` ...) or a git UI (`lazygit`, `tig` ...)
  runs has no sidebar while it does, and gets it back when it exits (about a
  second each way). The list is `DEFAULT_HIDE` in `sidebar.py`;
  `HERDR_BROOT_SIDEBAR_HIDE_FOR` (space or comma separated names, empty means
  never) replaces it. Short-lived pagers and pickers (`less`, `man`, `fzf`) are
  left out, as they would make the sidebar blink with every `git log`. The
  check asks herdr for the foreground processes of each pane.
- **Transparent**: the sidebar never keeps a tab alive. When the last real pane
  of a tab closes (claude exited, you closed the shell), the sidebar goes too
  and the tab closes within about 0.1 s: a close skips the usual debounce.
- **Transparent to other plugins**: each sidebar pane carries the pane token
  `transparent=1`. The convention is generic, nothing here names another
  plugin: whoever reads the token treats the pane as not being where you work.
  `herdr-run` (task-runner) types commands into the idle shell next to it, the
  task-runner leaves it out of the app, command and task number, and
  `navigate.sh` (vim-herdr-navigation) steps over it, so alt+h/l move past it
  and you reach it with the `focus` action only.
- **Survives a herdr restart**: session restore brings the panes back with
  their layout, directory and label, but as plain shells without what ran in
  them and without their tokens, and it emits no events. The watcher therefore
  checks on start and on every tab, workspace and pane event. Pane ids are not
  stable across restarts, so the registry is tied to the herdr server that
  wrote it (the identity of its socket) and is ignored for another one. A pane
  labelled `broot-sidebar` without the token is a dead leftover: it is closed
  and a fresh sidebar starts in its place (one that still runs broot only gets
  marked). The label is put back if another plugin renames the pane. If the
  on/off switch was lost (a reboot clears the runtime dir) but such panes
  exist, the sidebar is switched on again; after an explicit `off` it stays
  off.
- **Nothing is written to disk**: the switch, locks, `panes.json` and the last
  directories live in `$XDG_RUNTIME_DIR/herdr-broot-sidebar` (memory; without
  it `$TMPDIR` or `/tmp` with a per-user directory), and files are only
  rewritten when their content changes. After a reboot the sidebar is off until
  you toggle it. A sync takes about 50 ms and runs at most once a second; a
  pane title change also triggers one.
- A sidebar you exit by hand comes back on the next event; use the toggle.
- One failing step (a tab, a `--send` to broot) is logged and skipped; the
  other tabs and the saved state are still updated.

## Settings

Environment variables, set where the herdr server sees them (your shell
profile, then restart the server):

| Variable | Meaning |
| --- | --- |
| `HERDR_BROOT_SIDEBAR_RATIO` | width as a share of the tab, default `0.20` |
| `HERDR_BROOT_SIDEBAR_SIDE` | `right` (default) or `left` |
| `HERDR_BROOT_SIDEBAR_SKIP_NVIM` | `1` (default) or `0`, see above |
| `HERDR_BROOT_SIDEBAR_NVIM_FOLLOW` | `0` (default) or `1`, see below |
| `HERDR_BROOT_SIDEBAR_HIDE_FOR` | programs that hide the sidebar |
| `HERDR_BROOT_SIDEBAR_CMD` | the broot executable, no arguments |
| `BROOT_BIN` | used when the command is not set, then `PATH` |

"Follows neovim" is off by default (`HERDR_BROOT_SIDEBAR_NVIM_FOLLOW=1` turns
it on): nvim does not drive the sidebar, `panes.json` stays empty, nothing
probes for nvim sockets (unless `SKIP_NVIM` needs them) and the sidebar
follows the focused pane's directory in every tab. Opening files from broot in
nvim is not affected. nvim reads the variable too, so set it where both see
it.

Needs python 3.11+, broot and herdr. Put broot's own options in its config
(`~/.config/broot/conf.hjson`); a command with arguments is not supported.

## Install and bind

Add `local herdr-broot-sidebar` to `~/.config/herdr/plugins.list`, run
`~/.config/herdr/scripts/sync-plugins.sh`, then bind the actions in
`~/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "prefix+b"
type = "plugin_action"
command = "herdr-broot-sidebar.toggle"
description = "broot sidebar"

[[keys.command]]
key = "prefix+u"
type = "plugin_action"
command = "herdr-broot-sidebar.focus"
description = "focus broot sidebar"
```

## broot config

The sidebar works with a plain broot. Two verbs in
`~/.config/broot/verbs.hjson` make it nicer (this repo tracks them in
`.config/broot`):

- `hbs_report`, used by nvim to find out whether `:select` worked (broot cannot
  say what it selected otherwise). Without it only the project root's tree is
  tried:

  ```hjson
  {
      invocation: "hbs_report {out}"
      external: "ln -sfn {file} {out}"
      leave_broot: false
      switch_terminal: false
  }
  ```

- `edit` (key `enter`): runs `herdr-run --edit {file} --line {line}`, which
  opens the file in the nvim of the workspace, else in a new tab. `herdr-run`
  must be on `PATH` (the task-runner's `shell.sh` adds it, and the herdr server
  inherits that from the shell it was started in); broot treats `{...}` in a
  command as its own placeholders, so there is no room for a fallback path.

`switch_terminal: false` on these verbs keeps broot from leaving its screen.
The git status colours (`git_status_*`) are set in the skin file the config
imports.
