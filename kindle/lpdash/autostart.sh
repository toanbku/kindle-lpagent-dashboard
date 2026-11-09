#!/bin/sh
# Start the dashboard after the Kindle boots.
# Called from /mnt/us/emergency.sh, which the jailbreak's upstart job (kmc.conf) runs at framework_ready.
# To disable autostart: create /mnt/us/lpdash/autostart.off (or delete /mnt/us/emergency.sh).
# Safety net: 3 boots within 15 minutes -> autostart.off is created automatically (no boot loops).
# It also starts lpwdog.sh, the hardware watchdog that resets the Kindle if it freezes.
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

# What happened to the previous run: why the Kindle restarted (PWRON_LONGPRESS = power button held;
# a watchdog reset shows a different reason) and the last status line the daemon wrote.
[ -f "$D/heartbeat.txt" ] && mv "$D/heartbeat.txt" "$D/heartbeat.prev.txt"
rm -f "$D/messages.prev.txt" "$D/messages.prev.1.txt" "$D/messages.tail"
[ -f "$D/messages.live" ] && mv "$D/messages.live" "$D/messages.prev.txt"
[ -f "$D/messages.live.1" ] && mv "$D/messages.live.1" "$D/messages.prev.1.txt"
reason=$(dmesg | sed -n 's/.*Reboot Reason: *//p' | head -n 1)
log "boot (reboot reason: ${reason:-unknown}), last heartbeat: $(head -n 1 "$D/heartbeat.prev.txt" 2>/dev/null)"
rm -f "$D/lpdashd.pid"      # left behind if the last run froze; no daemon can be running yet
nohup sh "$D/lpwdog.sh" > /dev/null 2>&1 &
# DEV_SHELL_AT_BOOT=1 in config.sh: turn the dev shell on at every boot (it is off after a restart)
grep -q '^DEV_SHELL_AT_BOOT=1' "$D/config.sh" 2>/dev/null && sh "/mnt/us/documents/LP Agent - Dev shell.sh" > /dev/null 2>&1

log "waiting for the UI and Wi-Fi..."
sleep 60
nohup sh "$D/lpdashd.sh" > /dev/null 2>&1 &
sleep 30
lipc-set-prop com.lab126.appmgrd start app://com.lpagent.dashboard
log "daemon started + dashboard opened"
