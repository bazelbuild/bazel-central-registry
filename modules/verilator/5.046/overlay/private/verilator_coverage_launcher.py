"""Cross-platform wrapper

locates the upstream Perl entrypoint and the
Bazel-built binary within runfiles, then invokes them via subprocess.
Uses Python instead of bash for Windows compatibility.
"""

import os
import subprocess
import sys
from typing import Optional


def _find_runfiles() -> Optional[str]:
    for v in ("RUNFILES_DIR", "TEST_SRCDIR"):
        d = os.environ.get(v)
        if d and os.path.isdir(d):
            return d
    for suffix in (".runfiles", os.sep + ".runfiles"):
        c = os.path.abspath(sys.argv[0]) + suffix
        if os.path.isdir(c):
            return c
    return None


def main() -> None:
    rf = _find_runfiles()
    if rf is None:
        print("verilator_coverage launcher: cannot find runfiles", file=sys.stderr)
        sys.exit(1)
    repo = "_main"
    env = dict(os.environ)
    env["VERILATOR_COVERAGE_BIN"] = os.path.join(
        rf, repo, "bin", "verilator_coverage_bin_dbg"
    )
    script = os.path.join(rf, repo, "bin", "verilator_coverage")
    sys.exit(subprocess.run(["perl", script] + sys.argv[1:], env=env).returncode)
