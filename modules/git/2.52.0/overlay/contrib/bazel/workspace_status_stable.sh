#!/usr/bin/env bash
set -euo pipefail

# Stable values to avoid cache churn between commits.
echo "STABLE_GIT_VERSION 0.0.0"
echo "STABLE_GIT_BUILT_FROM_COMMIT UNKNOWN"
echo "STABLE_GIT_DATE 1970-01-01"
echo "STABLE_GIT_USER_AGENT git/0.0.0"
