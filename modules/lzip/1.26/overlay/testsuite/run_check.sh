#!/usr/bin/env bash
# Runs lzip's upstream testsuite/check.sh against the Bazel-built binary.
#
# check.sh is written for `make check` (Makefile.in line 51): it is started
# from the object directory, which must hold the `lzip` executable
# (`LZIP="${objdir}"/lzip` with objdir = pwd), it creates a `tmp` directory
# there, and it takes the testsuite directory and the version string as its
# two arguments.  Bazel's runfiles tree is neither writable nor laid out that
# way, so this links the binary into a directory under $TEST_TMPDIR and runs
# the script from there through /bin/sh.
#
# Usage: run_check.sh LZIP CHECK_SH VERSION
# The first two are runfiles-relative paths ($(rlocationpath ...)).

# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
set -uo pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v3 ---

lzip=$(rlocation "$1")
check_sh=$(rlocation "$2")
version=$3

objdir=$TEST_TMPDIR/obj
mkdir -p "$objdir"
ln -s "$lzip" "$objdir/lzip"
cd "$objdir"
exec /bin/sh "$check_sh" "${check_sh%/*}" "$version"
