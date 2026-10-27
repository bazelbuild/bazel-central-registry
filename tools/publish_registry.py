#!/usr/bin/env python3
"""Publish registry objects without replacing or deleting versioned content."""

import argparse
import hashlib
import json
import subprocess
import tempfile
from pathlib import Path


def plan_uploads(root, existing, read_remote, candidates=None):
    immutable = []
    mutable = []
    paths = [root / "bazel_registry.json", *sorted((root / "modules").rglob("*"))]
    for path in paths:
        if path.is_symlink():
            raise ValueError(f"Registry symlinks are not publishable: {path}")
        if not path.is_file():
            continue
        key = path.relative_to(root).as_posix()
        is_metadata = key == "bazel_registry.json" or (
            len(path.relative_to(root).parts) == 3 and path.name == "metadata.json"
        )
        if candidates is not None and key in existing and key not in candidates:
            continue
        if key in existing:
            remote = read_remote(key)
            if remote == path.read_bytes():
                continue
            if not is_metadata:
                raise ValueError(f"Refusing to overwrite published object: {key}")
            if path.name == "metadata.json":
                previous = set(json.loads(remote)["versions"])
                current = set(json.loads(path.read_bytes())["versions"])
                if not previous <= current:
                    raise ValueError(f"Refusing to remove published versions from {key}")
        (mutable if is_metadata else immutable).append((key, path))
    missing = {key for key in existing if key.startswith("modules/") and not (root / key).is_file()}
    if missing:
        raise ValueError(f"Remote registry contains objects absent locally: {sorted(missing)[:5]}")
    return immutable, mutable


def validate_publication(immutable, mutable, validated, existing, read_remote):
    required = {f"{Path(key).parts[1]}@{Path(key).parts[2]}" for key, _ in immutable}
    for key, path in mutable:
        if path.name != "metadata.json":
            continue
        previous = set(json.loads(read_remote(key))["versions"]) if key in existing else set()
        required.update(
            f"{path.parent.name}@{version}" for version in set(json.loads(path.read_bytes())["versions"]) - previous
        )
    missing = required - set(validated)
    if missing:
        raise ValueError(
            f"Publication includes versions without this run's consumer validation: "
            f"{sorted(missing)}; rerun validation from an earlier base."
        )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bucket", required=True)
    parser.add_argument("--endpoint-url", required=True)
    parser.add_argument("--validated-versions", type=Path, required=True)
    parser.add_argument("--base", required=True, help="Same registry base used for validation")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    changed = subprocess.check_output(
        ["git", "-C", str(root), "diff", "--name-only", "-z", args.base, "--", "modules", "bazel_registry.json"]
    )
    untracked = subprocess.check_output(
        [
            "git",
            "-C",
            str(root),
            "ls-files",
            "--others",
            "--exclude-standard",
            "-z",
            "--",
            "modules",
            "bazel_registry.json",
        ]
    )
    candidates = set((changed + untracked).decode().split("\0")) - {""}
    aws = ["aws", "--endpoint-url", args.endpoint_url, "s3api"]
    listing = json.loads(
        subprocess.check_output([*aws, "list-objects-v2", "--bucket", args.bucket, "--output", "json"])
    )
    existing = {entry["Key"] for entry in listing.get("Contents", [])}
    etags = {entry["Key"]: entry["ETag"] for entry in listing.get("Contents", [])}
    with tempfile.TemporaryDirectory(prefix="registry-publish-") as directory:

        def read_remote(key):
            output = Path(directory) / "object"
            subprocess.run(
                [
                    *aws,
                    "get-object",
                    "--bucket",
                    args.bucket,
                    "--key",
                    key,
                    str(output),
                ],
                check=True,
                stdout=subprocess.DEVNULL,
            )
            return output.read_bytes()

        immutable, mutable = plan_uploads(root, existing, read_remote, candidates)
        validate_publication(
            immutable,
            mutable,
            json.loads(args.validated_versions.read_text()),
            existing,
            read_remote,
        )
        # Complete every immutable object before advertising versions in metadata.
        for key, path in [*immutable, *mutable]:
            command = [
                *aws,
                "put-object",
                "--bucket",
                args.bucket,
                "--key",
                key,
                "--body",
                str(path),
                "--metadata",
                "sha256=" + hashlib.sha256(path.read_bytes()).hexdigest(),
            ]
            if key not in existing:
                command.extend(["--if-none-match", "*"])
            else:
                command.extend(["--if-match", etags[key]])
            subprocess.run(command, check=True, stdout=subprocess.DEVNULL)
            if read_remote(key) != path.read_bytes():
                raise ValueError(f"Remote publication verification failed: {key}")
            print(f"Published {key}", flush=True)


if __name__ == "__main__":
    main()
