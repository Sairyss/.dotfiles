#!/usr/bin/env bash
# Usage: launch-linger.sh DURATION | @DEADLINE_EPOCH      (DURATION: 90 / 90s / 1m / 1h / 1d)
# Called by launch.sh for --linger, in place of a plain `sleep`: counts DURATION down on the terminal,
# then exits 0, which tells the caller to close the pane.
#   Ctrl-C            close now (exit 0)
#   the keep key      cancel the countdown and keep the pane open (exit 1); default `k`,
#                     override with LAUNCH_KEEP_KEY
set -u

keep_key="${LAUNCH_KEEP_KEY:-k}"

if [[ $1 == @* ]]; then # an absolute deadline (epoch seconds), as given by launch-hold.sh
  end="${1#@}"
else
  n="${1%[smhd]}"
  case ${1: -1} in
    m) total=$((n * 60)) ;;
    h) total=$((n * 3600)) ;;
    d) total=$((n * 86400)) ;;
    *) total=$n ;;
  esac
  end=$(($(date +%s) + total))
fi
total=$((end - $(date +%s)))
((total > 0)) || exit 0 # already over

# no terminal to read keys from: behave like sleep
if ! { : </dev/tty; } 2>/dev/null; then sleep "$total"; exit 0; fi

trap 'printf "\r\033[2K"; exit 0' INT
while read -rsn1 -t 0.01 _ </dev/tty; do :; done # drop keys typed while the command ran

while ((left = end - $(date +%s), left > 0)); do
  printf '\r\033[2K[launch] closing in %ss  ·  %s: keep this tab open  ·  Ctrl-C: close now' "$left" "$keep_key"
  if read -rsn1 -t 1 key </dev/tty && [[ $key == "$keep_key" ]]; then
    printf '\r\033[2K[launch] kept open\n'
    exit 1
  fi
done
printf '\r\033[2K'
exit 0
