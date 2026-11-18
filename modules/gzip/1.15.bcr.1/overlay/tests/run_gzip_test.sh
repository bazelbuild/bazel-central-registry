#!/usr/bin/env bash
# Runs one script from GNU gzip's upstream `tests/` suite.
#
# The suite is written against `make check`: each script does
# `. "${srcdir=.}/init.sh"; path_prepend_ ..`, so it expects to run from a
# writable `<builddir>/tests` with `gzip` and the wrapper scripts (gunzip,
# zcat, zgrep, ...) one level up, plus the variables tests/Makefile.am's
# TESTS_ENVIRONMENT exports.  Bazel hands us a read-only runfiles tree
# instead, so this assembles that layout out of symlinks under $TEST_TMPDIR,
# points $srcdir at the runfiles copy of `tests/` (the VPATH form automake
# also supports; init.sh keeps an absolute $srcdir as is) and runs the script
# through /bin/sh.
#
# Usage: run_gzip_test.sh TEST_NAME INIT_SH CONFIG_H PROGRAM...
# All but the first are runfiles-relative paths ($(rlocationpath ...)).
# INIT_SH locates `tests/`; every PROGRAM (gzip and the wrapper scripts) is
# staged under its own file name at the top of the tree.  They are listed
# one by one because in a sandbox the runfiles tree holds exactly the
# declared files, and a program missing from it would quietly be picked up
# from the host's PATH instead.

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

test_name=$1
init_sh=$(rlocation "$2")
config_h=$(rlocation "$3")
shift 3

stage=$TEST_TMPDIR/tree
mkdir -p "$stage/tests"

# Makefile.am's bin_PROGRAMS and bin_SCRIPTS at the top of the build tree,
# and tests/Makefile.am's `built_programs` in the same order.  zless and
# zmore count only when their pager is installed -- configure's
# AC_CHECK_PROG([LESS]) / ([MORE]) -- because `help-version` runs every
# program on real input, which would exec it.
built_programs=
for program in "$@"; do
  path=$(rlocation "$program")
  name=${path##*/}
  ln -s "$path" "$stage/$name"
  case $name in
    zless) command -v less > /dev/null 2>&1 || continue ;;
    zmore) command -v more > /dev/null 2>&1 || continue ;;
  esac
  built_programs="$built_programs${built_programs:+ }$name"
done

# tests/Makefile.am TESTS_ENVIRONMENT, restricted to the variables init.sh
# or some script reads.  VERSION is what `help-version` checks
# `gzip --version` against, so it comes from the header gzip was built with.
VERSION=$(sed -n 's/^#define VERSION "\(.*\)"$/\1/p' "$config_h")
srcdir=${init_sh%/*}
# Only tests/pipe-output reads this, and only to skip a case on Cygwin.
host_os=$(uname -s | tr '[:upper:]' '[:lower:]')
export LC_ALL=C
export VERSION
export abs_top_builddir=$stage
export abs_srcdir=$srcdir
export srcdir
export built_programs
export GREP=grep
export PERL=perl
export SHELL=/bin/sh
export host_os
# tests/Makefile.am line 128: init.sh traces the script (`set -x`) so the log
# shows what ran.
export VERBOSE=yes
export TMPDIR=$stage
export PATH=$stage:$PATH

cd "$stage/tests"
# tests/init.cfg sets stderr_fileno_=9 to match the `9>&2` that
# TESTS_ENVIRONMENT ends with; without it every skip_/fail_ diagnostic dies
# on a bad file descriptor.
exec 9>&2
set +e
"$SHELL" "$srcdir/$test_name"
status=$?

# Upstream uses exit 77 for "not applicable on this machine" (no perl, no
# room for a 4 GiB sparse file, running as root, ...).  Bazel has no
# runtime-skip status, so report it loudly and pass.
if [ "$status" -eq 77 ]; then
  echo "SKIPPED: $test_name requested a skip (exit 77); see the log above."
  exit 0
fi
exit "$status"
