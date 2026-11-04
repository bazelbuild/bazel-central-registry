#!/usr/bin/env bash
# Smoke test: the checker starts and reports its version.
set -euo pipefail
"$1" --version | grep "^kepler-formal version: "
