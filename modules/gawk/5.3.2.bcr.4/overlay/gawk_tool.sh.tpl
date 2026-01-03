#!/usr/bin/env bash

set -euo pipefail

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

GAWK=$(rlocation "$$WORKSPACE_NAME$$/$$GAWK$$")

# All of the extensions are symlinked from a single directory. But we need to provide
# `rlocation` with an actual extension file rather than the directory, because the directory
# doesn't appear in the runfiles manifest.
export AWKLIBPATH=$(dirname "$(rlocation $$WORKSPACE_NAME$$/$$SAMPLE_EXTENSION$$)")

"$GAWK" "$@"
