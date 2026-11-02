# LP Agent dashboard config. Copy to /mnt/us/lpdash/config.sh on the Kindle and fill it in.
# This file holds your API key in plain text: anyone who plugs the Kindle into a computer can read it.
# Use an Open API key you can revoke (see https://docs.lpagent.io).

LPA_KEY="your-lp-agent-open-api-key"
LPA_OWNER="0xYourWalletAddress"   # wallet to show (EVM 0x... for ROBINHOOD, base58 for SOL)
LPA_CHAIN="ROBINHOOD"             # ROBINHOOD (shown in USD) or SOL (shown in SOL)

INTERVAL=300       # seconds between refreshes (the API is rate limited, keep >= 120)
FLASH_EVERY=12     # full flashing refresh every N refreshes to clear e-ink ghosting (12 x 5 min = 1 h)
TZ_OFFSET_MIN=0    # your UTC offset in minutes for the clock on screen, e.g. 420 = UTC+7, -300 = UTC-5
FRONTLIGHT=0       # frontlight level set when the daemon starts (0 = off, empty = leave it alone)

# Optional: LAN IP of YOUR computer, allowed to use the "LP Agent - Dev shell" scriptlet
# (passwordless root telnet on port 2323). Leave empty to keep the dev shell disabled.
DEV_SHELL_ALLOW_IP=""
