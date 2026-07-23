#!/usr/bin/env python3
"""Refresh `Cargo.lock` and `cargo-bazel-lock.json` in `modules/prjoxide/<version>/overlay/libprjoxide/`."""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile
import zipfile
from pathlib import Path

MODULE_NAME = "prjoxide"
HERE = Path(__file__).resolve().parent
REGISTRY_ROOT = HERE.parent.parent  # modules/prjoxide -> modules -> <registry root>

sys.path.insert(0, str(REGISTRY_ROOT / "tools"))
from registry import RegistryClient, download_file, integrity_for_comparison, read  # noqa: E402


def parse_args() -> argparse.Namespace:
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "versions",
        nargs="*",
        help=(f"versions under modules/{MODULE_NAME}/ to refresh. With no arguments, refreshes every version on disk."),
    )
    parser.add_argument(
        "--keep-workdir",
        action="store_true",
        help="don't delete the scratch directory after running (useful when debugging)",
    )
    return parser.parse_args()


def _log(msg: str) -> None:
    print(f"[repin] {msg}", file=sys.stderr, flush=True)


def _run(cmd: list[str], cwd: Path, env: dict[str, str] | None = None) -> None:
    _log(f"$ {' '.join(cmd)}  (cwd={cwd})")
    subprocess.run(cmd, cwd=cwd, env=env, check=True)


def _all_versions() -> list[str]:
    return sorted(
        p.name
        for p in (REGISTRY_ROOT / "modules" / MODULE_NAME).iterdir()
        if p.is_dir() and (p / "source.json").exists()
    )


def _extract(archive: Path, dest: Path, strip_prefix: str) -> Path:
    dest.mkdir(parents=True, exist_ok=True)
    if archive.suffix == ".zip":
        with zipfile.ZipFile(archive) as zf:
            zf.extractall(dest)
    elif archive.name.endswith((".tar.gz", ".tgz", ".tar")):
        with tarfile.open(archive) as tf:
            tf.extractall(dest)
    else:
        raise SystemExit(f"unsupported archive type: {archive.name}")
    extracted = dest / strip_prefix if strip_prefix else dest
    if not extracted.exists():
        raise SystemExit(f"strip_prefix {strip_prefix!r} not present in archive {archive.name}")
    return extracted


def _apply_patches(version_dir: Path, source: dict, work_tree: Path) -> None:
    patches = source.get("patches", {})
    if not patches:
        return
    patch_strip = source.get("patch_strip", 0)
    patches_dir = version_dir / "patches"
    for patch_name in sorted(patches.keys()):
        patch_file = patches_dir / patch_name
        if not patch_file.exists():
            raise SystemExit(f"patch listed in source.json not found on disk: {patch_file}")
        _run(["patch", f"-p{patch_strip}", "-i", str(patch_file)], cwd=work_tree)


def _cargo_lock(work_tree: Path) -> Path:
    workspace = work_tree / "libprjoxide"
    (workspace / "Cargo.lock").unlink(missing_ok=True)
    _run(["cargo", "generate-lockfile", "--manifest-path", "Cargo.toml"], cwd=workspace)
    return workspace / "Cargo.lock"


def _cargo_bazel_lock(work_tree: Path) -> Path:
    # The overlay declares `module(name = "prjoxide")` at work_tree/MODULE.bazel,
    # so for this invocation the scratch tree IS the prjoxide root module —
    # the only context in which crate_universe permits regenerating its lockfile.
    (work_tree / ".bazelrc").write_text(
        f"common --enable_bzlmod --lockfile_mode=off --registry=file://{REGISTRY_ROOT} --registry=https://bcr.bazel.build\n"
    )
    env = dict(os.environ, CARGO_BAZEL_REPIN="1")
    _run(["bazel", "build", "@prjoxide_crates//:all"], cwd=work_tree, env=env)
    lock = work_tree / "libprjoxide" / "cargo-bazel-lock.json"
    if not lock.exists():
        raise SystemExit(f"crate_universe did not write {lock}")
    return lock


def _repin_one(version: str, keep_workdir: bool) -> None:
    version_dir = REGISTRY_ROOT / "modules" / MODULE_NAME / version
    overlay_dir = version_dir / "overlay"
    if not overlay_dir.exists():
        raise SystemExit(f"expected overlay at {overlay_dir}, not found")

    source = json.loads((version_dir / "source.json").read_text())

    workdir = Path(tempfile.mkdtemp(prefix=f"{MODULE_NAME}-repin-{version}-"))
    try:
        _log(f"=== {MODULE_NAME}@{version} -> {workdir}")
        archive = workdir / Path(source["url"].split("/")[-1] or "archive")
        _log(f"downloading {source['url']}")
        download_file(source["url"], str(archive))
        actual = integrity_for_comparison(read(archive), source["integrity"])
        if actual != source["integrity"]:
            raise SystemExit(f"integrity mismatch for {archive.name}: expected {source['integrity']}, got {actual}")

        work_tree = _extract(archive, workdir / "src", source.get("strip_prefix", ""))
        _apply_patches(version_dir, source, work_tree)
        shutil.copytree(overlay_dir, work_tree, dirs_exist_ok=True)

        shutil.copy2(_cargo_lock(work_tree), overlay_dir / "libprjoxide" / "Cargo.lock")
        shutil.copy2(
            _cargo_bazel_lock(work_tree),
            overlay_dir / "libprjoxide" / "cargo-bazel-lock.json",
        )

        _log(f"refreshing SRI hashes in {version_dir / 'source.json'}")
        RegistryClient(REGISTRY_ROOT).update_integrity(MODULE_NAME, version)
        _log(f"refreshed {MODULE_NAME}@{version}")
    finally:
        if keep_workdir:
            _log(f"keeping scratch dir at {workdir}")
        else:
            shutil.rmtree(workdir, ignore_errors=True)


def main() -> int:
    args = parse_args()

    requested = args.versions or _all_versions()
    if not requested:
        raise SystemExit(f"no versions found under modules/{MODULE_NAME}/")

    unknown = [v for v in requested if not (REGISTRY_ROOT / "modules" / MODULE_NAME / v).is_dir()]
    if unknown:
        raise SystemExit(
            f"unknown {MODULE_NAME} version(s): {', '.join(unknown)}. Available: {', '.join(_all_versions())}"
        )

    for version in requested:
        _repin_one(version, args.keep_workdir)
    _log(f"done. refreshed {len(requested)} version(s): {', '.join(requested)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
