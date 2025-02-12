import dataclasses


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
        expected_url = f"{url_prefix}/{basename}.intoto.jsonl"
        url = metadata["url"]
        if url != expected_url:
            raise Error(f"Expected url {expected_url}, but got {url} in {basename} attestation.")

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
