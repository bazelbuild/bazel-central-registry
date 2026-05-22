# Wrapper script for generating ICU test data in Bazel.
#
# This script orchestrates the first part of the ICU test data pipeline:
# 1. databuilder - generates .res files from source test data
# 2. pkgdata     - packages .res files into a .dat archive
#
# Additionally, this script handles:
# - Copying the main ICU data file for genrb collation compilation.
# - Copying standalone test files (zoneinfo64.res, nam.typ).

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
    """Run the databuilder to generate .res files."""
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
    """Run pkgdata to package .res files into .dat."""
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
    """Create a package list file from the .res directory."""
    exclude_dirs = exclude_dirs or []
    files: list[str] = []
    for root, _, filenames in os.walk(res_dir):
        rel_root = os.path.relpath(root, res_dir)
        if any(rel_root.startswith(d) for d in exclude_dirs):
            continue
        for f in filenames:
            rel_path = os.path.relpath(os.path.join(root, f), res_dir)
            files.append(rel_path)

    files.sort()
    with open(lst_file, "w") as f:
        for file in files:
            f.write(file + "\n")

    logging.debug("Created package list with %d files: %s", len(files), lst_file)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate ICU test data for Bazel")
    parser.add_argument("--src_dir", required=True, help="Source data directory containing BUILDRULES.py")
    parser.add_argument("--tool_dir", required=True, help="Directory containing ICU tools (pkgdata, genccode, etc.)")
    parser.add_argument("--out_dir", required=True, help="Output directory for generated files")
    parser.add_argument("--pkg_name", required=True, help="Package name (e.g., testdata)")
    parser.add_argument(
        "--icu_data_dir",
        required=True,
        help="Directory containing the main ICU data file (icudt76l.dat) " "for genrb collation compilation",
    )
    parser.add_argument("--verbose", "-v", action="store_true", help="Enable verbose output")
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.WARNING,
        format="%(message)s",
    )

    src_dir = os.path.normpath(args.src_dir)
    tool_dir = os.path.normpath(args.tool_dir)
    out_dir = os.path.normpath(args.out_dir)
    icu_data_dir = os.path.normpath(args.icu_data_dir)
    icu_data_file = os.path.join(icu_data_dir, "icudt76l.dat")

    # `ignore_cleanup_errors=True` is needed on Windows: ICU tools mmap data
    # files and Windows keeps handles live for a beat after the child exits,
    # so the recursive `os.unlink` cleanup races with the OS and raises
    # PermissionError. Swallow cleanup errors so the actual build status
    # isn't masked by a stray traceback. See //icu4c/source/data/generator.py.
    with tempfile.TemporaryDirectory(ignore_cleanup_errors=True) as tmp_base:
        work_out_dir = os.path.join(tmp_base, "out", args.pkg_name)
        work_tmp_dir = os.path.join(tmp_base, "tmp")
        os.makedirs(work_out_dir)
        os.makedirs(work_tmp_dir)

        # Copy the main ICU data file into the output tree so that genrb can
        # find it when compiling collation tailoring rules. The databuilder
        # sets ICU_DATA to the output directory, so placing the .dat file in
        # a sub-directory keeps it out of the .lst (excluded below).
        build_dir = os.path.join(work_out_dir, "build")
        os.makedirs(build_dir)
        shutil.copy(icu_data_file, build_dir)
        logging.debug("Copied ICU data file to build dir: %s -> %s", icu_data_file, build_dir)

        # Step 1: Run databuilder (.txt → .res)
        run_databuilder(src_dir, work_out_dir, work_tmp_dir, tool_dir)

        # Step 2: Create package list (exclude build directory)
        lst_file = os.path.join(work_tmp_dir, f"{args.pkg_name}.lst")
        create_package_list(work_out_dir, lst_file, exclude_dirs=["build"])

        # Step 3: Run pkgdata (.res → .dat)
        pkgdata_bin = tool_executable(tool_dir, "pkgdata")
        run_pkgdata(pkgdata_bin, work_out_dir, lst_file, args.pkg_name, work_tmp_dir)

        # Step 4: Copy .dat to the declared output location (out/testdata.dat).
        # The .dat → linkable source (.S / .c) step lives in separate run_binary
        # targets in BUILD.bazel — see file header.
        dat_file = os.path.join(work_tmp_dir, f"{args.pkg_name}.dat")
        dat_out_dir = os.path.join(out_dir, "out")
        os.makedirs(dat_out_dir, exist_ok=True)
        shutil.copy(dat_file, os.path.join(dat_out_dir, f"{args.pkg_name}.dat"))
        logging.debug("Copied .dat file to: %s", dat_out_dir)

        # Step 5: Copy standalone test files that tests expect outside the
        # .dat package (TmpFile outputs from the databuilder).
        standalone_files = [
            ("zoneinfo64.res", f"out/{args.pkg_name}/zoneinfo64.res"),
            ("nam.typ", f"out/{args.pkg_name}/nam.typ"),
        ]

        for src_name, dst_rel_path in standalone_files:
            src_path = os.path.join(work_tmp_dir, src_name)
            if os.path.exists(src_path):
                dst_path = os.path.join(out_dir, dst_rel_path)
                os.makedirs(os.path.dirname(dst_path), exist_ok=True)
                shutil.copy(src_path, dst_path)
                logging.debug("Copied standalone file: %s -> %s", src_path, dst_path)
            else:
                logging.warning("Standalone file not found: %s", src_path)

    logging.debug("Test data generation complete.")


if __name__ == "__main__":
    main()
