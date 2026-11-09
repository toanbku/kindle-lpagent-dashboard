#!/bin/sh
# Hardware watchdog for the LP Agent dashboard (runs on the Kindle as root, busybox sh).
#
# Why: a Kindle left on 24/7 can freeze hard: the clock stops, Wi-Fi drops, nothing gets logged,
# and only holding the power button brings it back. The SoC has a hardware watchdog
# (i.MX6 imx2-wdt, /dev/watchdog0, 60 s): once opened, it must be written to regularly or it
# resets the device. This script writes to it every FEED seconds, so a frozen Kindle resets
# itself within about a minute and autostart.sh brings the dashboard back.
#
# Once a minute it also looks after the daemon:
#   - daemon gone but its pidfile left behind (it did not stop cleanly) -> start it again;
#   - daemon alive but its heartbeat is older than STALE seconds (stuck) -> reboot.
#   The reboot check turns itself off after 3 such reboots without a healthy hour in between,
#   so a bug in it cannot keep rebooting the Kindle.
#
# "LP Agent - Stop dashboard" stops it and disarms the chip (magic close "V").
# WATCHDOG=0 in config.sh turns it off.

D=${LPDASH_DIR:-/mnt/us/lpdash}
[ -f "$D/config.sh" ] && . "$D/config.sh"
DEV=${WDOG_DEV:-/dev/watchdog0}
HB=/var/tmp/lpdash.hb          # daemon heartbeat (uptime seconds), kept in RAM
FLAG=/var/tmp/lpwdog.reboot    # set by the check when it decided to reboot
PIDF=$D/lpwdog.pid
DPIDF=$D/lpdashd.pid
STRIKES=$D/wdog-strikes
: "${WATCHDOG:=1}" "${STALE:=900}" "${FEED:=10}"

log() { echo "$(date '+%m-%d %H:%M:%S') watchdog: $*" >> "$D/log.txt"; }
[ "$WATCHDOG" = "1" ] || exit 0

old=$(cat "$PIDF" 2>/dev/null)
if [ -n "$old" ] && [ "$old" != "$$" ] && grep -q lpwdog "/proc/$old/cmdline" 2>/dev/null; then
  echo "lpwdog is already running (pid $old)"; exit 0
fi
[ -c "$DEV" ] || { log "no $DEV, not started"; exit 0; }
exec 3>"$DEV" || { log "cannot open $DEV"; exit 1; }
echo $$ > "$PIDF"
rm -f "$FLAG"
renice -n -10 -p $$ > /dev/null 2>&1

SLP=
disarm() {
  [ -f "$FLAG" ] && return 0                   # our own reboot: stay armed (see the main loop)
  [ -n "$SLP" ] && kill $SLP 2>/dev/null
  printf V >&3; exec 3>&-
  [ "$(cat "$PIDF" 2>/dev/null)" = "$$" ] && rm -f "$PIDF"
  log "stopped, chip disarmed"; exit 0
}
trap disarm INT TERM

# Runs in the background once a minute, so a slow /mnt/us (USB mode) can never delay the feeding.
check_daemon() {
  p=$(cat "$DPIDF" 2>/dev/null)
  [ -n "$p" ] || return 0                       # no pidfile: stopped on purpose
  if ! grep -q lpdashd "/proc/$p/cmdline" 2>/dev/null; then
    log "daemon pid $p is gone -> starting it again"
    rm -f "$DPIDF"; nohup sh "$D/lpdashd.sh" > /dev/null 2>&1 &
    return 0
  fi
  read hb _ < "$HB" 2>/dev/null || return 0
  case "$hb" in ''|*[!0-9]*) return 0 ;; esac
  read up _ < /proc/uptime; up=${up%.*}; age=$((up - hb))
  s=$(cat "$STRIKES" 2>/dev/null); case "$s" in ''|*[!0-9]*) s=0 ;; esac
  if [ "$age" -gt "$STALE" ]; then
    [ "$s" -ge 3 ] && return 0
    echo $((s + 1)) > "$STRIKES"
    log "daemon heartbeat is ${age}s old (stuck) -> reboot (strike $((s + 1))/3)"
    touch "$FLAG"; sync; reboot
  elif [ "$s" -gt 0 ] && [ "$up" -gt 3600 ]; then
    rm -f "$STRIKES"; log "healthy for an hour, reboot strikes reset"
  fi
}

log "started pid $$ on $DEV (feed every ${FEED}s, daemon counts as stuck after ${STALE}s)"
n=0; CHK=
while :; do
  if [ -f "$FLAG" ]; then
    # A reboot is under way: keep the chip armed (ignore the TERM from shutdown) and stop feeding,
    # so the chip resets the Kindle if the reboot hangs too.
    trap '' INT TERM
    while :; do sleep 60; done
  fi
  printf . >&3
  n=$((n + 1))
  if [ $((n * FEED % 60)) -lt "$FEED" ] && ! grep -q lpwdog "/proc/${CHK:-x}/cmdline" 2>/dev/null; then
    check_daemon & CHK=$!
  fi
  sleep "$FEED" & SLP=$!; wait $SLP; SLP=
done
