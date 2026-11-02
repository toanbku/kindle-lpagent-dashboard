#!/usr/bin/env python3
"""Run shell commands on the Kindle through the dev shell (busybox telnetd, port 2323).

  ksh.py 'command'            run a command, print its output
  ksh.py --put local remote   copy a small file over (base64 + openssl on the Kindle)
Env: KINDLE_IP (required, the Kindle's LAN IP), KSH_TIMEOUT (seconds, default 30)
Start the shell first with the "LP Agent - Dev shell (on/off)" scriptlet on the Kindle.
"""
import base64
import os
import socket
import sys
import time

HOST = os.environ.get("KINDLE_IP") or sys.exit("set KINDLE_IP to the Kindle's LAN IP")
PORT = 2323
TIMEOUT = float(os.environ.get("KSH_TIMEOUT", "30"))
IAC, DONT, DO, WONT, WILL, SB, SE = 255, 254, 253, 252, 251, 250, 240


def clean(sock, data):
    """Strip telnet negotiation bytes and refuse every option."""
    out, i = bytearray(), 0
    while i < len(data):
        b = data[i]
        if b == IAC and i + 1 < len(data):
            c = data[i + 1]
            if c in (DO, DONT, WILL, WONT) and i + 2 < len(data):
                opt = data[i + 2]
                if c == DO:
                    sock.sendall(bytes([IAC, WONT, opt]))
                elif c == WILL:
                    sock.sendall(bytes([IAC, DONT, opt]))
                i += 3
                continue
            if c == SB:
                j = data.find(bytes([IAC, SE]), i)
                i = j + 2 if j >= 0 else len(data)
                continue
            i += 2
            continue
        out.append(b)
        i += 1
    return bytes(out)


def run(cmd):
    s = socket.create_connection((HOST, PORT), timeout=10)
    s.settimeout(1.0)
    try:  # swallow the greeting + negotiation
        clean(s, s.recv(4096))
    except socket.timeout:
        pass
    start, end = "__KSH_START__", "__KSH_END__"
    # markers are split with "" so the echoed input never matches the printed marker
    script = f"stty -echo 2>/dev/null; PS1=''; echo __KSH_\"\"START__\n{cmd}\necho __KSH_\"\"END__ $?\nexit\n"
    s.sendall(script.encode())
    buf, deadline = b"", time.time() + TIMEOUT
    while time.time() < deadline:
        try:
            d = s.recv(65536)
        except socket.timeout:
            if end.encode() in buf:
                break
            continue
        if not d:
            break
        buf += clean(s, d)
        if end.encode() in buf and b"\n" in buf.split(end.encode())[-1]:
            break
    s.close()
    text = buf.decode("utf-8", "replace").replace("\r\n", "\n").replace("\r", "")
    if start in text:
        text = text.split(start, 1)[1].lstrip("\n")
    code = None
    if end in text:
        body, tail = text.rsplit(end, 1)
        code = tail.strip().split()[0] if tail.strip() else None
        text = body
    sys.stdout.write(text)
    if code not in (None, "0"):
        sys.stdout.write(f"[exit {code}]\n")


def put(local, remote):
    data = base64.encodebytes(open(local, "rb").read()).decode()
    tmp = remote + ".b64tmp"
    cmd = f"cat > '{tmp}' <<'__B64__'\n{data}__B64__\nopenssl enc -base64 -d -in '{tmp}' -out '{remote}' && rm -f '{tmp}' && ls -la '{remote}' && md5sum '{remote}'"
    run(cmd)


if __name__ == "__main__":
    if len(sys.argv) >= 4 and sys.argv[1] == "--put":
        put(sys.argv[2], sys.argv[3])
    else:
        run(sys.argv[1] if len(sys.argv) > 1 else sys.stdin.read())
