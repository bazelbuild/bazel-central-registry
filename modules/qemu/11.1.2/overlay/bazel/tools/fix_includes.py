#!/usr/bin/env python3
"""Add the header dependencies a failed `bazel build` log asks for.

usage: fix_includes.py build.log [--dry-run]

For each "<file>: fatal error: <hdr>: No such file or directory", find
<hdr> in the source tree (next to <file>, or from the top), and give the
package of <file> a dependency on the `:headers` library of the package
that owns <hdr> (//include:qemu itself when <file> is under include/).
Uses buildozer; prints what it does.
"""

import os
import re
import subprocess
import sys

EXTERNAL = {"zlib.h": "@zlib"}


def package_of(path):
    d = os.path.dirname(path)
    while d and not os.path.exists(os.path.join(d, "BUILD.bazel")):
        d = os.path.dirname(d)
    return d


def locate(hdr, including):
    for base in (os.path.dirname(including), ""):
        cand = os.path.normpath(os.path.join(base, hdr))
        if os.path.isfile(cand):
            return cand
    return None


def main(log, dry_run=False):
    edits = set()
    unresolved = set()
    for m in re.finditer(r"^(?:\./)?([\w./+-]+):\d+:\d+: fatal error: ([\w./+-]+): No such file",
                         open(log).read(), re.M):
        including, hdr = m.groups()
        if hdr in EXTERNAL:
            dep = EXTERNAL[hdr]
        else:
            found = locate(hdr, including)
            if not found:
                unresolved.add((including, hdr))
                continue
            dep = "//{}:headers".format(package_of(found))
        pkg = package_of(including)
        target = "//include:qemu" if pkg == "include" else "//{}:headers".format(pkg)
        if dep.split(":")[0] == target.split(":")[0]:
            unresolved.add((including, hdr + " (same package)"))
            continue
        edits.add((target, dep))
    for target, dep in sorted(edits):
        print(f"{target} += {dep}")
        if not dry_run:
            subprocess.run(["buildozer", f"add deps {dep}", target], check=False,
                           stdout=subprocess.DEVNULL)
    for u in sorted(unresolved):
        print("unresolved:", *u)


if __name__ == "__main__":
    main(sys.argv[1], "--dry-run" in sys.argv)
