_use_languages_tag = tag_class(
    attrs = {
        "cc": attr.bool(default = False),
        "csharp": attr.bool(default = False),
        "gapic": attr.bool(default = False),
        "go": attr.bool(default = False),
        "go_test": attr.bool(default = False),
        "grpc": attr.bool(default = False),
        "java": attr.bool(default = False),
        "nodejs": attr.bool(default = False),
        "php": attr.bool(default = False),
        "python": attr.bool(default = False),
        "ruby": attr.bool(default = False),
    },
)

def _switched_rules_impl(_ctx):
    fail("""
The 'switched_rules' extension is no longer supported due to problems inherent to its design.
Instead, add 'bazel_dep(name = "googleapis-<lang>", version = "1.0.0")' to your MODULE.bazel file to use '<lang>_proto_library' targets in 'googleapis'.
To see error messages with the exact 'bazel_dep's to add, remove the 'switched_rules' usage and build your project.
The available individual modules can be found at https://registry.bazel.build/search?q=googleapis.
""")

switched_rules = module_extension(
    implementation = _switched_rules_impl,
    tag_classes = {
        "use_languages": _use_languages_tag,
    },
)
