"""Refresh derived registry descriptors; optionally freeze verified output bytes."""

import argparse
import base64
import hashlib
import json
from pathlib import Path


def integrity(path):
    digest = hashlib.sha256(path.read_bytes()).digest()
    return "sha256-" + base64.b64encode(digest).decode("ascii")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--generated", type=Path)
    args = parser.parse_args()
    version = Path(__file__).resolve().parent
    overlay = version / "overlay"
    if args.generated:
        outputs = {
            str(path.relative_to(args.generated)): hashlib.sha256(
                path.read_bytes()
            ).hexdigest()
            for path in sorted(args.generated.rglob("*"))
            if path.is_file() and path.name != "CMakeLists.txt"
        }
        if not outputs or any(
            Path(name).suffix not in (".h", ".cc", ".cu") for name in outputs
        ):
            raise ValueError("Expected complete generated header/C++/CUDA tree")
        (overlay / "bazel/outputs.bzl").write_text(
            '"""Generated from pinned upstream inference output; do not edit."""\n'
            + "OUTPUTS = "
            + json.dumps(outputs, indent=4)
            + "\n"
        )
    (version / "MODULE.bazel").write_bytes((overlay / "MODULE.bazel").read_bytes())
    provenance = {
        "spconv_version": "2.3.8",
        "spconv_commit": "263d6b47425ef843c82f997b12d8b714013d216c",
        "cumm_version": "0.7.11",
        "cumm_wheel_sha256": (
            "a2632c003aad2c8ea0ef0d384c7813e786e853389afbf57e8bf53ba2e843a566"
        ),
        "inference_only": True,
        "cuda_arch": "8.9",
        "cuda_version": "12.8",
        "generator": "spconv.gencode",
        "integration_inputs": {
            str(path.relative_to(overlay)): integrity(path)
            for path in sorted(overlay.rglob("*"))
            if path.is_file()
            and path.name != "spconv-source.json"
            and "__pycache__" not in path.parts
        },
    }
    (overlay / "spconv-source.json").write_text(json.dumps(provenance, indent=4) + "\n")
    source = {
        "url": (
            "https://github.com/traveller59/spconv/archive/"
            "263d6b47425ef843c82f997b12d8b714013d216c.tar.gz"
        ),
        "integrity": "sha256-wlAqswLKwFCNwQd3B/M0nZ3lc3QetENnMd9V2Si4iZ4=",
        "strip_prefix": "spconv-263d6b47425ef843c82f997b12d8b714013d216c",
        "overlay": {
            str(path.relative_to(overlay)): integrity(path)
            for path in sorted(overlay.rglob("*"))
            if path.is_file() and "__pycache__" not in path.parts
        },
    }
    (version / "source.json").write_text(json.dumps(source, indent=4) + "\n")


if __name__ == "__main__":
    main()
