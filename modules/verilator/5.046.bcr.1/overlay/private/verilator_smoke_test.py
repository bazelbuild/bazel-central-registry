"""Generic smoke test script for Verilator.

Resolves the verilator binary via runfiles, sets VERILATOR_ROOT, and
executes verilator with all command-line arguments forwarded.
"""

import os
import subprocess
import sys

from python.runfiles import runfiles


def _resolve_arg(r, arg):
    """Try to resolve an arg as an rlocation path; return the original if it fails."""
    try:
        resolved = r.Rlocation(arg)
        if resolved and os.path.exists(resolved):
            return resolved
    except (ValueError, TypeError):
        pass
    return arg


def main() -> None:
    r = runfiles.Create()
    verilator_rlocation = os.environ["VERILATOR_RLOCATIONPATH"]
    verilator = r.Rlocation(verilator_rlocation)
    if not verilator or not os.path.exists(verilator):
        print(
            f"ERROR: could not resolve verilator at {verilator_rlocation!r}",
            file=sys.stderr,
        )
        sys.exit(1)

    std_sv_rlocation = os.environ.get("VERILATOR_STD_SV_RLOCATIONPATH")
    if std_sv_rlocation:
        std_sv = r.Rlocation(std_sv_rlocation)
        if std_sv and os.path.exists(std_sv):
            verilator_root = os.path.dirname(os.path.dirname(std_sv))
        else:
            verilator_root = os.path.dirname(verilator)
    else:
        verilator_root = os.path.dirname(verilator)

    env = dict(os.environ)
    env.update(r.EnvVars())
    env["VERILATOR_ROOT"] = verilator_root

    args = [_resolve_arg(r, a) for a in sys.argv[1:]]
    result = subprocess.run(
        [verilator] + args,
        env=env,
    )
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
