#!/usr/bin/env python3
"""Check append-only version changes and emit the versions requiring presubmit."""

import argparse
import base64
import hashlib
import json
import os
import subprocess
from pathlib import Path


def git(root, *arguments):
    return subprocess.check_output(["git", "-C", str(root), *arguments])


def check_changes(root, base):
    old_paths = set(git(root, "ls-tree", "-r", "--name-only", "-z", base, "--", "modules").decode().split("\0"))
    changed = set(git(root, "diff", "--name-only", "-z", base, "--", "modules").decode().split("\0"))
    changed.update(git(root, "ls-files", "--others", "--exclude-standard", "-z", "--", "modules").decode().split("\0"))
    old_versions = {tuple(Path(path).parts[:3]) for path in old_paths if len(Path(path).parts) >= 4}
    modules = set()
    versions = set()
    for path in sorted(changed - {""}):
        parts = Path(path).parts
        if len(parts) < 3:
            raise ValueError(f"Unexpected registry path: {path}")
        modules.add(parts[1])
        if parts[2] == "metadata.json":
            continue
        if len(parts) < 4:
            raise ValueError(f"Unexpected version path: {path}")
        if tuple(parts[:3]) in old_versions:
            raise ValueError(f"Published version is immutable: {path}; add a new revision instead.")
        versions.add((parts[1], parts[2]))
    for name in sorted(modules):
        relative = f"modules/{name}/metadata.json"
        metadata = json.loads((root / relative).read_text())
        if not metadata.get("maintainers"):
            raise ValueError(f"{name}: at least one maintainer is required.")
        current = metadata["versions"]
        if len(current) != len(set(current)):
            raise ValueError(f"{name}: duplicate versions in metadata.")
        if relative in old_paths:
            previous = json.loads(git(root, "show", f"{base}:{relative}"))
            removed = set(previous["versions"]) - set(current)
            if removed:
                raise ValueError(f"{name}: cannot remove versions {sorted(removed)}; yank them instead.")
        for version in current:
            if not (root / "modules" / name / version / "MODULE.bazel").is_file():
                raise ValueError(f"{name}@{version}: metadata lists a missing version.")
        if current and current[-1] in metadata.get("yanked_versions", {}) and not metadata.get("deprecated"):
            raise ValueError(f"{name}: cannot yank the latest version without deprecating the module.")
    for name, version in sorted(versions):
        path = root / "modules" / name / version
        metadata = json.loads((path.parent / "metadata.json").read_text())
        if version not in metadata["versions"]:
            raise ValueError(f"{name}@{version}: absent from metadata.")
        if version in metadata.get("yanked_versions", {}):
            raise ValueError(f"{name}@{version}: new versions must not already be yanked.")
        source = json.loads((path / "source.json").read_text())
        if source.get("type", "archive") != "archive":
            raise ValueError(f"{name}@{version}: new versions require an archive source.")
        if not source.get("integrity") or not source.get("url", "").startswith("https://"):
            raise ValueError(f"{name}@{version}: HTTPS source and integrity are required.")
        if not (path / "presubmit.yml").is_file():
            raise ValueError(f"{name}@{version}: presubmit.yml is required.")
        for directory in ("patches", "overlay"):
            for relative, expected in source.get(directory, {}).items():
                file = path / directory / relative
                if not file.resolve().is_relative_to((path / directory).resolve()) or file.is_symlink():
                    raise ValueError(f"Invalid {directory} path: {file}")
                algorithm, _ = expected.split("-", 1)
                actual = algorithm + "-" + base64.b64encode(hashlib.new(algorithm, file.read_bytes()).digest()).decode()
                if actual != expected:
                    raise ValueError(f"Integrity mismatch: {file}")
    return [f"{name}@{version}" for name, version in sorted(versions)]


def consumer_versions(spec):
    supported = {
        "6.x": "6.5.0",
        "7.x": "7.6.2",
        "8.x": "8.8.1",
        "9.x": "9.2.0",
    }
    selected = set()
    for task in spec.get("tasks", {}).values():
        platforms = (
            spec.get("matrix", {}).get("platform", [])
            if task.get("platform") == "${{ platform }}"
            else [task.get("platform")]
        )
        if "ubuntu2204" not in platforms:
            continue
        bazels = spec.get("matrix", {}).get("bazel", []) if task.get("bazel") == "${{ bazel }}" else [task.get("bazel")]
        selected.update(supported.get(bazel, bazel) for bazel in bazels)
    if not selected or None in selected:
        raise ValueError("An Ubuntu 22.04 consumer task and Bazel version are required.")
    return sorted(selected)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", required=True)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--github-output", type=Path)
    args = parser.parse_args()
    root = Path(os.environ.get("BUILD_WORKSPACE_DIRECTORY", Path(__file__).resolve().parents[1]))
    try:
        versions = check_changes(root, args.base)
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Registry policy failed: {error}\n")
    result = json.dumps(versions)
    if args.output:
        args.output.write_text(result + "\n")
    if args.github_output:
        import yaml

        matrix = []
        for module in versions:
            name, version = module.split("@")
            spec = yaml.safe_load((root / "modules" / name / version / "presubmit.yml").read_text())
            try:
                versions_to_test = consumer_versions(spec)
            except ValueError as error:
                parser.exit(1, f"{module}: {error}\n")
            matrix.extend({"module": module, "bazel_version": version} for version in versions_to_test)
        with args.github_output.open("a") as output:
            output.write(f"matrix={json.dumps(matrix)}\n")
            output.write(f"versions={result}\n")
    print(result)


if __name__ == "__main__":
    main()
