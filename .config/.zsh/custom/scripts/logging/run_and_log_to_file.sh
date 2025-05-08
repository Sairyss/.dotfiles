#!/bin/bash

# This script runs an app and captures + parses its output into a log file.
# This is useful when you want to view your logs in a log parsing tool like lnav
# https://github.com/tstack/lnav

set -e

cleanup() {
  if [[ -f "$LOGFILE" ]]; then
    echo "Removing temp log file: $LOGFILE"
    rm -f "$LOGFILE"
  fi
}
trap cleanup EXIT SIGINT SIGTERM

if [ $# -eq 0 ]; then
  echo "Usage: $0 <your-app-command> [args...]"
  exit 1
fi

# Create a temp log file by default
LOGFILE="/tmp/temp_app_log_1234.json.log"
touch "$LOGFILE"
echo "$LOGFILE"

# If output is not json, wrap it to json. Otherwise keep original json
(
  "$@" 2>&1 &
) | while IFS= read -r line; do
  if echo "$line" | jq -e . >/dev/null 2>&1; then
    echo "$line"
  else
    escaped=$(echo "$line" | sed 's/\\/\\\\/g; s/"/\\"/g')
    echo "{ \"_nonJson\": \"$escaped\" }"
  fi
done >>"$LOGFILE"
