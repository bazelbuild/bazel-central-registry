#!/bin/bash
#
# Copies all Bazel files from a Folly repo to BCR Folly. Meant to be run from
# this directory. This script can be run multiple times.
#
# Example usage:
#   ./folly_to_bcr.sh /path/to/folly/repo

set -eou pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <path_to_folly_repo>" >&2
  exit 1
fi

folly_repo="$1"

if [[ ! -d $folly_repo ]]; then
  echo "error: folly repo dir \"${folly_repo}\" does not exist or is not a directory" >&2
  exit 2
fi

dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
overlay_dir="${dir}/../overlay"

mkdir -p "${overlay_dir}"

cd "${folly_repo}"
find . -name "BUILD.bazel" | rsync -av --files-from=- . "${overlay_dir}"
rsync -avR bzl/ "${overlay_dir}"
rsync -av MODULE.bazel "${dir}/../MODULE.bazel"
