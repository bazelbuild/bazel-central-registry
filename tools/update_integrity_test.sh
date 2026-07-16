#!/bin/bash

set -euo pipefail

# Set up a registry that needs some update_integrity treatment
foomod="${TEST_TMPDIR}/registry/modules/foomod"
mkdir -p "${foomod}/1.2.3/patches"
mkdir -p "${foomod}/1.2.3/overlay"
cat <<"EOF" >"${foomod}/metadata.json"
{
  "homepage": "https://example.com/",
  "maintainers": [{"email": "bcr-maintainers@bazel.build", "name": "No Maintainer Specified"}],
  "repository": ["github:luben/zstd-jni"],
  "versions": [],
  "yanked_versions": {}
}
EOF
echo 'module(name = "foomod", version = "1.2.3")' >"${foomod}/1.2.3/MODULE.bazel"
echo hello >"${foomod}/1.2.3/overlay/overlay.file"
echo old >"${foomod}/1.2.3/patches/preexisting-1.patch"
echo old >"${foomod}/1.2.3/patches/preexisting-2.patch"
echo new >"${foomod}/1.2.3/patches/a-newly-added.patch"
cat <<"EOF" >"${foomod}/1.2.3/source.json"
{
    "url": "file:///dev/null",
    "integrity": "not-a-real-integrity-hash",
    "strip_prefix": "foomod-1.2.3",
    "overlay": {"overlay.file": "outdated-sha", "removed-overlay": "outdated-sha"},
    "patches": {
        "preexisting-1.patch": "sha256-AdCdGcITmkauv7V3eA0SPXOW6XIBvH6tIQouv/gjne4=",
        "preexisting-2.patch": "sha256-AdCdGcITmkauv7V3eA0SPXOW6XIBvH6tIQouv/gjne4="
        },
    "patch_strip": 1
}
EOF

# Run the update_integrity tool
tools/update_integrity --registry="${TEST_TMPDIR}/registry" foomod

# Check that the tool did the right thing
diff -u - "${foomod}/1.2.3/source.json" <<<'{
    "url": "file:///dev/null",
    "integrity": "sha256-47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=",
    "strip_prefix": "foomod-1.2.3",
    "overlay": {
        "overlay.file": "sha256-WJG1tSLV3whtD/CxEPvZ0hu0/HFjrzTQgoai6Eb2vgM="
    },
    "patches": {
        "preexisting-1.patch": "sha256-AdCdGcITmkauv7V3eA0SPXOW6XIBvH6tIQouv/gjne4=",
        "preexisting-2.patch": "sha256-AdCdGcITmkauv7V3eA0SPXOW6XIBvH6tIQouv/gjne4=",
        "a-newly-added.patch": "sha256-eqelNZFz0Ftjz9aC48OEh/PLT38dYGWf5Z+rFQWXfUw="
    },
    "patch_strip": 1
}'
diff -u - "${foomod}/metadata.json" <<<'{
    "homepage": "https://example.com/",
    "maintainers": [
        {
            "email": "bcr-maintainers@bazel.build",
            "name": "No Maintainer Specified"
        }
    ],
    "repository": [
        "github:luben/zstd-jni"
    ],
    "versions": [
        "1.2.3"
    ],
    "yanked_versions": {}
}'
