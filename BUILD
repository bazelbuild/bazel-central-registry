load("@npm//tools:ajv-cli/package_json.bzl", ajv = "bin")

_METADATA_FILES = glob(["modules/*/metadata.json"])

[
    ajv.ajv_test(
        name = "test_metadata." + s.removesuffix("/metadata.json"),
        args = [
            "validate",
            "-s",
            "$(execpath metadata.schema.json)",
            "-d",
            "$(execpath %s)" % s,
        ],
        data = [
            s,
            "metadata.schema.json",
        ],
    )
    for s in _METADATA_FILES
]
