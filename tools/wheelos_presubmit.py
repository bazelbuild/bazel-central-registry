#!/usr/bin/env python3
"""Validate a private registry entry and run its Ubuntu 22.04 consumers."""

import argparse
import json
import os
import re
import shutil
import subprocess
import tempfile
from dataclasses import dataclass
from pathlib import Path

import bcr_presubmit
import jsonschema
import yaml
from bcr_validation import BcrValidator
from registry import RegistryClient


def validation_exceptions(source_url):
    exceptions = ["presubmit_yml"]
    if isinstance(source_url, str) and re.fullmatch(
        r"https://github\.com/[\w.-]+/[\w.-]+/archive/"
        r"(?:[0-9a-f]{40}|refs/tags/v?\d+\.\d+\.\d+)\.(?:tar\.gz|zip)",
        source_url,
    ):
        exceptions.append("url_stability")
    return exceptions


@dataclass
class BaselineModule:
    version: str
    document: dict | None

    def attestations(self):
        return self.document


class GitRegistryBaseline:
    def __init__(self, root, revision):
        self.root = root
        self.revision = revision

    def read_json(self, path):
        command = ["git", "-C", str(self.root)]
        if not subprocess.check_output(
            [*command, "ls-tree", "--name-only", self.revision, "--", path]
        ):
            return None
        return json.loads(
            subprocess.check_output([*command, "show", f"{self.revision}:{path}"])
        )

    def get_latest_module_version(self, name):
        metadata = self.read_json(f"modules/{name}/metadata.json")
        if metadata is None:
            return None
        version = metadata["versions"][-1]
        return BaselineModule(
            version, self.read_json(f"modules/{name}/{version}/attestations.json")
        )


def prepare_test_module(anonymous, destination, name, spec, version, bazel):
    environment = dict(os.environ, USE_BAZEL_VERSION=version)
    command = [bazel, "--batch", "--nosystem_rc", "--nohome_rc"]
    mapping = json.loads(
        subprocess.check_output(
            [*command, "mod", "dump_repo_mapping", ""],
            cwd=anonymous,
            env=environment,
            text=True,
        )
    )
    output_base = subprocess.check_output(
        [*command, "info", "output_base"],
        cwd=anonymous,
        env=environment,
        text=True,
    ).strip()
    source = Path(output_base) / "external" / mapping[name]
    shutil.copytree(source, destination, symlinks=True)
    test_root = (destination / spec["module_path"]).resolve()
    if not test_root.is_relative_to(destination.resolve()):
        raise ValueError(f"Test module must be inside fetched source: {test_root}")
    if not (test_root / "MODULE.bazel").is_file():
        raise ValueError(f"Missing test module in fetched source: {test_root}")
    with (test_root / ".bazelrc").open("a") as rc:
        rc.write("\ncommon --enable_bzlmod\n")
        rc.write(f"common --registry={bcr_presubmit.BCR_REPO_DIR.as_uri()}\n")
    return test_root


def run_tasks(root, tasks, version, bazel, cache):
    selected = [
        task
        for task in tasks.values()
        if task["platform"] == "ubuntu2204"
        and (task["bazel"] == version or task["bazel"] == version.split(".")[0] + ".x")
    ]
    if not selected:
        raise ValueError(f"No Ubuntu 22.04 consumer task for Bazel {version}.")
    with (root / ".bazelrc").open("a") as rc:
        rc.write("\ncommon --registry=https://bcr.wheelos.cn\n")
        rc.write("common --registry=https://bcr.bazel.build\n")
        rc.write(f"\ncommon --repository_cache={cache / 'repo_cache'}\n")
        rc.write(f"build --disk_cache={cache / 'disk_cache'}\n")
        rc.write("common --lockfile_mode=off\ncommon --announce_rc\n")
    environment = dict(os.environ, USE_BAZEL_VERSION=version)
    for task in selected:
        print(
            f"Consumer: {task.get('name', 'verify targets')} / Bazel {version}",
            flush=True,
        )
        if not task.get("build_targets") and not task.get("test_targets"):
            raise ValueError("A consumer task must build or test targets.")
        for action in ("build", "test"):
            targets = task.get(f"{action}_targets", [])
            if not targets:
                continue
            flags = task.get("build_flags", [])
            if action == "test":
                flags = [
                    *flags,
                    *task.get("test_flags", []),
                    "--flaky_test_attempts=1",
                    "--test_output=errors",
                ]
            subprocess.run(
                [
                    bazel,
                    "--batch",
                    "--nosystem_rc",
                    "--nohome_rc",
                    action,
                    *flags,
                    "--",
                    *targets,
                ],
                cwd=root,
                env=environment,
                check=True,
            )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--module", required=True, help="name@version")
    parser.add_argument("--bazel-version", required=True)
    parser.add_argument("--bazel", default="bazelisk")
    parser.add_argument("--base", default="HEAD", help="Previous registry commit")
    parser.add_argument("--cache", type=Path, default=Path.home() / ".cache/bazel")
    args = parser.parse_args()
    if os.geteuid() == 0:
        parser.error("Run registry consumers as a non-root user.")
    name, version = args.module.split("@")
    root = Path(
        os.environ.get("BUILD_WORKSPACE_DIRECTORY", Path(__file__).resolve().parents[1])
    )
    registry = RegistryClient(root)
    schema = json.loads((root / "metadata.schema.json").read_text())
    jsonschema.validate(registry.get_metadata(name), schema)
    validator = BcrValidator(
        registry, upstream=GitRegistryBaseline(root, args.base), should_fix=False
    )
    source_path = root / "modules" / name / version / "source.json"
    source = json.loads(source_path.read_text())
    exceptions = validation_exceptions(source.get("url"))
    if "url_stability" in exceptions:
        print(
            "Accepting checksummed commit or version-tag GitHub archive; "
            "URL byte-stability classification waived.",
            flush=True,
        )
    # This fork uses PR review and accepts checksummed commit/version-tag archives.
    # Integrity, patched MODULE consistency, tasks and attestations remain required.
    validator.validate_module(name, version, exceptions)
    if validator.getValidationReturnCode() != 0:
        return validator.getValidationReturnCode()
    bcr_presubmit.BCR_REPO_DIR = root
    with tempfile.TemporaryDirectory(prefix="wheelos-presubmit-") as directory:
        anonymous = Path(directory) / "anonymous_module"
        anonymous.mkdir()
        bcr_presubmit.create_anonymous_repo(name, version, anonymous)
        config = bcr_presubmit.get_anonymous_module_task_config(name, version)
        run_tasks(
            anonymous, config["tasks"], args.bazel_version, args.bazel, args.cache
        )
        config = bcr_presubmit.get_test_module_task_config(name, version)
        if config.get("tasks"):
            spec = yaml.safe_load(
                (root / "modules" / name / version / "presubmit.yml").read_text()
            )
            test_root = prepare_test_module(
                anonymous,
                Path(directory) / "module_src",
                name,
                spec["bcr_test_module"],
                args.bazel_version,
                args.bazel,
            )
            run_tasks(
                Path(test_root),
                config["tasks"],
                args.bazel_version,
                args.bazel,
                args.cache,
            )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
