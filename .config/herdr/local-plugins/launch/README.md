# launch

`bin/herdr-run` starts a command in herdr: in the focused pane, a new tab, a split or a workspace,
depending on the mode. `herdr-run --help` lists every option; this page explains how it decides where
a command goes. Outside herdr the command just runs as is.

"Idle" below means the pane's shell is the foreground process, i.e. nothing is running in it.

## Where a command goes

| Mode | Focused pane idle | Focused pane busy |
| --- | --- | --- |
| (default) | typed into the pane | new tab |
| `--tab` / `--job` | new tab | new tab |
| `--split` | new split next to the pane | new split |
| `--here` | runs in this terminal (e.g. a popup) | same |
| `--workspace` | typed into the pane when it is in `--cwd`, else see "Jumping to a directory" | see "Jumping to a directory" |
| `--work-dir DIR` | typed into the pane when it is in `DIR`, else see "Jumping to a directory" | new tab when the pane is in `DIR`, else see "Jumping to a directory" |

`--cwd DIR` only sets the directory for the default mode: an idle pane is reused when it is already
in `DIR`, otherwise a new tab opens there.

`--background` (`--bg`) starts the command without taking you there: it never
changes focus and shows a "Started in background" notification, since nothing
else shows it. In the workspace you are in it opens a new tab (never your
pane). With `--work-dir` in another workspace open there, an idle pane of it is
used (so the workspace's sidebar shows the app), else a new tab in it, else a
new workspace. With `--linger`, a success closes the tab after the linger and a
failure keeps it open marked failed. It conflicts with `--here` and `--split`.

Only one of `--tab`/`--job`, `--split`, `--workspace`, `--work-dir` and `--here` may be given.

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

A failed command (non-zero exit, except Ctrl-C) with `--linger` skips the
countdown: its tab stays open and the "failed" mark stays until you focus the
pane. Without `--keep` or `--linger` a tab closes on exit whatever the status.

`prefix+o` (herdr's own `open_notification_target`) only works while the
notification toast is on screen. `bin/herdr-jump-done`, bound to `prefix+O`,
works for as long as the mark is in the sidebar: it focuses the agent or job
that has been done or failed the longest, and again for the next one. It only
looks at the machine where it runs. It never touches other machines' marks (the API
can only move that server's focus, not this client's view, and it would clear
the mark): switch to that machine and press `prefix+O` there.

## Jumping to a directory (`--workspace`, `--work-dir`)

For commands that have to run in a given directory (the tests of a project, a Claude session).

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
is typed and no tab is opened, so a busy workspace is just focused. Outside herdr
it starts `$SHELL` in `DIR`.

## Used by

- some television channels (`~/.config/television/cable/custom`)
- key bindings in `~/.config/herdr/config.toml`

## Trying it

`--dry-run` prints the mode, the directory and the exact herdr calls without
doing anything:

```sh
herdr-run --work-dir ~/some/project --dry-run npm test
```
