#!/bin/bash
#
# Copies all files from BCR Folly to a Folly repo and applies all BCR patches.
# This script is not idempotent, it should only be run once on a clean Folly
# repo.
#
# Example usage:
#   ./bcr_to_folly.sh /path/to/folly/repo

set -eou pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <path_to_folly_repo>" >&2
  exit 1
fi

bcr_folly=".."
folly_repo="$1"

if [[ ! -d $folly_repo ]]; then
  echo "error: folly repo dir \"${folly_repo}\" does not exist or is not a directory" >&2
  exit 2
fi

rsync -avL "${bcr_folly}/overlay/." "${folly_repo}"
git -C "${folly_repo}" apply -p 1 "$(realpath ${bcr_folly})/patches/"*.patch

echo
echo "Copied all files from $(realpath ${bcr_folly}) to ${folly_repo} and applied all patches, happy Bazelfying!"

# PUT THIS IN README:
# Checkout Folly repo at the version you want to Bazelfy. git checkout -b tag...
# TODO: to use this create another folder and do (otherwise the include won't work):
# bazel_dep(name = "folly")
# local_path_override(
#     module_name = "folly",
#     path = "../folly",
# )
