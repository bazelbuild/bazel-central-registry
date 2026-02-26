"""Bazel test runner for Yosys .ys script tests.

Expected environment variables (set via Bazel env/rlocationpath):
  YOSYS      - rlocation path to the yosys binary
  YS_SCRIPT  - rlocation path to the .ys script to run

Bazel sets TEST_SRCDIR to the root of the runfiles tree, so
combining TEST_SRCDIR with an rlocation path gives the real file path.
"""

import os
import subprocess
import sys


def main():
    test_srcdir = os.environ.get("TEST_SRCDIR", "")

    yosys_bin = os.path.join(test_srcdir, os.environ["YOSYS"])
    script_path = os.path.join(test_srcdir, os.environ["YS_SCRIPT"])

    script_dir = os.path.dirname(script_path)
    script_file = os.path.basename(script_path)

    # Run yosys from the script's directory so that relative
    # read_verilog / read_rtlil paths inside the script resolve correctly.
    result = subprocess.run(
        [yosys_bin, "-ql", "/dev/null", script_file],
        cwd=script_dir,
    )
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
