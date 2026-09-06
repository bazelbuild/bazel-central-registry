#!/bin/bash
#
# Copies all files under the overlay dir in BCR Folly to a Folly repo and
# applies all BCR patches. This script is not idempotent, it should only be run
# once on a clean Folly repo. Meant to be run from this directory.
#
# Example usage:
#   ./bcr_to_folly.sh /path/to/folly/repo

set -eou pipefail

if [[ "$#" -ne 1 ]]; then
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
