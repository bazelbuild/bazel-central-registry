#!/usr/bin/env bash
# Runs upstream's Autotest suite against the binaries this module builds.
#
# `tests/testsuite` is autom4te output, but the release tarball ships it
# (tests/Makefile.am EXTRA_DIST), so running it needs no autotools -- only the
# two fixture files `make check` would have had config.status write, plus the
# programs under test on PATH.  Both fixtures hold absolute paths, so they are
# written here at run time rather than generated at build time.
#
# $1 is the testsuite driver, $2 the cpio under test, $3 the genfile helper,
# each an `$(rlocationpath)` rather than a path relative to the working
# directory, so the lookup below works off the manifest as well as a symlink
# tree.

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

testsuite="$(rlocation "$1")"
cpio="$(rlocation "$2")"
genfile="$(rlocation "$3")"

# The driver writes testsuite.dir/ and testsuite.log beside itself, so it has
# to run from a writable copy rather than out of the read-only runfiles.
work="${TEST_TMPDIR:-/tmp}/suite"
rm -rf "$work"
mkdir -p "$work/bin"
cp "$testsuite" "$work/testsuite"
cp "$cpio" "$work/bin/cpio"
cp "$genfile" "$work/bin/genfile"
chmod +x "$work/testsuite" "$work/bin/cpio" "$work/bin/genfile"

# AC_CONFIG_TESTDIR(tests) (configure.ac:104) is what writes atconfig.
cat > "$work/atconfig" <<EOF
at_testdir='tests'
abs_builddir='$work'
at_srcdir='.'
abs_srcdir='$work'
at_top_srcdir='$work'
abs_top_srcdir='$work'
at_top_build_prefix='../'
abs_top_builddir='$work'
at_top_builddir=\$at_top_build_prefix
EXEEXT=''
AUTOTEST_PATH='tests'
SHELL=\${CONFIG_SHELL-'/bin/sh'}
EOF

# tests/atlocal.in, which AC_CONFIG_FILES (configure.ac:105) substitutes, does
# nothing but put the build directories on PATH ahead of everything else.  That
# is what makes the suite exercise the cpio built here instead of the host's.
echo "PATH=\"$work/bin:\$PATH\"" > "$work/atlocal"

cd "$work"
if ! ./testsuite; then
    echo "=== testsuite.log ===" >&2
    cat testsuite.log >&2
    exit 1
fi
