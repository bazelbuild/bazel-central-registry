#!/usr/bin/env bash
# Runs one of upstream's unit-tests/ programs the way `make check` does: from a
# writable directory that holds `files/` (the fixtures test.c and
# test-parse-html.c read through SRCDIR) and, for test-dl, `.libs/` with the
# two dummy plugins it dlopen()s.  The programs also create scratch entries
# (.test/, .test_dl_dir/) beside themselves, which rules out running them from
# the read-only runfiles tree.
#
# $1 is the test program, the remaining arguments its data files; every one is
# an `$(rlocationpath)` rather than a path relative to the working directory,
# so the lookup below works off the manifest as well as a symlink tree.

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

program="$(rlocation "$1")"
shift

work="${TEST_TMPDIR:-/tmp}/unit-tests"
rm -rf "$work"
mkdir -p "$work/files" "$work/.libs"

# Plugins go where libtool's `make check` would have left them (test-dl.c:65,
# BUILD_NAME); everything else is a fixture under files/.
for arg in "$@"; do
    path="$(rlocation "$arg")"
    case "$path" in
        *.so | *.dylib | *.dll) cp "$path" "$work/.libs/" ;;
        *) cp "$path" "$work/files/" ;;
    esac
done

cd "$work"
exec "$program"
