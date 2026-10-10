#!/usr/bin/env bash
# Checks @isaacsim//:extensions is a directory Kit would accept as an
# --ext-folder, and that the extensions inside it are laid out the way their
# premake5.lua says -- not the way a uniform guess would lay them out.
#
# argv: $1 = rlocationpath of @isaacsim//:extensions

# --- begin runfiles.bash initialization v3 ---
set -uo pipefail
f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  { echo >&2 "ERROR: cannot locate bazel runfiles library"; exit 1; }
# --- end runfiles.bash initialization v3 ---
set -e

farm="$(rlocation "$1")"
if [[ -z "${farm}" || ! -d "${farm}" ]]; then
  echo >&2 "FAIL: extension folder not found in runfiles: $1"
  exit 1
fi

failures=0
fail() {
  echo >&2 "FAIL: $*"
  failures=$((failures + 1))
}

# Every entry must be an extension Kit can read, i.e. carry its manifest.
count=0
while IFS= read -r ext; do
  count=$((count + 1))
  if [[ ! -f "${farm}/${ext}/config/extension.toml" ]]; then
    fail "${ext} has no config/extension.toml"
  fi
done < <(ls "${farm}")

if (( count < 96 )); then
  fail "expected ~100 source-built extensions, found ${count}"
fi

# premake copies python/mock/*.py *flat* into the package root while relocating
# python/impl into a subpackage, so this is where
# isaacsim.core.experimental.utils.ops has to end up. Getting it wrong yields an
# extension Kit loads but whose submodules cannot be imported.
expect_file() {
  if [[ ! -f "${farm}/$1" ]]; then
    fail "missing $1"
  fi
}

expect_file "isaacsim.core.experimental.utils/isaacsim/core/experimental/utils/ops.py"
expect_file "isaacsim.core.experimental.utils/isaacsim/core/experimental/utils/impl/prim.py"
expect_file "isaacsim.core.version/isaacsim/core/version/__init__.py"
expect_file "isaacsim.replicator.behavior/isaacsim/replicator/behavior/__init__.py"

# source/deprecated/ extensions are shipped and still referenced by the stock
# app configs, so they are built too.
expect_file "isaacsim.core.prims/config/extension.toml"

# OmniGraph databases are generated from the .ogn definitions at build time.
# They are not in the source tree, and an extension missing them loads happily
# and then fails the moment one of its nodes is used.
expect_file "isaacsim.replicator.writers/isaacsim/replicator/writers/ogn/OgnDopeDatabase.py"
expect_file "isaacsim.replicator.writers/isaacsim/replicator/writers/ogn/tests/TestOgnDope.py"
expect_file "isaacsim.core.experimental.actuators/isaacsim/core/experimental/actuators/ogn/OgnArticulationActuatorsDatabase.py"

if (( failures > 0 )); then
  echo >&2 "${failures} check(s) failed"
  exit 1
fi

echo "OK: ${count} source-built Isaac Sim extensions, layouts as premake declares"
