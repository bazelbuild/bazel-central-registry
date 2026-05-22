# Wrapper script for generating the main ICU data bundle in Bazel.
#
# This script orchestrates the ICU main data generation pipeline:
#   1. databuilder  — .txt/.ucm/… → .res files
#   2. pkgdata      — .res files   → icudt76l.dat archive
#
# The tool binaries are compiled against stub ICU data (via the bootstrap
# transition in defs.bzl), so no real .dat file is required as
# input — the circular dependency is broken at the compilation level.

from __future__ import annotations

import argparse
import logging
import os
import platform
import shutil
import subprocess
import sys
import tempfile

from icutools.databuilder import __main__ as databuilder_main

# Tool-cfg sub-directory name used by 'windows-exec' mode on Windows. It must
# match the Windows replace_prefixes layout in '//icu4c/source/tools/BUILD.bazel'.
# On Linux/macOS the tooldir is flat and this is unused.
WINDOWS_TOOL_CFG = "bin"


def tool_executable(tool_dir: str, tool_name: str) -> str:
    """Resolve the on-disk path of a tool in the Bazel-built tooldir."""
    if platform.system() == "Windows":
        return os.path.join(tool_dir, tool_name, WINDOWS_TOOL_CFG, f"{tool_name}.exe")
    return os.path.join(tool_dir, tool_name)


def run_databuilder(
    src_dir: str,
    out_dir: str,
    tmp_dir: str,
    tool_dir: str,
) -> None:
    """Run the ICU databuilder to compile source data into .res files."""
    argv = [
        "--mode",
        "windows-exec" if platform.system() == "Windows" else "unix-exec",
        "--src_dir",
        src_dir,
        "--out_dir",
        out_dir,
        "--tmp_dir",
        tmp_dir,
        "--tool_dir",
        tool_dir,
        "--seqmode",
        "parallel",
        # Always pass --verbose: in quiet mode the databuilder redirects each
        # tool's stderr to devnull, so we'd lose genrb/gencnval failures in
        # CI logs. The verbose output is a few extra lines per tool, not a
        # firehose.
        "--verbose",
    ]

    if platform.system() == "Windows":
        argv += ["--tool_cfg", WINDOWS_TOOL_CFG]

    logging.debug("Running databuilder with args: %s", " ".join(argv))
    databuilder_main.main(argv)


def run_pkgdata(
    pkgdata_bin: str,
    res_dir: str,
    lst_file: str,
    pkg_name: str,
    out_dir: str,
) -> None:
    """Run pkgdata to package .res files into a .dat archive."""
    cmd = [
        pkgdata_bin,
        "-m",
        "common",
        "-p",
        pkg_name,
        "-c",
        "-s",
        res_dir,
        "-d",
        out_dir,
        lst_file,
    ]
    if logging.getLogger().isEnabledFor(logging.DEBUG):
        cmd.insert(1, "-v")
    logging.debug("Running: %s", " ".join(cmd))
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.stdout:
        logging.debug("%s", result.stdout)
    if result.stderr:
        logging.debug("%s", result.stderr)
    if result.returncode != 0:
        sys.exit(result.returncode)


def create_package_list(
    res_dir: str,
    lst_file: str,
    exclude_dirs: list[str] | None = None,
) -> None:
    """Walk res_dir and write a sorted manifest of all files to lst_file."""
    exclude_dirs = exclude_dirs or []
    files: list[str] = []
    for root, _, filenames in os.walk(res_dir):
        rel_root = os.path.relpath(root, res_dir)
        if any(rel_root == d or rel_root.startswith(d + os.sep) for d in exclude_dirs):
            continue
        for f in filenames:
            rel_path = os.path.relpath(os.path.join(root, f), res_dir)
            files.append(rel_path)

    files.sort()
    with open(lst_file, "w") as fh:
        for f in files:
            fh.write(f + "\n")

    logging.debug("Created package list with %d files: %s", len(files), lst_file)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate the main ICU data bundle for Bazel (bootstrap mode).",
    )
    parser.add_argument("--src_dir", required=True, help="Source data directory (icu4c/source/data)")
    parser.add_argument("--tool_dir", required=True, help="Directory containing bootstrap-compiled ICU tools")
    parser.add_argument("--out_dir", required=True, help="Output directory for generated files")
    parser.add_argument("--pkg_name", required=True, help="ICU data package name (e.g. icudt76l)")
    parser.add_argument("--verbose", "-v", action="store_true", help="Enable verbose output")
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.WARNING,
        format="%(message)s",
    )

    src_dir = os.path.normpath(args.src_dir)
    tool_dir = os.path.normpath(args.tool_dir)
    out_dir = os.path.normpath(args.out_dir)

    # `ignore_cleanup_errors=True` is needed on Windows: ICU tools mmap data
    # files (cnvalias.icu, icudt<v>l.dat) and Windows keeps handles live for
    # a beat after the child exits, so `os.unlink` during the cleanup walk
    # races with the OS and raises PermissionError. Swallowing the cleanup
    # errors keeps the actual build-failure (or success) status visible
    # instead of being masked by a stray cleanup traceback.
    with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp_base:
        work_out_dir = os.path.join(tmp_base, "out", args.pkg_name)
        work_tmp_dir = os.path.join(tmp_base, "tmp")
        os.makedirs(work_out_dir)
        os.makedirs(work_tmp_dir)

        # Step 1: Run databuilder (.txt/.ucm/… → .res)
        run_databuilder(src_dir, work_out_dir, work_tmp_dir, tool_dir)

        # Step 2: Create package manifest
        lst_file = os.path.join(work_tmp_dir, f"{args.pkg_name}.lst")
        create_package_list(work_out_dir, lst_file)

        # Step 3: Run pkgdata (.res → .dat)
        pkgdata_bin = tool_executable(tool_dir, "pkgdata")
        run_pkgdata(pkgdata_bin, work_out_dir, lst_file, args.pkg_name, work_tmp_dir)

        # Step 4: Copy .dat to the declared output location
        dat_file = os.path.join(work_tmp_dir, f"{args.pkg_name}.dat")
        os.makedirs(out_dir, exist_ok=True)
        shutil.copy(dat_file, os.path.join(out_dir, f"{args.pkg_name}.dat"))
        logging.debug("Copied .dat to: %s", out_dir)

    logging.debug("ICU data generation complete.")


if __name__ == "__main__":
    main()
