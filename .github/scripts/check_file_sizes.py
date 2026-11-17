#!/usr/bin/env python3
#
# Copyright 2026 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Checks that repository Git blobs do not exceed the 25 MiB size limit."""

import argparse
import os
from pathlib import Path
import subprocess
import sys

BYTES_PER_MIB = 1024 * 1024
MAX_FILE_SIZE_BYTES = 25 * BYTES_PER_MIB
DEFAULT_REPO_DIR = str(Path(__file__).resolve().parents[2])


def _run_git(repo_dir, args, input_text=None, check=True):
    return subprocess.run(
        ["git", "-C", repo_dir, "-c", "core.quotePath=false", *args],
        input=input_text,
        check=check,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        errors="surrogateescape",
    )


def find_oversized_blobs(repo_dir, base_ref="origin/main", max_bytes=MAX_FILE_SIZE_BYTES):
    """Returns sorted (path, size_bytes) pairs exceeding max_bytes."""
    head_check = _run_git(repo_dir, ["rev-parse", "--verify", "HEAD"], check=False)
    if head_check.returncode != 0:
        return []

    oversized = {}

    ls_tree = _run_git(repo_dir, ["ls-tree", "-r", "-l", "-z", "HEAD"])
    for entry in ls_tree.stdout.split("\0"):
        if not entry or "\t" not in entry:
            continue
        meta, path = entry.split("\t", 1)
        parts = meta.split()
        if len(parts) < 4:
            continue
        obj_type, size_str = parts[1], parts[3]
        if obj_type != "blob" or size_str == "-":
            continue
        size = int(size_str)
        if size > max_bytes:
            oversized[path] = max(oversized.get(path, 0), size)

    if base_ref:
        merge_base = _run_git(repo_dir, ["merge-base", base_ref, "HEAD"], check=False)
        if merge_base.returncode == 0:
            base_sha = merge_base.stdout.strip()
            rev_list = _run_git(repo_dir, ["rev-list", "--objects", f"{base_sha}..HEAD"])
            if rev_list.stdout:
                cat_file = _run_git(
                    repo_dir,
                    ["cat-file", "--batch-check=%(objecttype) %(objectsize) %(rest)"],
                    input_text=rev_list.stdout,
                )
                for line in cat_file.stdout.splitlines():
                    parts = line.split(" ", 2)
                    if len(parts) < 2 or parts[0] != "blob":
                        continue
                    size = int(parts[1])
                    if size > max_bytes:
                        path = parts[2] if len(parts) > 2 and parts[2] else "<unnamed blob>"
                        oversized[path] = max(oversized.get(path, 0), size)

    return sorted(oversized.items())


def _resolve_default_base_ref(repo_dir):
    gh_base = os.environ.get("GITHUB_BASE_REF", "").strip()
    if gh_base:
        remote_ref = f"origin/{gh_base}"
        verify = _run_git(
            repo_dir,
            ["rev-parse", "--verify", "--quiet", f"refs/remotes/{remote_ref}"],
            check=False,
        )
        if verify.returncode == 0:
            return remote_ref
        fetch = _run_git(repo_dir, ["fetch", "--no-tags", "origin", gh_base], check=False)
        if fetch.returncode == 0:
            return "FETCH_HEAD"
        return remote_ref

    for candidate, full_ref in (
        ("upstream/main", "refs/remotes/upstream/main"),
        ("origin/main", "refs/remotes/origin/main"),
        ("main", "refs/heads/main"),
    ):
        verify = _run_git(
            repo_dir,
            ["rev-parse", "--verify", "--quiet", full_ref],
            check=False,
        )
        if verify.returncode == 0:
            return candidate
    return "origin/main"


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-dir",
        default=DEFAULT_REPO_DIR,
        help="Path to the Git repository root.",
    )
    parser.add_argument(
        "--base-ref",
        default=None,
        help="Base Git ref used to inspect blobs across commits in base..HEAD.",
    )
    parser.add_argument(
        "--max-bytes",
        type=int,
        default=MAX_FILE_SIZE_BYTES,
        help="Maximum allowed blob size in bytes.",
    )
    args = parser.parse_args(argv)
    base_ref = args.base_ref if args.base_ref is not None else _resolve_default_base_ref(args.repo_dir)

    oversized = find_oversized_blobs(args.repo_dir, base_ref=base_ref, max_bytes=args.max_bytes)
    if not oversized:
        return 0

    limit_mib = args.max_bytes / BYTES_PER_MIB
    print(
        f"ERROR: File(s) exceed the {limit_mib:g} MiB ({args.max_bytes:,} bytes) limit "
        "due to limitations of an internal clone of this repository:",
        file=sys.stderr,
    )
    for path, size in oversized:
        size_mib = size / BYTES_PER_MIB
        print(f"  - {path}: {size_mib:.2f} MiB ({size:,} bytes)", file=sys.stderr)
    print(
        "Reference external archives (for example, via source.json) instead of committing large files to Git.",
        file=sys.stderr,
    )
    return 1


if __name__ == "__main__":
    sys.exit(main())
