"""A wrapper for bisonpre that reduces noise in console logs."""

import os
import subprocess
import sys


def main() -> None:
    """The main entrypoint"""

    env = dict(os.environ)
    if "RUNFILES_DIR" in env:
        del env["RUNFILES_DIR"]

    result = subprocess.run(
        [sys.executable] + sys.argv[1:],
        env=env,
        check=False,
        stderr=subprocess.STDOUT,
        stdout=subprocess.PIPE,
        encoding="utf-8",
    )
    # Only log if the process has failed.
    if result.returncode:
        print(result.stdout, file=sys.stderr)
        sys.exit(result.returncode)


if __name__ == "__main__":
    main()
