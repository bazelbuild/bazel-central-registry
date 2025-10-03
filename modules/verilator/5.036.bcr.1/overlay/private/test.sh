#!/usr/bin/env bash
set -euxo pipefail

VERILATOR="$1"
VERILATOR_ARGS="$2"
TOP="$3"
OUTDIR="$TEST_TMPDIR/obj"

"$VERILATOR" "$VERILATOR_ARGS" "$TOP" --Mdir="$OUTDIR" --build
