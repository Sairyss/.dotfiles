# launch

`bin/herdr-run` starts a command in herdr: in the focused pane, a new tab, a split or a workspace,
depending on the mode. `herdr-run --help` lists every option; this page explains how it decides where
a command goes. Outside herdr the command just runs as is.

"Idle" below means the pane's shell is the foreground process, i.e. nothing is running in it.

## Where a command goes

| Mode | Focused pane idle | Focused pane busy |
|---|---|---|
| (default) | typed into the pane | new tab |
| `--tab` / `--job` | new tab | new tab |
| `--split` | new split next to the pane | new split |
| `--here` | runs in this terminal (e.g. a popup) | same |
| `--workspace` | `cd` to `--cwd` if needed, then typed into the pane | see "Jumping to a directory" |
| `--work-dir DIR` | same as `--workspace` when the pane is not in `DIR`; typed into the pane when it is | new tab when the pane is in `DIR`, else see "Jumping to a directory" |

`--cwd DIR` only sets the directory for the default mode: an idle pane is reused when it is already
in `DIR`, otherwise a new tab opens there.

Only one of `--tab`/`--job`, `--split`, `--workspace`, `--work-dir` and `--here` may be given.

## Done and failed marks

With `--keep` or `--linger`, a command that finishes while you are looking
elsewhere stays in herdr's sidebar and notifications as "done" (or "failed")
until you focus its pane, so you can jump to it later. This works the same when
the command is typed into an idle pane as in a new tab. The difference is the
end: a new tab closes after the linger, an idle pane (your own shell) always
stays open, so `--linger` only affects new tabs, splits and workspaces.

## Jumping to a directory (`--workspace`, `--work-dir`)

For commands that have to run in a given directory (the tests of a project, a Claude session).

1. **The focused pane is idle**: it is `cd`'ed to the directory (on its own line, so herdr's sidebar
   still labels it by the command) and the command is typed into it. Not if the
   workspace was renamed by hand, i.e. its name is not the name of the pane's
   directory or of any directory above it (so a workspace named after the
   directory it was opened in, like sesh does, still counts after a `cd` into a
   subfolder): such a workspace stays where it is and the command goes to
   another workspace (step 2).
2. **The focused pane is busy**: look for a workspace that already has a pane in
   the directory or below it (the pane's shell directory or the directory of its
   foreground process, symlinks resolved). A workspace renamed by hand is
   skipped when its pane is only below the directory.
   - an **idle pane** there: focus its workspace and tab, `cd` it to the
     directory if it is below it, and type the command into it;
   - only **busy panes** there: open a new tab in that workspace and run the
     command in it;
   - **no such workspace**: create a new workspace in the directory (named after
     it) and run it there.

`--work-dir DIR` adds one shortcut in front of this: when the focused pane is already in `DIR` it
behaves exactly like the default mode (idle: typed in, busy: new tab), so no other workspace is touched.

## Used by

- some television channels (`~/.config/television/cable`)
- key bindings in `~/.config/herdr/config.toml`

## Trying it

`--dry-run` prints the mode, the directory and the exact herdr calls without
doing anything:

```sh
herdr-run --work-dir ~/some/project --dry-run npm test
```
