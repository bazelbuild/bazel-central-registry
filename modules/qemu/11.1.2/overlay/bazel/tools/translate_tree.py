#!/usr/bin/env python3
"""Write first-pass BUILD.bazel files for a set of directories.

usage: translate_tree.py DIR...

Each DIR and every ancestor directory with a meson.build gets a BUILD.bazel
from meson2bazel.py unless it already has one that is not a placeholder;
a directory one of them lists in qemu_package(subdirs) but that is not
translated gets a placeholder providing the per-target aggregate.
"""

import os
import re
import subprocess
import sys

PLACEHOLDER = "# Placeholder until this directory is built with Bazel"
HERE = os.path.dirname(os.path.abspath(__file__))


def is_placeholder(path):
    return not os.path.exists(path) or open(path).read().startswith(PLACEHOLDER)


def placeholder(d):
    lines = [PLACEHOLDER + "."]
    load = 'load("//bazel:qemu.bzl", "qemu_package")'
    body = []
    if os.path.exists(os.path.join(d, "trace-events")):
        body.append('exports_files(["trace-events"])')
    body.append("qemu_package()")
    return "\n".join([lines[0], load, ""] + body) + "\n"


def main(dirs):
    todo = set()
    for d in dirs:
        while d and d != ".":
            if os.path.exists(os.path.join(d, "meson.build")):
                todo.add(d)
            d = os.path.dirname(d)
    written = []
    for d in sorted(todo):
        p = os.path.join(d, "BUILD.bazel")
        if not is_placeholder(p):
            continue
        out = subprocess.run([sys.executable, os.path.join(HERE, "meson2bazel.py"), d],
                             capture_output=True, text=True, check=True).stdout
        open(p, "w").write(out)
        written.append(d)
    # subdirs referenced by any BUILD file that have no BUILD of their own
    for d in written:
        text = open(os.path.join(d, "BUILD.bazel")).read()
        m = re.search(r"qemu_package\(subdirs = (\[.*?\])\)", text, re.S)
        if not m:
            continue
        for sub in eval(m.group(1)):
            sd = os.path.join(d, sub)
            p = os.path.join(sd, "BUILD.bazel")
            if is_placeholder(p) and os.path.isdir(sd):
                open(p, "w").write(placeholder(sd))
    print("\n".join(written))


if __name__ == "__main__":
    main(sys.argv[1:])
