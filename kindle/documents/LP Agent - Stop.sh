#!/bin/sh
# Name: LP Agent - Stop dashboard
# Author: toanbku

# Stop the watchdog and the daemon, and give the normal screensaver back.
D=/mnt/us/lpdash
# watchdog first (TERM makes it disarm the chip), then the daemon
W=$(cat "$D/lpwdog.pid" 2>/dev/null)
if [ -n "$W" ] && grep -q lpwdog "/proc/$W/cmdline" 2>/dev/null; then kill "$W"; sleep 1; fi
P=$(cat "$D/lpdashd.pid" 2>/dev/null)
if [ -n "$P" ] && grep -q lpdashd "/proc/$P/cmdline" 2>/dev/null; then kill "$P"; fi
rm -f "$D/lpdashd.pid"
lipc-set-prop com.lab126.powerd preventScreenSaver 0 2>/dev/null
echo "LP Agent dashboard stopped"
