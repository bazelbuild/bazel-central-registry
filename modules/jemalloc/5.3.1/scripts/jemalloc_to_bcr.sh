#!/bin/bash

# Copies all Bazel files from a jemalloc repo build with Bazel to an overlay in the BCR.
# Meant to be run from this directory. This script can be run multiple times.
#
# Example usage:
#   ./jemalloc_to_bcr.sh /path/to/jemalloc/repo

set -eou pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <path_to_repo>" >&2
  exit 1
fi

repo="$1"

if [[ ! -d $repo ]]; then
  echo "error: jemalloc repo dir \"${repo}\" does not exist or is not a directory" >&2
  exit 2
fi

dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
overlay_dir="${dir}/../overlay"

mkdir -p "${overlay_dir}"

cd "${repo}"
find . -name "BUILD.bazel" | rsync -av --files-from=- . "${overlay_dir}"
find . -name "*.bzl" | rsync -av --files-from=- . "${overlay_dir}"
rsync -av examples/ "${overlay_dir}/examples/"
rsync -av MODULE.bazel "${dir}/../MODULE.bazel"

# Remove the MODULE.bazel symlink if it exists and create a new one
if [ -e "${overlay_dir}/MODULE.bazel" ]; then
  rm "${overlay_dir}/MODULE.bazel"
fi
ln -s "../MODULE.bazel" "${overlay_dir}/MODULE.bazel"
