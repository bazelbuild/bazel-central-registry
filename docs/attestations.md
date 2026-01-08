# Attestations

> [!CAUTION]
> This feature is still experimental.

## Introduction

BCR now accepts build attestations in order to increase security for all BCR users.
This feature is still experimental and thus optional, but eventually we expect all
modules that natively build with Bazel to also generate build attestation.

## How it works

BCR presubmit verifies attestations if an incoming PR for a new module (version) contains an `attestations.json` file next to `source.json` and `MODULE.bazel`.
Its format looks like this:

```
{
  "mediaType": "application/vnd.build.bazel.registry.attestation+json;version=1.0.0",
  "attestations" {
    "source.json": {
      "url": "https://github.com/some-org/some-repo/releases/download/v1.0.0/source.json.intoto.jsonl",
      "integrity": "sha256-NylZt7S5lfmT0VjMvzXwafpjIqoaWDkgaml5VrmdW/A=",
    },
    "MODULE.bazel": {
      "url": "https://github.com/some-org/some-repo/releases/download/v1.0.0/optionalPrefix-MODULE.bazel.intoto.jsonl",
      "integrity": "sha256-NylZt7S5lfmT0VjMvzXwafpjIqoaWDkgaml5VrmdW/A=",
    },
    "project.tar.gz": {
      "url": "https://github.com/some-org/some-repo/releases/download/v1.0.0/project.tar.gz.intoto.jsonl",
      "integrity": "sha256-NylZt7S5lfmT0VjMvzXwafpjIqoaWDkgaml5VrmdW/A=",
    },
  }
}
```

Rules:

1. `attestations` must contain exactly three elements, with keys being `source.json`, `MODULE.bazel` and the basename of the source archive.
2. All URLs in this file must point to the GitHub repository specified in `metadata.json`.
3. All `*.intoto.jsonl` attestations referenced in this file must live in the same directory.
4. Attestations are either plain DSEE or Sigstore Bundles, and their signatures can be verified by [slsa-verifier](https://github.com/slsa-framework/slsa-verifier)

Attestations are checked with [slsa-verifier](https://github.com/slsa-framework/slsa-verifier) during presubmit.
Once the PR has been merged, `MODULE.bazel.intoto.json` and `source.json.intoto.jsonl` will be mirrored to https://registry.bazel.build/.

## Tools

You can verify attestations locally by running [bcr_validation.py](README.md#validations).

## Future Work

- Extensive testing of pre- and post-submit with real attestations (SLSA provenance and VSAs).
- Adding a visual indicator to the BCR web UI to indicate the presence of attestations.
- Launching a GitHub action that handles attestation creation and publishing.
- Eventually enforcing attestations for all new module versions (this will only happen after several announcements and a migration period).
