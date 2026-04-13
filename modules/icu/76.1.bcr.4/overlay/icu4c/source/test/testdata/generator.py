# Wrapper script for generating ICU test data in Bazel.
#
# This script orchestrates the ICU test data generation pipeline:
# 1. databuilder - generates .res files from source test data
# 2. pkgdata - packages .res files into a .dat archive
# 3. genccode - converts .dat to assembly for static linking
#
# Additionally, it handles:
# - Copying the main ICU data file for genrb collation compilation
# - Copying standalone test files (zoneinfo64.res, nam.typ)

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


def run_databuilder(
    src_dir: str,
    out_dir: str,
    tmp_dir: str,
    tool_dir: str,
) -> None:
    """Run the databuilder to generate .res files."""
    argv = [
        "--mode", "windows-exec" if platform.system() == "Windows" else "unix-exec",
        "--src_dir", src_dir,
        "--out_dir", out_dir,
        "--tmp_dir", tmp_dir,
        "--tool_dir", tool_dir,
        "--seqmode", "parallel",
    ]
    if logging.getLogger().isEnabledFor(logging.DEBUG):
        argv.append("--verbose")
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
        "-m", "common",
        "-p", pkg_name,
        "-c",
        "-s", res_dir,
        "-d", out_dir,
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


def run_genccode(
    genccode_bin: str,
    dat_file: str,
    entry_name: str,
    out_dir: str,
) -> None:
    """Run genccode to convert .dat to assembly."""
    cmd = [
        genccode_bin,
        "--assembly", "gcc",
        "--name", entry_name,
        "--entrypoint", entry_name,
        "--destdir", out_dir,
        dat_file,
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
    parser.add_argument("--src_dir", required=True,
                        help="Source data directory containing BUILDRULES.py")
    parser.add_argument("--tool_dir", required=True,
                        help="Directory containing ICU tools (pkgdata, genccode, etc.)")
    parser.add_argument("--out_dir", required=True,
                        help="Output directory for generated files")
    parser.add_argument("--pkg_name", required=True,
                        help="Package name (e.g., testdata)")
    parser.add_argument("--entry_name", required=True,
                        help="Entry point name for assembly (e.g., testdata)")
    parser.add_argument("--icu_data_dir", required=True,
                        help="Directory containing the main ICU data file (icudt76l.dat) "
                             "for genrb collation compilation")
    parser.add_argument("--verbose", "-v", action="store_true",
                        help="Enable verbose output")
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

    with tempfile.TemporaryDirectory() as tmp_base:
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
        pkgdata_bin = os.path.join(tool_dir, "pkgdata")
        run_pkgdata(pkgdata_bin, work_out_dir, lst_file, args.pkg_name, work_tmp_dir)

        # Step 4: Run genccode (.dat → .S)
        dat_file = os.path.join(work_tmp_dir, f"{args.pkg_name}.dat")
        genccode_bin = os.path.join(tool_dir, "genccode")
        os.makedirs(out_dir, exist_ok=True)
        run_genccode(genccode_bin, dat_file, args.entry_name, out_dir)

        # Step 5: Copy .dat to the declared output location (out/testdata.dat)
        dat_out_dir = os.path.join(out_dir, "out")
        os.makedirs(dat_out_dir, exist_ok=True)
        shutil.copy(dat_file, os.path.join(dat_out_dir, f"{args.pkg_name}.dat"))
        logging.debug("Copied .dat file to: %s", dat_out_dir)

        # Step 6: Copy standalone test files that tests expect outside the
        # .dat package (TmpFile outputs from the databuilder).
        standalone_files = [
            ("zoneinfo64.res", f"out/{args.pkg_name}/zoneinfo64.res"),
            ("nam.typ",        f"out/{args.pkg_name}/nam.typ"),
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
