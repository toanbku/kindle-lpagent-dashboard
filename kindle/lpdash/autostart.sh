#!/bin/sh
# Start the dashboard after the Kindle boots.
# Called from /mnt/us/emergency.sh, which the jailbreak's upstart job (kmc.conf) runs at framework_ready.
# To disable autostart: create /mnt/us/lpdash/autostart.off (or delete /mnt/us/emergency.sh).
# Safety net: 3 boots within 15 minutes -> autostart.off is created automatically (no boot loops).
D=/mnt/us/lpdash
BOOTS=$D/boots.txt
log() { echo "$(date '+%m-%d %H:%M:%S') autostart: $*" >> "$D/log.txt"; }

[ -f "$D/autostart.off" ] && { log "disabled (autostart.off)"; exit 0; }

now=$(date +%s)
echo "$now" >> "$BOOTS"
recent=0
for t in $(tail -n 3 "$BOOTS"); do [ $((now - t)) -lt 900 ] && recent=$((recent + 1)); done
if [ "$recent" -ge 3 ]; then
  touch "$D/autostart.off"; log "$recent boots in 15 minutes -> autostart DISABLED to be safe"; exit 0
fi
tail -n 10 "$BOOTS" > "$BOOTS.tmp" && mv "$BOOTS.tmp" "$BOOTS"

log "boot, waiting for the UI and Wi-Fi..."
sleep 60
nohup sh "$D/lpdashd.sh" > /dev/null 2>&1 &
sleep 30
lipc-set-prop com.lab126.appmgrd start app://com.lpagent.dashboard
log "daemon started + dashboard opened"
