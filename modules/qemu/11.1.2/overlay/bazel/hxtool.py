"""The header-generation mode of QEMU's scripts/hxtool, with no shell."""

import sys


def header(lines):
    in_rst = False
    seen_name = False
    for raw in lines:
        line = raw.rstrip("\n").strip(" \t")
        if line.startswith("HXCOMM"):
            continue
        if line.startswith("SRST"):
            if in_rst:
                raise ValueError("nested SRST")
            in_rst = True
            seen_name = False
        elif line.startswith("ERST"):
            if not in_rst:
                raise ValueError("ERST outside SRST")
            in_rst = False
        else:
            if line.startswith(".name"):
                if seen_name:
                    raise ValueError("another .name without intervening documentation")
                seen_name = True
            if not in_rst:
                yield line
    if in_rst:
        raise ValueError("unterminated SRST")


if __name__ == "__main__":
    with open(sys.argv[1], encoding="utf-8") as source:
        for line in header(source):
            print(line)
