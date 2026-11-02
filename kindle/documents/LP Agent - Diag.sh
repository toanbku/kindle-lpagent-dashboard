#!/bin/sh
# Name: LP Agent - Diag
# Author: toanbku

# Dump system info to /mnt/us/lpdash/diag.txt for debugging (read-only, changes nothing).
O=/mnt/us/lpdash/diag.txt
mkdir -p /mnt/us/lpdash
{
  echo "== id / uname / version"; id; uname -a; cat /etc/prettyversion.txt 2>/dev/null
  echo "== appreg: store/browser/waf"
  sqlite3 /var/local/appreg.db "select handlerId,name,value from properties where handlerId like 'com.lab126.store%' or handlerId like 'com.lab126.browser%' or handlerId like 'com.lab126.web%' or value like '%mesquite%' or value like '%waf%' or value like '%wafapp%';"
  echo "== appreg: associations store/browser"
  sqlite3 /var/local/appreg.db "select * from associations where handlerId like 'com.lab126.store%' or handlerId like 'com.lab126.browser%';"
  echo "== appreg: handlerIds com.lab126.*"
  sqlite3 /var/local/appreg.db "select handlerId from handlerIds where handlerId like 'com.lab126.%' order by 1;" | tr '\n' ' '; echo
  echo "== waf dirs"
  ls -la /var/local/mesquite /opt/var/local/mesquite /var/local/waf /usr/share/webkit-1.0 2>&1 | head -60
  echo "== config.xml files"
  find /var/local /opt/var /usr/share /app 2>/dev/null -maxdepth 4 -name config.xml | head -20
  F=$(find /var/local /opt/var /usr/share /app 2>/dev/null -maxdepth 4 -name config.xml | grep -i store | head -1)
  echo "-- $F"; cat "$F" 2>/dev/null
  F2=$(find /var/local /opt/var /usr/share /app 2>/dev/null -maxdepth 4 -name config.xml | grep -i browser | head -1)
  echo "-- $F2"; cat "$F2" 2>/dev/null
  echo "== binaries"; ls -la /usr/bin/mesquite* /usr/bin/*waf* /usr/bin/browser* /usr/bin/webreader* 2>&1
  echo "== ps"; ps | grep -i -E 'mesquite|waf|lpdash|curl|browser' | grep -v grep
  echo "== lpdash"; ls -la /mnt/us/lpdash /mnt/us/lpdash/data 2>&1; tail -20 /mnt/us/lpdash/log.txt 2>&1
  echo "== curl"; curl --version 2>&1 | head -2
  echo "== date/tz"; date; date -u; cat /var/local/system/tz 2>/dev/null; echo "TZ=$TZ"
  echo "== powerd"; lipc-get-prop com.lab126.powerd preventScreenSaver 2>&1; lipc-get-prop com.lab126.powerd state 2>&1
  echo "== wifi"; lipc-get-prop com.lab126.wifid cmState 2>&1
} > "$O" 2>&1
echo "Diag done: lpdash/diag.txt"
