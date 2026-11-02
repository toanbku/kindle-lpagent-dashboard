#!/usr/bin/env python3
"""Screenshot the Kindle through the dev shell: reads /dev/fb0 (gzip+base64) -> grayscale PNG.
  KINDLE_IP=192.168.x.y kshot.py out.png
Env: KW/KH screen size (default 1072x1448, Paperwhite 4).
"""
import base64
import gzip
import os
import struct
import subprocess
import sys
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
out = sys.argv[1] if len(sys.argv) > 1 else "kindle.png"
cmd = ("cat /sys/class/graphics/fb0/virtual_size /sys/class/graphics/fb0/stride "
       "/sys/class/graphics/fb0/bits_per_pixel; echo __FB__; "
       "gzip -c /dev/fb0 | openssl enc -base64 2>/dev/null; echo __FBEND__")
env = dict(os.environ, KSH_TIMEOUT=os.environ.get("KSH_TIMEOUT", "90"))
txt = subprocess.run([sys.executable, "-I", os.path.join(HERE, "ksh.py"), cmd],
                     capture_output=True, text=True, env=env).stdout
head, rest = txt.split("__FB__", 1)
b64 = rest.split("__FBEND__", 1)[0]
lines = [l.strip() for l in head.strip().splitlines() if l.strip()]
vw, vh = [int(x) for x in lines[-3].split(",")]
stride, bpp = int(lines[-2]), int(lines[-1])
raw = gzip.decompress(base64.b64decode("".join(b64.split())))
if bpp != 8:
    sys.exit(f"bpp={bpp} not supported")
# virtual_size is the whole multi-page buffer (1088x6144); the visible part is the top-left screen-sized area
vw = int(os.environ.get("KW", "1072")); vh = int(os.environ.get("KH", "1448"))
h = min(vh, len(raw) // stride)
rows = [raw[y * stride: y * stride + vw] for y in range(h)]
# 8bpp heuristic: if the top rows are mostly 0 the buffer is probably inverted -> flip it back
# (dark full-screen images such as the screensaver can come out inverted)
flat = b"".join(rows[: min(50, h)])
if flat.count(0) > flat.count(255):
    rows = [bytes(255 - b for b in r) for r in rows]

def png(w, hh, rws):
    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)
    data = b"".join(b"\x00" + r for r in rws)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, hh, 8, 0, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(data, 9)) + chunk(b"IEND", b""))

open(out, "wb").write(png(vw, h, rows))
print(f"{out}  {vw}x{h} stride={stride} bpp={bpp}")
