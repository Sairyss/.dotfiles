# Source this file (it defines a function, it doesn't run anything):
#   source "${TELEVISION_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/television}/scripts/lib/align-rows.sh"
#
# align_rows NAME_FIELD VALUE_FIELD [CAP] [PREFIX_FIELD]
#   Filter for a channel's `list` output: reads tab-separated rows on stdin and prints each one again with a
#   display field added at the end, so the second column lines up in every row, like sesh's picker:
#     [PREFIX ]NAME padded to the widest name, three spaces, VALUE
#   The fields are numbered from 1. Names longer than CAP (default 40) are cut and end in "…", which also
#   keeps one long name from pushing the column far right. A VALUE under $HOME is shown with ~.
#   PREFIX_FIELD (optional) is a field printed before the name, e.g. a marker for open workspaces; give the
#   rows a blank one (" ") where there is nothing to mark, so the names stay aligned.
#   The channel then shows the new last field with `display = "{split:\t:N}"`.
#   Lengths are counted in bytes where awk is mawk, so non-ASCII names may be padded a little short.
align_rows() {
  local name_f=$1 value_f=$2 cap=${3:-40} prefix_f=${4:-0}
  awk -F'\t' -v nf="$name_f" -v vf="$value_f" -v cap="$cap" -v pf="$prefix_f" -v home="$HOME" '
    { rows[NR] = $0
      n = $nf
      if (length(n) > cap) n = substr(n, 1, cap - 1) "…"
      name[NR] = n
      if (length(n) > w) w = length(n) }
    END {
      for (i = 1; i <= NR; i++) {
        split(rows[i], f, "\t")
        v = f[vf]
        if (home != "" && index(v, home) == 1) v = "~" substr(v, length(home) + 1)
        pre = pf ? f[pf] " " : ""
        printf "%s\t%s%-" w "s   %s\n", rows[i], pre, name[i], v
      }
    }'
}
