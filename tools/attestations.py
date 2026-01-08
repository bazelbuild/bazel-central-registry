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
import dataclasses
import re


class Error(Exception):
    """
    Raised whenever we encounter a problem related to attestations.
    """


_VALID_MEDIA_TYPES = frozenset(["application/vnd.build.bazel.registry.attestation+json;version=1.0.0"])


@dataclasses.dataclass(frozen=True)
class Attestation:
    url: str
    integrity: str
    artifact_url_or_path: str


def parse_file(attestations_json, module_name, version, registry):
    _assert_is_dict_with_keys(attestations_json, ["mediaType", "attestations"])

    mediaType = attestations_json.get("mediaType")
    if mediaType not in _VALID_MEDIA_TYPES:
        raise Error(f"Invalid media type '{mediaType}'")

    source_url = registry.get_source(module_name, version)["url"]
    url_prefix, _, archive_basename = source_url.rpartition("/")

    full_locations = {
        "source.json": str(registry.get_source_json_path(module_name, version)),
        "MODULE.bazel": str(registry.get_module_dot_bazel_path(module_name, version)),
        archive_basename: source_url,
    }

    attestations_metadata = attestations_json.get("attestations")
    _assert_is_dict_with_keys(attestations_metadata, list(full_locations.keys()))

    attestations = []
    for basename, metadata in attestations_metadata.items():
        _assert_is_dict_with_keys(metadata, ["url", "integrity"])

        # verify_source_archive_url_match_github_repo in bcr_validation.py
        # already ensures that source_url points to the correct repository.
        # Consequently, we only need to check that all URLs start
        # with url_prefix.
        url = metadata["url"]
        # Basename can have an optional prefix since a GitHub release may
        # contain multiple modules (and thus attestation files).
        if not re.match(f"^{url_prefix}/[^/]*{basename}.intoto.jsonl$", url):
            raise Error(
                f"Expected url {url_prefix}/[prefix]{basename}.intoto.jsonl, but got {url} in {basename} attestation."
            )

        integrity = metadata["integrity"]
        if not integrity:
            raise Error(f"Missing `integrity` field for {basename} attestation.")

        attestations.append(
            Attestation(
                url=url,
                integrity=integrity,
                artifact_url_or_path=full_locations[basename],
            )
        )

    return attestations


def _assert_is_dict_with_keys(candidate, keys):
    def format(k):
        return ", ".join(k)

    if not isinstance(candidate, dict):
        raise Error("Expected a dictionary.")
    if set(keys).symmetric_difference(candidate.keys()):
        raise Error(f"Expected keys {format(keys)}, but got {format(candidate.keys())}.")
