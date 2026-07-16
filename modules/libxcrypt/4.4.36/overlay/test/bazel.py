from __future__ import annotations

from argparse import ArgumentParser
from pathlib import Path
from subprocess import CalledProcessError, run
from sys import argv

from python.runfiles import Runfiles


class RunfileNotFoundError(FileNotFoundError):
    pass


def runfile(path: Path) -> Path:
    runfiles = Runfiles.Create()
    resolved = Path(runfiles.Rlocation(path))
    if not resolved.exists():
        raise RunfileNotFoundError(path)
    return resolved


def arguments(prsr: ArgumentParser) -> None:
    prsr.add_argument(
        "program",
        metavar="PROG",
        help="The binary to run.",
        type=runfile,
    )
    prsr.add_argument(
        "arguments",
        metavar="ARG",
        nargs="*",
        help="Arguments to pass to the binary.",
    )


def main(exe: Path, *args: str) -> int:
    prsr = ArgumentParser(
        prog=exe.relative_to(Path.cwd()),
        description="Runs a `libxcrypt` binary an skips when `77` exit code is returned.",
        fromfile_prefix_chars="@",
    )

    arguments(prsr)

    parsed = prsr.parse_args(args)

    cmd = (parsed.program, *parsed.arguments)

    try:
        run(cmd, check=True)
    except CalledProcessError as e:
        if e.returncode == 77:
            return 0
        return e.returncode
    except KeyboardInterrupt:
        return 130

    return 0


def entry():
    exit(main(Path(argv[0]), *argv[1:]))


if __name__ == "__main__":
    entry()
