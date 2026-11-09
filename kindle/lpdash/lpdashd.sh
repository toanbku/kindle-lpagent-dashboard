#!/bin/sh
# LP Agent dashboard daemon (runs on the Kindle as root, busybox sh).
# Every INTERVAL seconds it calls the LP Agent Open API with curl and writes data/*.js
# for the dashboard app to load. It also keeps the screen awake and flashes the
# e-ink panel now and then to clear ghosting.

DIR=${LPDASH_DIR:-/mnt/us/lpdash}
. "$DIR/config.sh"            # LPA_KEY LPA_OWNER LPA_CHAIN INTERVAL FLASH_EVERY ...
API=https://api.lpagent.io/open-api/v1
DATA=$DIR/data
LOG=$DIR/log.txt
PIDF=$DIR/lpdashd.pid
HBF=/var/tmp/lpdash.hb          # heartbeat (uptime seconds) that lpwdog.sh checks, in RAM
LIVE=$DIR/messages.live         # copy of the system log, see startlog()
FBINK=${FBINK:-/mnt/us/libkh/bin/fbink}
: "${INTERVAL:=300}" "${FLASH_EVERY:=12}" "${GAP:=6}"

mkdir -p "$DATA"
log() { echo "$(date '+%m-%d %H:%M:%S') $*" >> "$LOG"; }
nap() { sleep "$1" & SLP=$!; wait $SLP; SLP=; }   # a sleep that SIGTERM can interrupt
beat() { read up _ < /proc/uptime; echo "${up%.*}" > "$HBF"; }
memavail() { awk '/^MemAvailable:/ {print $2 "k"}' /proc/meminfo; }

# Single instance: quit if the pid in the pidfile is alive AND its /proc cmdline is lpdashd.
# (Don't use ps: a child that has forked but not exec'd yet still shows as lpdashd.sh.)
old=$(cat "$PIDF" 2>/dev/null)
if [ -n "$old" ] && [ "$old" != "$$" ] && grep -q lpdashd "/proc/$old/cmdline" 2>/dev/null; then
  echo "lpdashd is already running (pid $old)"; exit 0
fi
echo $$ > "$PIDF"
cleanup() { [ -n "$SLP" ] && kill $SLP 2>/dev/null; [ -n "$LOGP" ] && kill $LOGP 2>/dev/null
  [ "$(cat "$PIDF" 2>/dev/null)" = "$$" ] && rm -f "$PIDF"; log "stop pid $$"; exit 0; }
trap cleanup INT TERM

# fetch <name> <path> <extra query>  ->  data/<name>.js  (window.LPRAW.<name> = {...})
fetch() {
  name=$1; url="$API$2?chain=$LPA_CHAIN&owner=$LPA_OWNER$3"; i=0
  while [ $i -lt 4 ]; do
    beat
    code=$(curl -sS -m 40 -o "$DATA/.$name.json" -w '%{http_code}' \
      -H "x-api-key: $LPA_KEY" -H 'accept: application/json' "$url" 2>>"$LOG")
    if [ "$code" = "200" ] && [ -s "$DATA/.$name.json" ]; then
      { printf 'window.LPRAW=window.LPRAW||{};LPRAW.%s=' "$name"
        cat "$DATA/.$name.json"; printf ';\n'; } > "$DATA/.$name.js" \
        && mv "$DATA/.$name.js" "$DATA/$name.js"
      rm -f "$DATA/.$name.json"
      return 0
    fi
    log "$name: HTTP $code (try $((i + 1)))"
    if [ "$code" = "429" ]; then nap $((15 * (i + 1))); else nap 5; fi
    i=$((i + 1))
  done
  return 1
}

# Keep the device awake. preventScreenSaver can get reset to 0 (app switches, other tools),
# so set it again every minute. If the screensaver is already up, wake the device.
keepalive() {
  beat
  lipc-set-prop com.lab126.powerd preventScreenSaver 1 2>/dev/null
  st=$(lipc-get-prop com.lab126.powerd state 2>/dev/null)
  # Evidence for when the whole Kindle freezes: a status line on /mnt/us (autostart.sh moves it to
  # heartbeat.prev.txt at the next boot). susp/fail count system suspends since boot.
  echo "$(date '+%m-%d %H:%M:%S') up=${up%.*}s state=$st memavail=$(memavail) load=$(cut -d' ' -f1-3 /proc/loadavg)" \
    "susp=$(sed -n 's/^success: //p' /sys/kernel/debug/suspend_stats 2>/dev/null) fail=$(sed -n 's/^fail: //p' /sys/kernel/debug/suspend_stats 2>/dev/null)" \
    > "$DIR/heartbeat.txt"
  # lpwdog.sh bind-mounts this file over /sys/power/state: anything in it is a blocked suspend request
  if [ -s /var/tmp/lpdash.power_state ]; then
    log "blocked a suspend request ($(head -c 20 /var/tmp/lpdash.power_state)), powerd state=$st"
    : > /var/tmp/lpdash.power_state
  fi
  case "$st" in
    screenSaver|readyToSuspend|suspended)
      log "device is in $st -> waking it up"
      # wakeUp only exists while the screensaver is showing
      lipc-set-prop com.lab126.powerd wakeUp 1 2>/dev/null || lipc-set-prop com.lab126.powerd powerButton 1 2>/dev/null
      # Kindles with Special Offers stay on the "Swipe to unlock" ad after waking: unload it
      nap 3; lipc-set-prop com.lab126.blanket unload ad_screensaver 2>/dev/null
      ;;
  esac
}
# long sleep that still runs keepalive once a minute
idle() { left=$1; while [ "$left" -gt 0 ]; do keepalive; s=60; [ "$left" -lt 60 ] && s=$left; nap "$s"; left=$((left - s)); done; }

# /var/log/messages lives in RAM and is lost when a frozen Kindle is restarted, so copy it line by
# line to /mnt/us (rotated at ~400 KB; autostart.sh renames it to messages.prev.txt at boot), and
# make the kernel write dirty data out after 3 s instead of 30 s so the last lines reach the disk.
LOGP=
startlog() { tail -n 0 -F /var/log/messages >> "$LIVE" 2>/dev/null & LOGP=$!; }
echo 300 > /proc/sys/vm/dirty_expire_centisecs 2>/dev/null
startlog

log "start pid $$ chain=$LPA_CHAIN interval=${INTERVAL}s"
# Frontlight: FRONTLIGHT in config (0 = off). Only set at start, so manual changes stick.
[ -n "$FRONTLIGHT" ] && lipc-set-prop com.lab126.powerd flIntensity "$FRONTLIGHT" 2>/dev/null
n=0
while :; do
  keepalive
  ok=0
  fetch open     /lp-positions/opening    ""          && ok=$((ok + 1)); nap "$GAP"
  fetch overview /lp-positions/overview   ""          && ok=$((ok + 1)); nap "$GAP"
  fetch closed   /lp-positions/historical "&limit=20" && ok=$((ok + 1)); nap "$GAP"
  fetch balance  /token/balance           ""          && ok=$((ok + 1))
  printf 'window.LPRAW=window.LPRAW||{};LPRAW.meta={fetchedAt:%s,ok:%s,total:4,chain:"%s",owner:"%s",interval:%s,tz:%s};\n' \
    "$(date +%s)" "$ok" "$LPA_CHAIN" "$LPA_OWNER" "$INTERVAL" "${TZ_OFFSET_MIN:-0}" > "$DATA/.meta.js" && mv "$DATA/.meta.js" "$DATA/meta.js"
  log "fetch $ok/4 memavail=$(memavail)"
  [ -n "$ONESHOT" ] && { rm -f "$PIDF"; exit 0; }   # testing: run one round and quit

  n=$((n + 1))
  if [ $((n % FLASH_EVERY)) -eq 0 ] && [ -x "$FBINK" ]; then
    nap 75                         # let the page draw the new data first
    "$FBINK" -q -s -f 2>/dev/null  # full flashing refresh, clears ghosting
  fi

  # keep the log under ~200KB
  if [ "$(wc -c < "$LOG")" -gt 200000 ]; then tail -n 500 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"; fi
  if [ "$(wc -c < "$LIVE" 2>/dev/null || echo 0)" -gt 400000 ]; then kill $LOGP 2>/dev/null; mv "$LIVE" "$LIVE.1"; startlog; fi
  idle "$INTERVAL"
done
