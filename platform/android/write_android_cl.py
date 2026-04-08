#!/usr/bin/env python3
from pathlib import Path
import struct
import sys


def main() -> None:
    args = [b"--main-pack", b"res://data.pck"]
    out = bytearray()
    out += struct.pack("<I", len(args))
    for arg in args:
        out += struct.pack("<I", len(arg))
        out += arg

    root = Path(__file__).resolve().parents[2]
    target = root / "build" / "android_source" / "assets" / "_cl_"
    if len(sys.argv) > 1:
        target = Path(sys.argv[1]).resolve()
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(out)
    print(target)


if __name__ == "__main__":
    main()
