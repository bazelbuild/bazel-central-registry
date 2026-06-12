#!/usr/bin/env bash
#
#  gen_cov_style.sh - embed the coverage report stylesheet as a C string.
#
#  Mirrors the cov-style.h rule from src/cov/Makemodule.am: each line of the
#  CSS is turned into a quoted, newline-terminated C string literal.
#
set -euo pipefail

src="$1"
out="$2"

{
   echo 'static const char cov_style[] ='
   sed -e 's/\\/\\\\/g' \
       -e 's/"/\\"/g' \
       -e 's/$/\\n"/' \
       -e 's/^/"/' \
       "$src"
   echo ';'
} > "$out"
