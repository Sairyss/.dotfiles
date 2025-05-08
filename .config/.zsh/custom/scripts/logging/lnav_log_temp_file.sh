#!/bin/bash

# run lnav on temp file created by other script
# https://github.com/tstack/lnav

sleep 0.2
LOGFILE="/tmp/temp_app_log_1234.json.log"
lnav "$LOGFILE"
