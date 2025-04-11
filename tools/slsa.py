#!/usr/bin/env python3
#
# Copyright 2025 The Bazel Authors. All rights reserved.
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
import attestations as attestations_lib
import base64
import collections
import hashlib
import json
import os
import platform
import re
import subprocess
import sys
import textwrap

from enum import Enum
from pathlib import Path

from registry import download
from registry import download_file
from registry import integrity_for_comparison


# TODO: Read these settings from a config file
_GH_RELEASE_BUILDER_ID = "https://github.com/bazel-contrib/.github/.github/workflows/release_ruleset.yaml"
_GH_PUBLISH_BUILDER_ID = "https://github.com/bazel-contrib/publish-to-bcr/.github/workflows/publish.yaml"
_VSA_VERIFIER_ID = "https://bcid.corp.google.com/verifier/bcid_package_enforcer/v0.1"
_VSA_VERIFIED_LEVEL = "SLSA_BUILD_LEVEL_2"
_VSA_KEY_ID = "keystore://76574:prod:vsa_signing_public_key"

# https://cloud.google.com/kubernetes-engine/docs/how-to/verify-control-plane-vm-integrity
_VSA_PUBLIC_KEY = textwrap.dedent(
    """\
    -----BEGIN PUBLIC KEY-----
    MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEeGa6ZCZn0q6WpaUwJrSk+PPYEsca
    3Xkk3UrxvbQtoZzTmq0zIYq+4QQl0YBedSyy+XcwAMaUWTouTrB05WhYtg==
    -----END PUBLIC KEY-----"""
)

_PREDICATE_RE = re.compile(r"^https://slsa.dev/(provenance|verification_summary)/v\d+(\.\d+)?$")


class PredicateType(Enum):
    INVALID = 1
    PROVENANCE = 2
    VSA = 3


def validate_predicate_type(value):
    m = _PREDICATE_RE.match(value)
    if not m:
        return PredicateType.INVALID

    return PredicateType.PROVENANCE if m.group(1) == "provenance" else PredicateType.VSA


class Verifier:
    _URL_TEMPLATE = (
        "https://github.com/slsa-framework/slsa-verifier/releases/download/{version}/slsa-verifier-{os}-{arch}{ext}"
    )
    _SHA256SUM_URL = "https://raw.githubusercontent.com/slsa-framework/slsa-verifier/refs/heads/main/SHA256SUM.md"
    _PROTOCOL_RE = re.compile(r"^http(s)?://")

    def __init__(self, version, download_dir):
        self._version = version

        root = Path(download_dir)
        self._executable = root / f"slsa-verifier{self._get_binary_extension()}"
        self._vsa_key_path = root / "key.pem"

    def _get_binary_extension(self):
        return ".exe" if platform.system().lower() == "windows" else ""

    def run(self, attestation, source_uri, source_tag, tmp_dir):
        self._download_binary_if_necessary()

        attestation_basename = os.path.basename(attestation.url)
        raw_attestation = download(attestation.url)
        actual_integrity = integrity_for_comparison(raw_attestation, attestation.integrity)
        if actual_integrity != attestation.integrity:
            raise attestations_lib.Error(
                f"{attestation_basename} has expected integrity `{attestation.integrity}`, "
                f"but the actual value is `{actual_integrity}`."
            )

        attestation_path = os.path.join(tmp_dir, attestation_basename)
        with open(attestation_path, "wb") as f:
            f.write(raw_attestation)

        actual_types = self._read_attestation_types(attestation_basename, raw_attestation)
        predicate_type = self._evaluate_attestation_types(attestation_basename, actual_types)

        cmd, args = self._get_args(
            predicate_type,
            attestation_path,
            source_uri,
            source_tag,
            attestation.artifact_url_or_path,
            tmp_dir,
        )
        eprint(self.format_cmd(cmd, args))

        result = subprocess.run(
            [self._executable, cmd] + args,
            capture_output=True,
            encoding="utf-8",
            # TODO(fweikert): remove once GH attestation support is stable.
            env={"SLSA_VERIFIER_EXPERIMENTAL": "1", **os.environ},
        )

        if result.returncode:
            raise attestations_lib.Error(
                "\n".join(
                    [
                        f"SLSA verifier failed for {attestation_basename}:",
                        f"\t{result.stderr}",
                    ]
                )
            )

        eprint(f"Result:\n\t{result.stdout}")

    def _download_binary_if_necessary(self):
        if self._executable.exists():
            return

        url = self._get_url()
        raw_content = download(url)

        # TODO(fweikert): Re-enable once we use a stable release.
        # self._check_sha256sum(raw_content, os.path.basename(url))

        with open(self._executable, "wb") as f:
            f.write(raw_content)

        os.chmod(self._executable, 0o755)

    def _get_url(self):
        osname = platform.system().lower()
        m = platform.machine()
        arch = m if m == "arm64" else "amd64"
        return self._URL_TEMPLATE.format(version=self._version, os=osname, arch=arch, ext=self._get_binary_extension())

    def _check_sha256sum(self, raw_content, binary_name):
        actual_hash = hashlib.sha256(raw_content).hexdigest()
        pattern = re.compile(rf"^{actual_hash}\s+{binary_name}$", re.MULTILINE)

        sha256sums = download(self._SHA256SUM_URL).decode("utf-8")

        # Unfortunately the file contains Markdown.
        needle = f"[{self._version}]"
        for version_block in sha256sums.split("###"):
            if needle in version_block:
                if pattern.search(version_block):
                    return
                break

        raise attestations_lib.Error(
            f"{binary_name}@{self._version}: " f"could not find actual checksum {actual_hash} in {self._SHA256SUM_URL}."
        )

    def _read_attestation_types(self, basename, raw_attestation):
        def parse(pos, line):
            try:
                data = json.loads(line)
                raw_payload = (data.get("dsseEnvelope") or data).get("payload")
                payload = json.loads(base64.b64decode(raw_payload))
                return payload.get("predicateType")
            except Exception as ex:
                raise attestations_lib.Error(f"Error in {basename}:{pos}: {ex}.") from ex

        lines = [l for l in raw_attestation.split(b"\n") if l]
        return [parse(p, l) for p, l in enumerate(lines)]

    def _evaluate_attestation_types(self, basename, actual_types):
        if not actual_types:
            raise attestations_lib.Error(f"{basename} does not contain any attestations.")

        by_type = self._partition(actual_types)
        invalid = by_type.get(PredicateType.INVALID)
        if invalid:
            raise attestations_lib.Error(f"{basename} contains invalid attestation type(s): {', '.join(invalid)}.")

        # TODO: check if attestation_type matches a globally defined allowlist?

        if len(by_type) > 1:
            raise attestations_lib.Error(f"{basename} must contain either SLSA provenances or VSAs, not both.")

        # TODO: which one to return if there are multiple?
        return list(by_type.keys())[0]

    def _partition(self, attestation_types):
        result = collections.defaultdict(set)
        for at in attestation_types:
            result[validate_predicate_type(at)].add(at)

        return result

    def _get_args(self, validated_type, attestation_path, source_uri, source_tag, artifact_url_or_path, tmp_dir):
        fname = "_get_vsa_args" if validated_type == PredicateType.VSA else "_get_github_att_args"
        return getattr(self, fname)(attestation_path, source_uri, source_tag, artifact_url_or_path, tmp_dir)

    def _get_github_att_args(self, attestation_path, source_uri, source_tag, artifact_url_or_path, tmp_dir):
        artifact_path = self._download_artifact_if_required(artifact_url_or_path, tmp_dir)
        args = [
            "--attestation-path",
            attestation_path,
            "--source-uri",
            source_uri,
            "--builder-id",
            self._get_builder_id(artifact_path),
            artifact_path,
        ]
        return "verify-github-attestation", args

    def _download_artifact_if_required(self, url_or_path, tmp_dir):
        if not self._PROTOCOL_RE.match(url_or_path):
            return url_or_path

        dest = os.path.join(tmp_dir, os.path.basename(url_or_path))
        download_file(url_or_path, dest)
        return dest

    def _get_builder_id(self, artifact_path):
        base = os.path.basename(artifact_path)
        if base == "MODULE.bazel" or base == "source.json":
            return _GH_PUBLISH_BUILDER_ID

        return _GH_RELEASE_BUILDER_ID

    def _get_vsa_args(self, attestation_path, source_uri, source_tag, artifact_url_or_path, tmp_dir):
        self._ensure_vsa_key_exists()
        artifact_digest = hashlib.sha256(self._read_url_or_file(artifact_url_or_path)).hexdigest()
        args = [
            "--subject-digest",
            artifact_digest,
            "--attestation-path",
            attestation_path,
            "--verifier-id",
            _VSA_VERIFIER_ID,
            "--resource-uri",
            source_uri,
            "--verified-level",
            _VSA_VERIFIED_LEVEL,
            "--public-key-path",
            self._vsa_key_path,
            "--public-key-id",
            _VSA_KEY_ID,
        ]
        return "verify-vsa", args

    def _ensure_vsa_key_exists(self):
        if self._vsa_key_path.exists():
            return

        with open(self._vsa_key_path, "wt") as f:
            f.write(_VSA_PUBLIC_KEY)

    def _read_url_or_file(self, url_or_path):
        if self._PROTOCOL_RE.match(url_or_path):
            return download(url_or_path)

        with open(url_or_path, "rb") as f:
            return f.read()

    def format_cmd(self, cmd, args):
        parts = [f"slsa-verifier {cmd}"]

        i = 0
        while i < len(args):
            value = args[i]
            if value.startswith("--"):
                parts.append(f"\t{value} {args[i+1]}")
                i += 1
            else:
                parts.append(f"\t{value}")

            i += 1

        return " \\\n".join(parts)


def eprint(*args, **kwargs):
    """
    Print to stderr and flush (just in case).
    """
    print(*args, flush=True, file=sys.stderr, **kwargs)
