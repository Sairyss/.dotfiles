# AGENTS.md

Guidelines for working on these dotfiles. They apply to every config, script
and channel in the repo.

## Scripts must work on any machine

- No machine-specific paths (`/home/<user>`, mount points) and no real
  project, company or user names in scripts, configs or docs. Examples in
  comments must be generic.
- Don't use relative paths to reach other files in the repo (`../lib`,
  `$(dirname "$0")`). Build the full path from an environment variable with a
  default, so it keeps working when files move:
  - television: `${TELEVISION_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/television}`
  - herdr: `${XDG_CONFIG_HOME:-$HOME/.config}/herdr`
  - Claude Code: `${CLAUDE_CONFIG_DIR:-$HOME/.claude}`
- Let the user override a tool's location with an environment variable
  (e.g. `$HERDR_RUN`) before falling back to `PATH` and then to the default
  install location. A key binding or popup may not have your shell's `PATH`.
- In docs, write paths as `~/.config/...`, not relative ones.
- Say which tools a script needs (`requirements` in a channel, a comment in a
  script). Don't assume GNU-only behaviour when a portable form is as easy.

## Shell scripts

- `#!/usr/bin/env bash`, `set -euo pipefail`, and a usage line at the top.
- One script per feature with subcommands (`list`, `preview`, `run`, ...)
  instead of long shell one-liners inside TOML files.
- Put logic shared by several scripts in a sourceable library and document it
  at the top of the file. Libraries only define functions. Current ones are in
  `.config/television/scripts/lib/`.
- Keep the same density of comments as the surrounding code: explain why, not
  what.

## Television channels (`.config/television/cable/custom`)

- Our own channels live in `cable/custom`, apart from the defaults that
  `tv update-channels` downloads into `cable`. tv reads `cable` recursively, and
  when two channels have the same name the one in `custom` is used.
- An action only runs when a key is bound to it: add
  `[keybindings] enter = "actions:<name>"`.
- Pass fields between source, preview and actions with tab-separated entries
  and `{split:\t:N}`. Don't set `output` when an action needs other fields of
  the entry.
- Use TOML literal strings (`'''...'''`) for commands that contain quotes or
  backslashes.
- Give every action a description that says what it really does, and check
  them after copying a channel.
- Keep channels generic where a pattern repeats. For example, "the current
  project, else the top zoxide directories" is `scope_dirs` in
  `lib/scope-dirs.sh`; reuse it instead of copying it.
- Don't write a list of specific channels in docs. They change; say "some
  channels".

## Running commands in herdr

- Start commands from channels and key bindings with `herdr-run`, not by
  typing into panes yourself. How it picks the pane, tab or workspace is
  described in `.config/herdr/local-plugins/herdr-task-runner/README.md`; keep
  that file and the usage notes at the top of `bin/herdr-run` up to date when
  behaviour changes.
- Commands that have to run in a certain directory use `--work-dir DIR`.
  Long-running commands use `--job`.
- `herdr-run` depends only on bash, grep, sed, cut, head and date. Don't add
  other dependencies (such as jq) to it.
- Options that pick where a command runs conflict with each other. Reject the
  combination with an error that names both flags.

## Verifying changes

- Test script pieces from the shell with real data before wiring them in.
- Use `herdr-run --dry-run` to check what would happen. Don't open workspaces
  or tabs in the user's live session just to test.
- After a rename or move, a syntax check (`bash -n`) and a grep for old
  names are enough. Don't re-run everything.
- Say what was and wasn't run, e.g. that a channel loads in `tv` but was not
  used in the popup.

## Docs

- Markdown lines are wrapped at 80 characters (markdownlint MD013).
