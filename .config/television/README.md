# television

Config for [television](https://github.com/alexpasmantier/television) (`tv`).
The repo-wide rules are in `AGENTS.md`; this page covers what is specific to
this directory.

## Layout

| Path | What it holds |
| --- | --- |
| `config.toml` | Global settings: theme, keybindings, UI |
| `themes/` | Our own themes (`theme` in `config.toml` picks one) |
| `cable/` | Default channels, downloaded by `tv update-channels` |
| `cable/custom/` | Our own channels |
| `scripts/` | One script per feature, named after the channel that uses it |
| `scripts/lib/` | Sourceable libraries (functions only) |

`tv` reads `cable/` recursively, so `cable/custom/` needs no configuration.
When two channels have the same name, the one in `custom/` is used (seen in
tests, not documented by television). New channels of ours go in `custom/`, so
an `update-channels` never mixes with them.

## Shared code

- `scripts/lib/herdr-run.sh`: `herdr_run_bin`, the path of `herdr-run`.
- `scripts/lib/scope-dirs.sh`: `scope_dirs`, "the current project, else the top
  zoxide directories".
- `scripts/lib/align-rows.sh`: `align_rows`, aligns the columns of a `list`
  output (name padded, then a value) and adds a display field.
- `scripts/dir-preview`: the preview of a directory (top-level directories as a
  tree, like yazi's). Channels pass the depth as a second argument.

Before copying a block between scripts, check whether it belongs in a library.

## Things to be aware of

- **Entries are tab-separated.** Fields are used with `{split:\t:N}` (counted
  from 0) in the display, preview and actions. When a script adds a display
  field, the channel has to point `display` at its new index.
- **No styling in `display`.** television does not parse ANSI codes in a
  `display` template (the raw codes show up), so a row can't have a bold or
  coloured part. Alignment with spaces is what is possible.
- **Keys are not listed in the status bar.** The bar at the bottom only shows
  television's own keys and can't be extended. A channel's own keys go in the
  preview panel footer (`[ui.preview_panel] footer`), which is only visible
  while the preview is shown. The action picker (`ctrl-x` by default) lists
  every action with its description.
- **An action without a key never runs.** Bind it in `[keybindings]`.
- **Previews run on every selection change.** Keep them cheap. A directory
  preview uses `dir-preview`, whose `--git-ignore` keeps `node_modules` and
  similar out of the tree.
- **Theme overrides win over the theme.** An entry in `[ui.theme_overrides]`
  replaces the same colour of the theme, so a leftover one can look like the
  theme isn't applied. `tv` reads the theme at start, so restart a popup after
  changing it.
- **Channels that start commands use `herdr-run`** (see the
  herdr-task-runner plugin's README). `herdr-run --work-dir DIR` without a
  command only goes to the directory.
- **The `channels` channel** previews the channel's file from `cable/custom`
  first, then from `cable`. Keep that order if the directories change again.

## Checking a change

- `bash -n` on the script, and run its subcommands from the shell with real
  data (`list`, `preview ...`).
- `tv list-channels` shows whether a channel file is found and parses; a typo
  in the TOML shows up there.
- How a channel looks (columns, footer, theme) can only be seen by opening it
  in `tv`. Say so when it wasn't.
