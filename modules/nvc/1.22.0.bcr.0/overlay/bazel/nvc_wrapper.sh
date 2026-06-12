#!/usr/bin/env bash
#
#  nvc_wrapper.sh - run the Bazel-built nvc with NVC_LIBPATH pointing at the
#  bootstrapped standard libraries in the runfiles tree.
#
#  This is a convenience entry point for `bazel run //:nvc_cmd -- ...`.  The raw
#  compiler is //:nvc; consumers that install NVC elsewhere should set
#  NVC_LIBPATH (or pass -L) themselves.
#
set -euo pipefail

self="$(cd "$(dirname "$0")" >/dev/null 2>&1 && pwd)/$(basename "$0")"
runfiles="${RUNFILES_DIR:-${self}.runfiles}"
root="${runfiles}/_main"

if [ ! -x "${root}/nvc" ]; then
   # Executed from inside the runfiles tree itself.
   root="$(dirname "${self}")"
fi

export NVC_LIBPATH="${NVC_LIBPATH:+${NVC_LIBPATH}:}${root}/stdlib"
exec "${root}/nvc" "$@"
