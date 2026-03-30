"""Generic smoke test script for Verilator.

Resolves the verilator binary via runfiles, sets VERILATOR_ROOT, and
executes verilator with all command-line arguments forwarded.
"""

import os
import subprocess
import sys

from python.runfiles import runfiles


def main() -> None:
    r = runfiles.Create()
    verilator_rlocation = os.environ["VERILATOR_RLOCATIONPATH"]
    verilator = r.Rlocation(verilator_rlocation)
    if not verilator or not os.path.exists(verilator):
        print(f"ERROR: could not resolve verilator at {verilator_rlocation!r}", file=sys.stderr)
        sys.exit(1)

    env = dict(os.environ)
    env.update(r.EnvVars())
    env["VERILATOR_ROOT"] = os.path.dirname(os.path.dirname(verilator))

    result = subprocess.run(
        [verilator] + sys.argv[1:],
        env=env,
    )
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
