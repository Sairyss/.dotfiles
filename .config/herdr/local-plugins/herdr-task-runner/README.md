# herdr-task-runner

`bin/herdr-run` starts a command in herdr: in the focused pane, a new tab, a
split or a workspace, depending on the mode. `herdr-run --help` lists every
option; this page explains how it decides where a command goes. Outside herdr
the command just runs as is.

"Idle" below means the pane's shell is the foreground process, i.e. nothing is
running in it.

## Where a command goes

| Mode | Focused pane idle | Focused pane busy |
| --- | --- | --- |
| (default) | typed into the pane | new tab |
| `--tab` / `--job` | new tab | new tab |
| `--split` | new split next to the pane | new split |
| `--here` | runs in this terminal (e.g. a popup) | same |
| `--workspace` | typed into the pane when it is in `--cwd`, else see "Jumping to a directory" | see "Jumping to a directory" |
| `--work-dir DIR` | typed into the pane when it is in `DIR`, else see "Jumping to a directory" | new tab when the pane is in `DIR`, else see "Jumping to a directory" |

`--cwd DIR` only sets the directory for the default mode: an idle pane is reused
when it is already in `DIR`, otherwise a new tab opens there.

`--background` (`--bg`) starts the command without taking you there: it never
changes focus and shows a "Started in background" notification, since nothing
else shows it. In the workspace you are in it opens a new tab (never your
pane). With `--work-dir` in another workspace open there, an idle pane of it is
used (so the workspace's sidebar shows the app), else a new tab in it, else a
new workspace. With `--linger`, a success closes the tab after the linger and a
failure keeps it open marked failed. It conflicts with `--here` and `--split`.

Only one of `--tab`/`--job`, `--split`, `--workspace`, `--work-dir` and `--here`
may be given.

`--reuse` is for commands that should be open once per workspace (such as
lazygit). If a pane of the focused workspace already runs exactly that command
line in the foreground, herdr-run jumps to its tab instead of starting another.
Quotes and the program's directory are ignored when comparing, so `nvim .`
matches `nvim .` but not `nvim file`. It applies to the default and `--tab`
modes. Without it, every call opens a new tab (such as claude).

## Done and failed marks

With `--keep` or `--linger`, a command that finishes while you are looking
elsewhere stays in herdr's sidebar and notifications as "done" (or "failed")
until you focus its pane, so you can jump to it later. This works the same when
the command is typed into an idle pane as in a new tab. The difference is the
end: a new tab closes after the linger, an idle pane (your own shell) always
stays open, so `--linger` only affects new tabs, splits and workspaces.
`jobs.linger` is the duration `--job` and `--linger default` use (1m;
`$HERDR_RUN_LINGER` overrides it).

A failed command (non-zero exit, except Ctrl-C) with `--linger` skips the
countdown: its tab stays open and the "failed" mark stays until you focus the
pane. Without `--keep` or `--linger` a tab closes on exit whatever the status.

`prefix+o` (herdr's own `open_notification_target`) only works while the
notification toast is on screen. `bin/herdr-jump-done`, bound to `prefix+O`,
works for as long as the mark is in the sidebar: it focuses the agent or job
that has been done or failed the longest, and again for the next one. It only
looks at the machine where it runs. It never touches other machines' marks (the
API can only move that server's focus, not this client's view, and it would
clear the mark): switch to that machine and press `prefix+O` there.

## Jumping to a directory (`--workspace`, `--work-dir`)

For commands that have to run in a given directory (the tests of a project, a
Claude session).

Only an exact match counts: a pane whose directory is the directory itself (the
pane's shell directory or the directory of its foreground process, symlinks
resolved). A pane in a directory below or above it is never reused, and a pane
is never `cd`'ed to another directory. So with a `backend` workspace focused,
choosing the `mcp_server` project goes to the workspace of `mcp_server` (or
opens it) and leaves the `backend` pane alone.

1. **The focused pane is in the directory**: the default mode. An idle pane gets
   the command typed in, a busy one a new tab (in its workspace).
2. **Another workspace has a pane in the directory**:
   - an **idle pane** there: focus its workspace and tab and type the command
     into it;
   - only **busy panes** there: open a new tab in that workspace and run the
     command in it.
3. **No such workspace**: create a new workspace in the directory (named after
   it) and run the command there.

`--work-dir DIR` without a command only goes there: the same steps, but nothing
is typed and no tab is opened, so a busy workspace is just focused. Outside
herdr it starts `$SHELL` in `DIR`.

## Sidebar and agents panel (`sidebar.py`)

The same plugin keeps herdr's sidebar in step with the panes. `sidebar.py` has
these subcommands, started from `herdr-plugin.toml` (the last three are also
plugin actions):

- `watch` runs detached from the startup hook, subscribes to herdr's events and
  reconciles after bursts of them (plugin event hooks can't see `pane.updated`).
  If herdr refuses the subscription it logs that and retries after
  `watch.retry_delay`; it does not poll.
- `reconcile` is one idempotent pass. It registers nvim panes as agent `nvim`
  from their terminal title, tags slow commands as `kind=job`, and sets the
  workspace tokens `$title`, `$app`, `$tabs`, `$tasks`, `$cmd`, `$branch` and
  `$uncommitted`. `$tasks` is the number of tasks running in all tabs of the
  workspace, shown from `tasks.min_count` (default 2). Finished jobs still
  marked done or failed count until you focus their pane
  (`tasks.count_finished`); interactive apps such as nvim or lazygit
  (`jobs.ignore`), coding agents and shells don't count.
  The `git` calls for all workspaces run in parallel.
- `apply` installs the agents panel order: jobs, nvim, then real agents.
- `restart` replaces the running watcher, for after editing `sidebar.py`.
- `config` prints the effective settings.

It needs python 3.11+ and git.

### Settings

Nothing is hardcoded in the script. `config.default.toml` lists every setting
with its default and a comment. To change one, put only that key in
`~/.config/herdr/plugins/config/herdr-task-runner/config.toml` (or the file
`$HERDR_TASK_RUNNER_CONFIG` names); it is merged over the defaults table by
table, and a list replaces the default list. The dotfiles track that file as
`.config/herdr/herdr-task-runner/config.toml` and `scripts/sync-plugins.sh`
links it in.

Settings are read on every pass, so an edit applies with the next pane event.
A bad file is logged and ignored (the defaults are used), and unknown keys are
logged, so a typo doesn't fail silently. The herdr tools in `bin/` are bash
and take their settings from environment variables instead
(`HERDR_RUN_LINGER`, `HERDR_TASK_RUNNER_KEEP_KEY`), since they can't depend on
a TOML parser. The `[jobs]` table is the exception: `sidebar.py` writes it to
`shell.env` in the state dir, and `hooks.zsh`, `herdr-run` and `herdr-run-hold`
read that file (an environment variable of the same setting wins, e.g.
`HERDR_TASK_RUNNER_THRESHOLD`).

`scripts/sync-plugins.sh` links `herdr-run` and `herdr-run-hold` into
`~/.local/bin` (`$XDG_BIN_HOME`), so they are found by name wherever that is on
`PATH`. Otherwise `herdr-run` types `herdr-run-hold` anyway in zsh (a function
from `hooks.zsh`), then `"$HERDR_RUN_HOLD"`, then the full path.

### Jobs

Commands that run for a while show in the sidebar like an agent: working while
they run, then done or failed (blocked) until you look at the pane. herdr
notifies on that state change itself, so the plugin sends no toast. Two parts
do it, so the plugin doesn't need herdr-ohmyzsh:

- `hooks.zsh` (loaded by `shell.sh` in zsh inside a herdr pane) watches the
  lines you type, after `jobs.terminal_threshold` seconds. When one ends while
  you are looking elsewhere, it runs `herdr-run-hold --typed` from the prompt,
  so the entry stays as done (or failed) in the Agents panel until you focus
  the pane, like a `herdr-run` job. The prompt waits meanwhile; typed-ahead keys
  are kept.
- `herdr-run --keep/--linger` lines are shown as working by the same hooks
  after `jobs.run_threshold`; `herdr-run-hold` marks them done or failed.

`jobs.label_style` sets what an entry is called, which is also what herdr's
own notification says: `command` (default) names it after the whole command,
cut at 32 characters (`npm-run-docker-env-reset`), `program` after the first
word (`npm`). The sidebar's `$app` stays the program either way.

`jobs.report = false` turns the sidebar entries off. Environment variables
override the settings for one shell: `HERDR_TASK_RUNNER_THRESHOLD`,
`HERDR_TASK_RUNNER_RUN_THRESHOLD` and `HERDR_TASK_RUNNER_REPORT`.

`jobs.ignore` lists interactive programs that are never jobs (and never counted
in `$tasks`); `jobs.ignore_bare` lists REPLs that are ignored only without
arguments. The shells read the settings when they start, so a change reaches
the shells opened after it. herdr-ohmyzsh's `hsplit`/`htab`/`hagent`/
`hworktree`/`hreload` helpers and its `herdr` completions are not included.

### Logs

`sidebar.log` in the plugin's state dir
(`~/.local/state/herdr/plugins/herdr-task-runner/`, 200 KB, one backup). Set
`HERDR_TASK_RUNNER_DEBUG=1` for every herdr call and the time of each pass.

## Used by

- some television channels (`~/.config/television/cable/custom`)
- key bindings in `~/.config/herdr/config.toml`

## Trying it

`--dry-run` prints the mode, the directory and the exact herdr calls without
doing anything:

```sh
herdr-run --work-dir ~/some/project --dry-run npm test
```
