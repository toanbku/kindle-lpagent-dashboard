#!/bin/sh
# Name: LP Agent Dashboard
# Author: toanbku

# Tap this "book" to start the data daemon and open the dashboard app (WAF com.lpagent.dashboard).
D=/mnt/us/lpdash
if [ ! -f "$D/config.sh" ]; then echo "Missing $D/config.sh (copy config.example.sh)"; exit 1; fi

nohup sh "$D/lpdashd.sh" > /dev/null 2>&1 &
lipc-set-prop com.lab126.powerd preventScreenSaver 1 2>/dev/null

# register the app if it is missing (first run, or after a reset)
if ! sqlite3 /var/local/appreg.db "select 1 from handlerIds where handlerId='com.lpagent.dashboard';" | grep -q 1; then
  sqlite3 /var/local/appreg.db < "$D/register_waf.sql" && echo "Registered the LP Agent app"
fi

echo "LP Agent: opening dashboard..."
# Open the app AFTER the scriptlet runner exits (it returns to Home and would cover the app otherwise)
nohup sh -c 'sleep 4; lipc-set-prop com.lab126.appmgrd start app://com.lpagent.dashboard' > /dev/null 2>&1 &
