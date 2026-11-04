#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"

# Use Git's own generator to keep behavior identical.
GIT_VERSION="$("$ROOT/GIT-VERSION-GEN" "$ROOT" --format='@GIT_VERSION@')"
GIT_BUILT_FROM_COMMIT="$("$ROOT/GIT-VERSION-GEN" "$ROOT" --format='@GIT_BUILT_FROM_COMMIT@')"
GIT_DATE="$("$ROOT/GIT-VERSION-GEN" "$ROOT" --format='@GIT_DATE@')"
GIT_USER_AGENT="$("$ROOT/GIT-VERSION-GEN" "$ROOT" --format='@GIT_USER_AGENT@')"

# Keys starting with STABLE_ go into stable-status.txt (i.e. cache-keyed).
echo "STABLE_GIT_VERSION ${GIT_VERSION}"
echo "STABLE_GIT_BUILT_FROM_COMMIT ${GIT_BUILT_FROM_COMMIT}"
echo "STABLE_GIT_DATE ${GIT_DATE}"
echo "STABLE_GIT_USER_AGENT ${GIT_USER_AGENT}"
