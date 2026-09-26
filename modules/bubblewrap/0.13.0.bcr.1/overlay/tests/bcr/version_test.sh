#!/usr/bin/env bash
set -euo pipefail

bwrap="$1"
expected="$2"

actual="$("$bwrap" --version)"
if [[ "$actual" != "$expected" ]]; then
  echo "expected '$expected', got '$actual'" >&2
  exit 1
fi
echo "OK: $actual"
