#!/usr/bin/env python3
"""Package an existing pinned SM89 inference source tree without running codegen."""

import argparse
import hashlib
import json
import tarfile
from pathlib import Path


def package(source_tree: Path, output: Path) -> None:
    manifest = json.loads((source_tree / "spconv-source.json").read_text())
    expected = {
        "spconv_commit": "263d6b47425ef843c82f997b12d8b714013d216c",
        "cumm_commit": "b8d83b6511b70746d04485d0d2ec00896b735430",
        "inference_only": True,
        "cuda_arch": "8.9",
        "cuda_version": "12.8",
    }
    for key, value in expected.items():
        if manifest.get(key) != value:
            raise ValueError(f"unsupported source provenance: {key}")
    if {path.name for path in source_tree.iterdir()} != {
        "spconv", "cumm", "spconv-source.json"
    }:
        raise ValueError("source tree must contain only spconv, cumm and manifest")
    for required in [
        "spconv/include/spconvlib/spconv/csrc/sparse/all/SpconvOps.h",
        "cumm/include/tensorview/tensor.h",
        "spconv/LICENSE",
        "cumm/LICENSE",
    ]:
        if not (source_tree / required).is_file():
            raise ValueError(f"missing required source file: {required}")
    paths = sorted(
        path for path in source_tree.rglob("*") if path.name != "CMakeLists.txt"
    )
    for path in paths:
        if path.is_symlink() or not (path.is_dir() or path.is_file()):
            raise ValueError(f"unsupported source entry: {path}")
        if path.is_file():
            if path.suffix not in {".h", ".hpp", ".cuh", ".cc", ".cu", ".json", ".md", ""}:
                raise ValueError(f"unsupported file type: {path}")
            content = path.read_bytes()
            if b"\0" in content or any(
                prefix in content for prefix in [b"/apollo/", b"/home/", b"/tmp/"]
            ):
                raise ValueError(f"binary content or host-specific path: {path}")
    with output.open("xb") as destination:
        with tarfile.open(fileobj=destination, mode="w:xz", format=tarfile.PAX_FORMAT) as archive:
            for path in paths:
                info = archive.gettarinfo(path, str(path.relative_to(source_tree)))
                info.uid = info.gid = info.mtime = 0
                info.uname = info.gname = ""
                info.mode = 0o755 if info.isdir() else 0o644
                info.pax_headers = {}
                if info.isfile():
                    with path.open("rb") as source:
                        archive.addfile(info, source)
                else:
                    archive.addfile(info)
    print(f"sha256={hashlib.sha256(output.read_bytes()).hexdigest()}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-tree", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    arguments = parser.parse_args()
    package(arguments.source_tree.resolve(), arguments.output)
