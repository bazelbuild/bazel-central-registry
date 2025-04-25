#!/bin/bash
set -eou pipefail

if [ "$#" -ne 1 ]; then
  echo "Missing required arg: folly_src_path"
  exit 1
fi

folly_src_path="$1"

if [ ! -d "${folly_src_path}" ]; then
  echo "folly_src_path is not a valid directory: ${folly_src_path}"
  exit 1
fi

dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
overlay_dir="${dir}/overlay"

mkdir -p "${overlay_dir}"

cd "${folly_src_path}"
find . -name "BUILD.bazel" | rsync -av --files-from=- . "${overlay_dir}"
rsync -avR bzl/ "${overlay_dir}"
rsync -av MODULE.bazel "${dir}/MODULE.bazel"
