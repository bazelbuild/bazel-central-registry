"""Bazel test runner for Yosys .ys script tests.

Expected environment variables (set via Bazel env/rlocationpath):
  YOSYS      - rlocation path to the yosys binary
  YS_SCRIPT  - rlocation path to the .ys script to run
"""

import os
import subprocess
import sys

from python.runfiles import runfiles


def main() -> None:
    r = runfiles.Create()

    yosys_bin = r.Rlocation(os.environ["YOSYS"])
    script_path = r.Rlocation(os.environ["YS_SCRIPT"])

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
