"""Cross-platform wrapper

locates the upstream Perl entrypoint and the
Bazel-built binary within runfiles, then invokes them via subprocess.
Uses Python instead of bash for Windows compatibility.
"""

import os
import subprocess
import sys
from pathlib import Path
from typing import List

from python.runfiles import Runfiles


def _rlocation(runfiles: Runfiles, rlocationpaths: List[str]) -> Path:
    """Look up a runfile and ensure the file exists

    Args:
        runfiles: The runfiles object
        rlocationpaths: A list of potential runfiles keys

    Returns:
        The requested runifle.
    """
    source_repo = None
    if sys.platform == "win32":
        source_repo = ""

    for rlocationpath in rlocationpaths:
        rf = runfiles.Rlocation(rlocationpath, source_repo)
        if not rf:
            continue

        path = Path(rf)
        if path.exists():
            return path

    raise FileNotFoundError(f"Failed to find runfile from options: {rlocationpaths}")


_VERILATOR_COVERAGE_BIN_PATHS = [
    "verilator/verilator_coverage_bin_dbg",
    "_main/verilator_coverage_bin_dbg",
]

_SCRIPT_PATHS = [
    "verilator/verilator_coverage",
    "_main/verilator_coverage",
]


def main() -> None:
    """The main entrypoint."""
    runfiles = Runfiles.Create()
    if not runfiles:
        raise EnvironmentError("Failed to find runfiles.")

    coverage_bin = _rlocation(runfiles, _VERILATOR_COVERAGE_BIN_PATHS)
    script = _rlocation(runfiles, _SCRIPT_PATHS)

    env = dict(os.environ)
    env["VERILATOR_COVERAGE_BIN"] = str(coverage_bin)
    result = subprocess.run(["perl", script] + sys.argv[1:], env=env)

    sys.exit(result.returncode)
