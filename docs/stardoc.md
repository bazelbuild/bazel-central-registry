# Starlark API Documentation

Modules that expose Starlark APIs (rulesets, for example) may choose to publish documentation as a reference URL on releases.

Read more about this feature: https://blog.aspect.build/stardocs-on-bcr

## Generating API docs

The built-in rule [starlark_doc_extract](https://bazel.build/versions/8.3.0/reference/be/general#starlark_doc_extract) outputs `.binaryproto` files containing `stardoc_output.ModuleInfo` messages.

- Source: https://github.com/bazelbuild/bazel/blob/master/src/main/protobuf/stardoc_output.proto
- Docs: https://buf.build/bazel/bazel/docs/main:stardoc_output#stardoc_output.ModuleInfo

Authors are free to generate these files however they choose.
The simplest option is to add a `starlark_doc_extract` target for each `bzl_library` target you wish to document.

Note that the `bzl_library` rule from `bazel_skylib` has `filegroup` semantics - it doesn't produce any outputs, nor verify that the `bzl_library` has all dependencies provided.
See https://github.com/bazel-contrib/bazel-lib/blob/main/bzl_library.bzl for an alternative that fixes this. 

It is wise to run `bazel query 'kind(starlark_doc_extract, //...)'` to confirm which starlark modules your ruleset documents.

## Creating the docs artifact

Users of the Publish-to-BCR workflow have an existing `.github/workflows/release_prep.sh` script.
In this case you can simply add a snippet to create an archive file containing the stardoc output:

```bash
# Add generated API docs to the release, see https://github.com/bazelbuild/bazel-central-registry/issues/5593
docs="$(mktemp -d)"; targets="$(mktemp)"
bazel --output_base="$docs" query --output=label --output_file="$targets" 'kind("starlark_doc_extract rule", //...)'
bazel --output_base="$docs" build --target_pattern_file="$targets"
tar --create --auto-compress \
    --directory "$(bazel --output_base="$docs" info bazel-bin)" \
    --file "$GITHUB_WORKSPACE/${ARCHIVE%.tar.gz}.docs.tar.gz" .
```

> [!IMPORTANT]
> The `--output_file` flag was added in Bazel 7.5.0

Of course authors are free to produce the docs archive using a different technique.

## Publishing the docs

Again, we assume use of Publish-to-BCR.

Edit `.bcr/source.template.json` to include a link, such as

```json
{
    ...
    "docs_url": "https://github.com/{OWNER}/{REPO}/releases/download/{TAG}/{REPO}-{TAG}.docs.tar.gz",
}
```

> [!IMPORTANT]
> publish-to-bcr version v0.2.3 or greater is required to pick up a fix for multiple replacements in source.template.json

## Rendered docs

The https://registry.bazel.build site renders stardocs for modules that have published them.
The code for that site is in https://github.com/bazel-contrib/bcr-ui.
