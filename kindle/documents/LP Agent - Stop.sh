#!/bin/sh
# Name: LP Agent - Stop dashboard
# Author: toanbku

# Stop the daemon and give the normal screensaver back.
D=/mnt/us/lpdash
P=$(cat "$D/lpdashd.pid" 2>/dev/null)
if [ -n "$P" ] && grep -q lpdashd "/proc/$P/cmdline" 2>/dev/null; then kill "$P"; fi
rm -f "$D/lpdashd.pid"
lipc-set-prop com.lab126.powerd preventScreenSaver 0 2>/dev/null
echo "LP Agent dashboard stopped"
