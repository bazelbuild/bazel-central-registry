"""Run upstream PCCM generation and reject output or content drift."""

import argparse
import ast
import hashlib
import shutil
import tempfile
from pathlib import Path


def read_manifest(path):
    text = Path(path).read_text(encoding="utf-8")
    outputs = ast.literal_eval(text.split("OUTPUTS = ", 1)[1])
    for name in outputs:
        relative = Path(name)
        if relative.is_absolute() or ".." in relative.parts:
            raise ValueError(f"Invalid generated output path: {name}")
        if relative.suffix not in (".h", ".cc", ".cu"):
            raise ValueError(f"Unsupported generated output: {name}")
    return outputs


def validate_tree(root, expected):
    actual = {
        str(path.relative_to(root)): path
        for path in root.rglob("*")
        if path.is_file() and path.name != "CMakeLists.txt"
    }
    if actual.keys() != expected.keys():
        missing = sorted(expected.keys() - actual.keys())
        extra = sorted(actual.keys() - expected.keys())
        raise ValueError(
            f"Generated file set changed: missing={missing}, extra={extra}"
        )
    for name, digest in expected.items():
        if hashlib.sha256(actual[name].read_bytes()).hexdigest() != digest:
            raise ValueError(f"Generated content changed: {name}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--manifest", required=True, type=Path)
    args = parser.parse_args()
    expected = read_manifest(args.manifest)

    from spconv.gencode.__main__ import main as generate

    with tempfile.TemporaryDirectory(prefix="spconv-codegen-") as directory:
        root = Path(directory)
        generate(str(root / "include"), str(root / "src"), inference_only=True)
        validate_tree(root, expected)
        for name in expected:
            target = args.output / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(root / name, target)


if __name__ == "__main__":
    main()
