#!/usr/bin/env python3
"""Generate pinned inference-only spconv sources in an isolated environment."""

import argparse
import importlib.metadata
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

VERSIONS = json.loads((Path(__file__).resolve().parent / "versions.json").read_text())


def revision(path):
    return subprocess.check_output(
        ["git", "-C", str(path), "rev-parse", "HEAD"], text=True
    ).strip()


def prepare(arguments):
    if os.geteuid() == 0:
        raise RuntimeError("run source preparation as a non-root user")
    os.environ["CUMM_DISABLE_JIT"] = "1"
    os.environ["SPCONV_DISABLE_JIT"] = "1"
    if revision(arguments.spconv) != VERSIONS["spconv_commit"]:
        raise RuntimeError("spconv checkout must be v2.3.8 at the pinned commit")
    if revision(arguments.cumm) != VERSIONS["cumm_commit"]:
        raise RuntimeError("cumm checkout must be v0.7.11 at the pinned commit")
    for name in ("spconv", "cumm"):
        expected = VERSIONS[name + "_version"]
        importlib.import_module(name)
        module = sys.modules[name]
        version = getattr(module, "__version__", None)
        if version != expected:
            raise RuntimeError(f"{name}: expected {expected}, got {version}")
    output = arguments.output.resolve()
    if output.exists():
        raise RuntimeError(f"output already exists; preserve it: {output}")
    output.mkdir(parents=True)
    cumm = output / "cumm"
    cumm.mkdir()
    shutil.copytree(arguments.cumm / "include", cumm / "include", symlinks=False)
    for source, destination in [
        (arguments.spconv, output / "spconv"),
        (arguments.cumm, cumm),
    ]:
        destination.mkdir(exist_ok=True)
        shutil.copy2(source / "LICENSE", destination / "LICENSE")
    environment = dict(os.environ)
    environment.update(
        CUMM_DISABLE_JIT="1",
        SPCONV_DISABLE_JIT="1",
        CUMM_CUDA_ARCH_LIST=arguments.cuda_arch,
        CUMM_CUDA_VERSION=arguments.cuda_version,
        CUMM_INCLUDE_PATH=str(cumm / "include"),
    )
    subprocess.run(
        [
            sys.executable,
            "-m",
            "spconv.gencode",
            f"--include={output / 'spconv/include'}",
            f"--src={output / 'spconv/src'}",
            "--inference_only=True",
        ],
        env=environment,
        check=True,
    )
    manifest = {
        "spconv_commit": VERSIONS["spconv_commit"],
        "cumm_commit": VERSIONS["cumm_commit"],
        "inference_only": True,
        "cuda_arch": arguments.cuda_arch,
        "cuda_version": arguments.cuda_version,
        "python": sys.version,
        "generator_packages": {
            name: importlib.metadata.version(name)
            for name in ["pccm", "ccimport", "numpy", "sympy"]
        },
    }
    (output / "spconv-source.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Source ready: --repo_env=SPCONV_SOURCE_ROOT={output}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--spconv", type=Path, required=True)
    parser.add_argument("--cumm", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--cuda-arch", required=True)
    parser.add_argument("--cuda-version", required=True)
    prepare(parser.parse_args())
