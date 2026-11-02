#!/bin/bash
# Render the Kindle app with headless Chrome to check the layout before copying it to the device.
#   tools/render-test.sh        real data from kindle/lpdash/data/ (see "Local preview" in the README)
#   tools/render-test.sh demo   fake data from kindle/apps/xyz.lpagent.dashboard/demo/
# Screenshots go to out/ (pages 1 and 2, PW4 size 1072x1448 and a smaller 758x1024).
set -e; cd "$(dirname "$0")/.."
C="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
OUT="$PWD/out"; mkdir -p "$OUT"
Q=""; [ "$1" = demo ] && Q="demo=1&"
for sz in 1072,1448 758,1024; do
  for pg in 1 2; do
    f="$OUT/${1:-real}-p$pg-${sz/,/x}.png"
    "$C" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 --window-size=$sz \
      --virtual-time-budget=5000 --allow-file-access-from-files \
      --screenshot="$f" "file://$PWD/kindle/apps/xyz.lpagent.dashboard/index.html?${Q}page=$pg" >/dev/null 2>&1
    echo "$f"
  done
done
