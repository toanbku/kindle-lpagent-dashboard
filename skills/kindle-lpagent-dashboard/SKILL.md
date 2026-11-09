---
name: kindle-lpagent-dashboard
description: Install, configure, update and troubleshoot the LP Agent e-ink dashboard on a jailbroken Kindle (standalone - a busybox shell daemon pulls the LP Agent Open API and a local WAF web app draws it, no server). Use when someone wants to turn a Kindle into an LP Agent dashboard, copy or deploy it over USB or Wi-Fi, change its config or layout, or fix it (no data, stale data, screensaver, unexpected restarts, app not opening, can't reach the dev shell).
---

# Kindle LP Agent dashboard

The project lives at https://github.com/toanbku/kindle-lpagent-dashboard. The README there is the user-facing manual. This
file is the operator's checklist plus the gotchas that cost time.

**Find the files first.**
- If this skill was installed with the plugin, the repo root is two levels above this skill's base directory
  (`<base>/../..`), and `kindle/lpdash/lpdashd.sh` must exist there.
- Otherwise, clone the repo into a working folder.

**Map of the repo:**
- `kindle/` is a mirror of the Kindle's user storage `/mnt/us`. On macOS it is mounted at `/Volumes/Kindle`.
- `tools/` holds the scripts that run on the computer: `ksh.py`, `kshot.py` and `render-test.sh`.

## Ground rules

- **The API key is a secret.**
  - Never print it, echo it, paste it into chat or put it in a commit.
  - When showing `config.sh`, redact `LPA_KEY`, e.g. `sed -E 's/(LPA_KEY=).*/\1<redacted>/'`.
  - `config.sh` is gitignored. Keep it that way.
- **Jailbreaking is the user's call.** It can brick the device.
  - Explain the risk, link the [Kindle Modding guide](https://kindlemodding.org) (WinterBreak) and let the user do the steps on the device.
  - Until the device is jailbroken, it must stay in airplane mode, because an automatic update can close the exploit.
- **Don't edit a shell script while it runs.** For the daemon, the order is: stop it, copy the file, start it.
- **The watchdog (`lpwdog.sh`) holds the hardware watchdog open.** Stop it only with a plain `kill` (TERM), which
  disarms the chip. `kill -9` or `kill -STOP` on it resets the Kindle within 60 s. If the daemon is killed hard and
  leaves its pidfile behind, the watchdog starts it again within a minute.
- **Never send a suspend request to test something** (`echo mem > /sys/power/state`, `powerButton`) unless
  `lpwdog.sh` is running: on a PW4 a suspend request hangs the Kindle, and without the block it stays frozen until
  someone holds the power button.
- **The dev shell is passwordless root over telnet.**
  - Only allow the user's own computer IP (`DEV_SHELL_ALLOW_IP`).
  - Remind the user to turn it off when finished.
- **Rebooting the device, deleting files on it, or editing `/var/local/appreg.db` changes the user's Kindle.** Say what you
  are about to do before you do it.

## 1. Check the device

- **USB.**
  - Mac: `ls /Volumes/Kindle`.
  - If nothing mounts, check `ioreg -p IOUSB -l -w0 | grep '"idVendor" = 6473'` (Amazon is 0x1949).
  - A charge-only cable or a bad port is the usual cause, so swap the cable.
  - After an eject, the Kindle stays in charge-only mode until it is replugged.
- **Firmware:** `/Volumes/Kindle/system/version.txt`. WinterBreak supports firmware up to 5.18.0.
- **Jailbroken?** Ask the user. On a jailbroken Kindle, `.sh` files in `documents/` with a `# Name:` header show up as
  books (scriptlets).

## 2. Install

1. Copy the payload:
   ```sh
   cp -RX kindle/apps kindle/lpdash kindle/documents kindle/emergency.sh /Volumes/Kindle/
   find /Volumes/Kindle -maxdepth 3 -name '._*' -delete
   ```
   If `/Volumes/Kindle/emergency.sh` already exists and is not ours, merge it instead of overwriting.
2. Create `lpdash/config.sh` from `config.example.sh`.
   - Ask the user for the API key, the wallet, the chain (`ROBINHOOD` or `SOL`), their UTC offset, and optionally their computer's LAN IP for the dev shell.
   - Write the file without echoing the key, then run `chmod 600` on it.
3. Eject with `diskutil eject /Volumes/Kindle`. If the local `kindle/lpdash/` holds a preview `data/` or `log.txt`, it
   was copied too. That is harmless, but you can delete them on the device.
4. The user turns Wi-Fi on and taps **LP Agent Dashboard**. That registers the WAF app, starts the daemon and opens the app about 4 s later.
5. Verify that `lpdash/log.txt` shows `fetch 4/4`.

## 3. Update or debug over Wi-Fi

1. The user taps **LP Agent - Dev shell (on/off)**. It prints `Dev shell ON: <ip>:2323`. With `DEV_SHELL_AT_BOOT=1`
   in `config.sh` it also comes on at every boot (tapping the item then turns it off).
2. If you don't know the IP, find it:
   - A reboot can give the Kindle a new IP (DHCP), and a reboot also turns the dev shell off.
   - Ping-sweep the LAN, then run `arp -an`. Amazon devices have MAC prefixes such as `1c:4d:66`.
3. Run commands with `KINDLE_IP=<ip>`:
   ```sh
   tools/ksh.py 'tail -20 /mnt/us/lpdash/log.txt'
   tools/ksh.py --put <local> <remote>          # prints the remote md5, compare it with `md5 -q <local>`
   tools/kshot.py shot.png                      # framebuffer screenshot (dark images may come out inverted)
   ```
4. Restart the daemon:
   ```sh
   kill $(cat /mnt/us/lpdash/lpdashd.pid)
   nohup sh /mnt/us/lpdash/lpdashd.sh >/dev/null 2>&1 &
   ```
   - Only one daemon may run. Check with `/proc/<pid>/cmdline`, not `ps | grep`, because a forked child still carries the script name.
5. Open the app with `lipc-set-prop com.lab126.appmgrd start app://com.lpagent.dashboard`.
6. Finish by having the user tap the Dev shell item again to turn it off.

## 4. Change the layout (`kindle/apps/xyz.lpagent.dashboard/index.html`)

- **Old WebKit rules:**
  - Write ES5 only: no flexbox/grid, no Promise, no arrow functions.
  - Use tables and absolute positioning.
  - CSS `zoom` works.
- **Data:** it arrives through `<script>` tags that set `window.LPRAW.<name>`, because there is no XHR on `file://`.
  The path is `../../lpdash/data/`, or `demo/` with `?demo=1`.
- **Fonts:** the bundled Inter subset lacks ● ○ ≈. Draw dots with CSS.
- **Screen height:** `innerHeight` reports 1448 first and about 1232 roughly 2 s later, once the system bar is drawn.
  `layout()` re-runs at 1.5, 3.5 and 7 s: it drops "Recently closed" rows, then zooms.
- **System bar:** the top bar cannot be hidden (`kindle.chrome.hide()` and appreg `default-chrome-style` do nothing).
  Set its title with `kindle.messaging.sendMessage('com.lab126.chromebar','configureChrome',...)`.
- **Net worth** = wallet `balanceInUsd` + each position's `currentValue` + `unCollectedFee`. This matches the LP Agent app.
- **Preview:** run `tools/render-test.sh demo`, and `tools/render-test.sh` for real data. Look at both pages for
  overflow before you deploy.

## 5. Troubleshooting

| Symptom | Cause / fix |
|---|---|
| "No data yet" | The daemon is not running or `config.sh` is missing. Check `lpdash/log.txt`. |
| STALE DATA banner | Wi-Fi is off or the API is failing. `log.txt` has the HTTP codes. `429` = rate limit, so keep the 6 s gaps and raise `INTERVAL`. `000` is a network/TLS blip that usually recovers on the next try. |
| Screensaver appears | Something reset `preventScreenSaver` to 0. The daemon's `keepalive` sets it every minute, and when `state` is `screenSaver` it sends `wakeUp 1` (that property only works while the screensaver shows) and `lipc-set-prop com.lab126.blanket unload ad_screensaver` to clear the Special Offers lock screen. |
| Kindle froze (clock on the top bar stopped too) | A whole-device hang caused by a suspend request (reproduced on a PW4), not the daemon. The watchdog chip pauses during low-power modes (WCR `0x773D`: WDZST=1, latched before Linux, write-once), so it can't catch it. `lpwdog.sh` (`WATCHDOG=1`, default) therefore bind-mounts `/var/tmp/lpdash.power_state` over `/sys/power/state` and sets `/sys/power/pm_test` to `freezer`. Check: `grep " /sys/power/state " /proc/mounts` and `blocked a suspend request` lines in `log.txt`. Evidence of the last run: `heartbeat.prev.txt` (has `susp=`/`fail=` counts), `messages.prev.txt`, and the `autostart: boot (reboot reason: ...)` line. |
| Kindle restarted by itself | Run `dmesg \| grep -i "reboot reason"`. `PWRON_LONGPRESS` = the power button was held for about 9 s, not a crash. |
| Dashboard did not come back after a reboot | Check `log.txt` for `autostart:` lines and look for `lpdash/autostart.off` (the boot-loop guard creates it after 3 boots within 15 min). `/etc/upstart/kmc.conf` must exist. |
| App opens then closes, or the Store opens instead | Don't launch through the Store or Mesquito: online, the Store loads Amazon's page. Use the registered WAF app (`register_waf.sql`). The scriptlet re-registers it if it is missing. |
| Two daemons, doubled API calls | Check the pidfile against `/proc/<pid>/cmdline`, kill the extra one. |

**Useful device commands:**
- `lipc-get-prop com.lab126.powerd state`, which returns `active`, `screenSaver` and so on.
- `lipc-probe com.lab126.powerd`
- `lipc-set-prop com.lab126.powerd flIntensity 0` (frontlight off)
- `/mnt/us/libkh/bin/fbink -s -f` (full flashing refresh)
