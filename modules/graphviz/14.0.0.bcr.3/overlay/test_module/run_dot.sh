#!/bin/bash
set -euo pipefail

dot_bin="${1:?missing dot binary path}"

if [[ ! -x "${dot_bin}" ]]; then
  echo "not executable: ${dot_bin}" >&2
  exit 1
fi

out=$(echo 'digraph G { a -> b }' | "${dot_bin}" -Tdot)
if ! grep -q 'a -> b' <<<"${out}"; then
  echo "dot output missing expected edge:" >&2
  echo "${out}" >&2
  exit 1
fi
