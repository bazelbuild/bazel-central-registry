#!/usr/bin/env bash
# Runs an mlx-c example from a writable scratch directory. The examples read
# and write files relative to the current working directory.
set -euo pipefail

binary="$PWD/$1"
shift
cd "${TEST_TMPDIR}"
for data in "$@"; do
  cp "${OLDPWD}/${data}" .
done
exec "${binary}"
