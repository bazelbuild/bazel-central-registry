"""Compile explicitly prepared, pinned spconv inference sources."""

def _spconv_source_repository_impl(ctx):
    root = ctx.getenv("SPCONV_SOURCE_ROOT", "")
    if not root:
        fail("Set --repo_env=SPCONV_SOURCE_ROOT to a prepared inference source tree; see @spconv//:README.bazel.md.")
    root = ctx.path(root)
    for path in [
        "spconv/include/spconvlib/spconv/csrc/sparse/all/SpconvOps.h",
        "spconv/src",
        "spconv/LICENSE",
        "cumm/include/tensorview/tensor.h",
        "cumm/LICENSE",
        "spconv-source.json",
    ]:
        if not root.get_child(path).exists:
            fail("Incomplete generated spconv source tree: {}".format(root.get_child(path)))
    versions = json.decode(ctx.read(ctx.attr.versions))
    manifest = json.decode(ctx.read(root.get_child("spconv-source.json")))
    for name in ["spconv_commit", "cumm_commit"]:
        if manifest.get(name) != versions[name]:
            fail("Unsupported {} in spconv source provenance".format(name))
    if manifest.get("inference_only") != True:
        fail("spconv source must be generated with inference_only=True")
    for project in ["spconv", "cumm"]:
        ctx.symlink(root.get_child(project), project)
        ctx.symlink(root.get_child(project + "/LICENSE"), project.upper() + "-LICENSE")
    ctx.file("BUILD.bazel", ctx.read(ctx.attr.build_file))

spconv_source_repository = repository_rule(
    implementation = _spconv_source_repository_impl,
    attrs = {
        "build_file": attr.label(default = "//bazel:source.BUILD"),
        "versions": attr.label(default = "//bazel:versions.json"),
    },
    environ = ["SPCONV_SOURCE_ROOT"],
    local = True,
    configure = True,
)
