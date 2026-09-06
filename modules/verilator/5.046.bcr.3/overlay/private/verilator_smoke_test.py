"""Generic smoke test script for Verilator.

Resolves the verilator binary via runfiles, sets VERILATOR_ROOT, and
executes verilator with all command-line arguments forwarded.
"""

import os
import platform
import subprocess
import sys
from pathlib import Path

from python.runfiles import Runfiles


def _rlocation(runfiles: Runfiles, rlocationpath: str) -> Path:
    """Look up a runfile and ensure the file exists

    Args:
        runfiles: The runfiles object
        rlocationpath: The runfile key

    Returns:
        The requested runifle.
    """
    # TODO: https://github.com/periareon/rules_venv/issues/37
    source_repo = None
    if platform.system() == "Windows":
        source_repo = ""
    runfile = runfiles.Rlocation(rlocationpath, source_repo)
    if not runfile:
        raise FileNotFoundError(f"Failed to find runfile: {rlocationpath}")
    path = Path(runfile)
    if not path.exists():
        raise FileNotFoundError(f"Runfile does not exist: ({rlocationpath}) {path}")
    return path


def _resolve_arg(r: Runfiles, arg: str) -> str:
    """Try to resolve an arg as an rlocation path; return the original if it fails."""
    try:
        resolved = _rlocation(r, arg)
        return str(resolved)
    except (ValueError, TypeError, FileNotFoundError):
        pass
    return arg


def main() -> None:
    r = Runfiles.Create()
    verilator_rlocation = os.environ["VERILATOR_RLOCATIONPATH"]
    verilator = _rlocation(r, verilator_rlocation)

    std_sv_rlocation = os.environ.get("VERILATOR_STD_SV_RLOCATIONPATH")
    if std_sv_rlocation:
        std_sv = _rlocation(r, std_sv_rlocation)
        verilator_root = os.path.dirname(os.path.dirname(std_sv))
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
