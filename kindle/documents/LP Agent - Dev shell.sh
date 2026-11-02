#!/bin/sh
# Name: LP Agent - Dev shell (on/off)
# Author: toanbku

# Developer shell. First tap: root telnet shell on port 2323 that ONLY accepts
# DEV_SHELL_ALLOW_IP from /mnt/us/lpdash/config.sh. Second tap: shell off, firewall rule removed.
# There is no password: never set DEV_SHELL_ALLOW_IP to anything but your own computer,
# and turn the shell off when you are done.
PORT=2323
PIDF=/mnt/us/lpdash/devshell.pid
mkdir -p /mnt/us/lpdash
[ -f /mnt/us/lpdash/config.sh ] && . /mnt/us/lpdash/config.sh
ALLOW=$DEV_SHELL_ALLOW_IP

if [ -f "$PIDF" ] && grep -q telnetd "/proc/$(cat "$PIDF")/cmdline" 2>/dev/null; then
  kill "$(cat "$PIDF")"; rm -f "$PIDF"
  [ -n "$ALLOW" ] && iptables -D INPUT -p tcp -s "$ALLOW" --dport $PORT -j ACCEPT 2>/dev/null
  echo "Dev shell OFF"
  exit 0
fi

case "$ALLOW" in
  *.*.*.*) ;;
  *) echo "Set DEV_SHELL_ALLOW_IP (your computer's LAN IP) in lpdash/config.sh first"; exit 1 ;;
esac
iptables -D INPUT -p tcp -s "$ALLOW" --dport $PORT -j ACCEPT 2>/dev/null
iptables -I INPUT -p tcp -s "$ALLOW" --dport $PORT -j ACCEPT
telnetd -F -p $PORT -l /bin/sh > /dev/null 2>&1 &
echo $! > "$PIDF"
IP=$(ifconfig wlan0 2>/dev/null | sed -n 's/.*inet addr:\([0-9.]*\).*/\1/p')
echo "Dev shell ON: $IP:$PORT (only accepts $ALLOW)"
echo "Open this item again to turn it off"
