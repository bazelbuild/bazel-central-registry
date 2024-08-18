#!/bin/bash

set -euxo pipefail

genhtml="$1"

test "$("$genhtml" 2>&1 --version)" == "genhtml: LCOV version 2.1-1"
