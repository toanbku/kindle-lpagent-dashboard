#!/bin/sh
# The jailbreak's upstart job (/etc/upstart/kmc.conf) runs this file on every boot, synchronously,
# so it must return right away. Here it only starts the LP Agent dashboard in the background.
[ -f /mnt/us/lpdash/autostart.sh ] && nohup sh /mnt/us/lpdash/autostart.sh > /dev/null 2>&1 &
exit 0
