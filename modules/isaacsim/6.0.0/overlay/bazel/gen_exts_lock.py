#!/usr/bin/env python3
"""Generate a Bazel lockfile for the closed-source Omniverse Kit extensions.

Only the closed extensions (shipped as prebuilt archives on the packman CDN) are
locked here; the Apache-2.0 isaacsim.* extensions are built from source, see
//bazel:source_exts.bzl.

Kit itself does the dependency resolution: run

    bazel run @isaacsim//:precache

which downloads the resolved closure into the shared ext cache. This script then
turns that resolved set into a JSON lock of pinned (url, sha256) pairs by looking
each package up in the local registry index and hashing the archive. The lock is
consumed by this module's `kit.extensions(lock = ...)`, see //bazel:kit.bzl.

The resolved set is read from the app's per-app extension link directory, whose
entry names are exactly registry packageIds (the shared cache next to it uses
opaque `<name>-<blobhash>` names instead, which cannot be looked up).

Usage:
    bazel run @isaacsim//bazel:gen_exts_lock -- --out bazel/exts_lock.json \
        [--resolved-dir '~/.local/share/ov/data/Kit/isaacsim.exp.base/*/exts/*'] \
        [--index-glob '~/.local/share/ov/data/exts/v2/index/*/packages/*.json']
"""

from __future__ import annotations

import argparse
import concurrent.futures
import hashlib
import json
import glob
import os
import re
import sys
import urllib.request

# Extension cache dir names look like <name>-<version>+<metadata>, e.g.
# omni.replicator.core-1.13.27+110.1.1.lx64.r.cp312 -- but platform-independent
# packages are published with no metadata suffix at all (omni.kit.browser.core-2.3.18),
# so it has to be optional or those silently drop out of the lock.
_PKG_DIR_RE = re.compile(
    r"^(?P<name>[^/]+?)-(?P<version>\d[^+]*?)(?:\+(?P<meta>.+))?$",
)


def load_index(index_glob: str) -> dict[str, dict]:
    """packageId -> parsed index record. Index files are '<packageId> <json>' lines."""
    index: dict[str, dict] = {}
    for path in glob.glob(os.path.expanduser(index_glob)):
        with open(path, encoding="utf-8") as fh:
            for line in fh:
                pid, _, blob = line.partition(" ")
                if not blob:
                    continue
                try:
                    index[pid] = json.loads(blob)
                except json.JSONDecodeError:
                    continue
    return index


def resolved_package_ids(resolved_glob: str) -> list[str]:
    """Package IDs Kit actually chose, from the app's extension link directories."""
    out: set[str] = set()
    for root in glob.glob(os.path.expanduser(resolved_glob)):
        if not os.path.isdir(root):
            continue
        for entry in os.listdir(root):
            if _PKG_DIR_RE.match(entry):
                out.add(entry)
    return sorted(out)


def repo_name(package_id: str) -> str:
    """Bazel repo name: omni.replicator.core-1.13.27+... -> ext_omni_replicator_core"""
    name = package_id.split("-", 1)[0] if "-" in package_id else package_id
    m = _PKG_DIR_RE.match(package_id)
    if m:
        name = m.group("name")
    return "ext_" + re.sub(r"[^0-9a-zA-Z]+", "_", name).strip("_").lower()


def load_existing_lock(path: str) -> dict[str, tuple[str, str, int]]:
    """packageId -> (url, sha256, size) from a previously generated lockfile."""
    if not os.path.exists(path):
        return {}
    try:
        with open(path, encoding="utf-8") as fh:
            lock = json.load(fh)
    except (OSError, json.JSONDecodeError):
        return {}
    return {
        pid: (spec["url"], spec["sha256"], spec.get("size", 0))
        for pid, spec in lock.items()
        if spec.get("url") and spec.get("sha256")
    }


def sha256_of_url(url: str) -> tuple[str, int]:
    h = hashlib.sha256()
    total = 0
    with urllib.request.urlopen(url) as resp:  # noqa: S310 - fixed CDN host
        while chunk := resp.read(1 << 20):
            h.update(chunk)
            total += len(chunk)
    return h.hexdigest(), total


def workspace_relative(path: str) -> str:
    """Resolve a relative path against the directory `bazel run` was invoked in.

    Under `bazel run` the working directory is the runfiles tree, so a relative
    --out would write the regenerated lock into the build output instead of the
    source tree the caller meant.
    """
    expanded = os.path.expanduser(path)
    root = os.environ.get("BUILD_WORKING_DIRECTORY")
    if os.path.isabs(expanded) or not root:
        return expanded
    return os.path.join(root, expanded)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument(
        "--resolved-dir",
        default="~/.local/share/ov/data/Kit/*/*/exts/*",
        help="Glob of app extension link dirs (entry names are registry packageIds).",
    )
    ap.add_argument(
        "--index-glob",
        default="~/.local/share/ov/data/exts/v2/index/*/packages/*.json",
    )
    ap.add_argument("--jobs", type=int, default=8)
    ap.add_argument(
        "--reuse",
        action="store_true",
        help="Keep sha256 values already recorded in --out for unchanged URLs, "
        "so only newly resolved archives are downloaded.",
    )
    ap.add_argument(
        "--reuse-from",
        action="append",
        default=[],
        metavar="LOCK",
        help="Additional lockfile to take hashes from. Useful when two apps share "
        "most of their closure; may be repeated. Implies --reuse.",
    )
    args = ap.parse_args()

    index = load_index(args.index_glob)
    if not index:
        print("ERROR: registry index empty; run a precache first", file=sys.stderr)
        return 1

    pkg_ids = resolved_package_ids(args.resolved_dir)
    if not pkg_ids:
        print("ERROR: no resolved extensions found", file=sys.stderr)
        return 1
    print(f"resolved extensions: {len(pkg_ids)}", file=sys.stderr)

    entries, missing = [], []
    for pid in pkg_ids:
        rec = index.get(pid)
        url = (rec or {}).get("package", {}).get("archivePath")
        if not url:
            missing.append(pid)
            continue
        entries.append((pid, url))

    if missing:
        print(
            f"WARNING: {len(missing)} extension(s) not in the registry index "
            f"(kernel-bundled or locally built): {', '.join(missing[:5])}"
            + (" ..." if len(missing) > 5 else ""),
            file=sys.stderr,
        )

    out_path = workspace_relative(args.out)
    reuse_from = [workspace_relative(p) for p in args.reuse_from]

    hashes: dict[str, tuple[str, int]] = {}
    if args.reuse or args.reuse_from:
        known: dict[str, tuple[str, str, int]] = {}
        for path in [out_path, *reuse_from]:
            known.update(load_existing_lock(path))
        for pid, url in entries:
            prev = known.get(pid)
            if prev and prev[0] == url:
                hashes[pid] = (prev[1], prev[2])
        if hashes:
            sources = ", ".join([out_path, *reuse_from])
            print(f"reusing {len(hashes)} hashes from {sources}", file=sys.stderr)

    todo = [(pid, url) for pid, url in entries if pid not in hashes]
    print(f"hashing {len(todo)} archives...", file=sys.stderr)
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as pool:
        futs = {pool.submit(sha256_of_url, url): (pid, url) for pid, url in todo}
        for i, fut in enumerate(concurrent.futures.as_completed(futs), 1):
            pid, url = futs[fut]
            try:
                hashes[pid] = fut.result()
            except Exception as exc:  # noqa: BLE001
                print(f"  FAILED {pid}: {exc}", file=sys.stderr)
            if i % 10 == 0:
                print(f"  {i}/{len(todo)}", file=sys.stderr)

    total_bytes = sum(sz for _, sz in hashes.values())
    lock = {}
    for pid, url in sorted(entries):
        if pid not in hashes:
            continue
        sha, size = hashes[pid]
        lock[pid] = {
            "name": _PKG_DIR_RE.match(pid).group("name"),
            "url": url,
            "sha256": sha,
            "size": size,
        }

    out_path = os.path.abspath(out_path)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as fh:
        json.dump(lock, fh, indent=2, sort_keys=True)
        fh.write("\n")
    print(f"wrote {out_path}: {len(lock)} exts, {total_bytes / 1e9:.2f} GB", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
