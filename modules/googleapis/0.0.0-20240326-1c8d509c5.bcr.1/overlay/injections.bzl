_INJECT_ATTRS = {
    "rules_cc": attr.label(),
    "rules_java": attr.label(),
    "rules_python": attr.label(),
    "rules_go": attr.label(),
    "grpc": attr.label(),
    "grpc_java": attr.label(),
}

_NATIVE = "native"
_DEV_DEP = "dev_dep"

_INJECTABLE_RULES = {
    # Common
    "proto_library_with_info": _DEV_DEP,
    "moved_proto_library": _DEV_DEP,
    # Java
    "java_proto_library": _NATIVE,
    "java_grpc_library": ("grpc_java", "//:java_grpc_library.bzl"),
    "java_gapic_library": _DEV_DEP,
    "java_gapic_test": _DEV_DEP,
    "java_gapic_assembly_gradle_pkg": _DEV_DEP,
    # Python
    "py_proto_library": ("grpc", "//bazel:python_rules.bzl"),
    "py_grpc_library": ("grpc", "//bazel:python_rules.bzl"),
    "py_gapic_library": _DEV_DEP,
    "py_test": _DEV_DEP,
    "py_gapic_assembly_pkg": _DEV_DEP,
    "py_import": ("rules_python", "//python:defs.bzl"),
    # Go
    "go_proto_library": ("rules_go", "//proto:def.bzl"),
    "go_grpc_library": ("rules_go", "//proto:def.bzl"),
    "go_library": ("rules_go", "//go:def.bzl"),
    "go_test": _DEV_DEP,
    "go_gapic_library": _DEV_DEP,
    "go_gapic_assembly_pkg": _DEV_DEP,
    # C++
    "cc_proto_library": _NATIVE,
    "cc_grpc_library": ("grpc", "//bazel:cc_grpc_library.bzl"),
    "cc_gapic_library": _DEV_DEP,
    # PHP
    "php_proto_library": _DEV_DEP,
    "php_grpc_library": _DEV_DEP,
    "php_gapic_library": _DEV_DEP,
    "php_gapic_assembly_pkg": _DEV_DEP,
    # Node.js
    "nodejs_gapic_library": _DEV_DEP,
    "nodejs_gapic_assembly_pkg": _DEV_DEP,
    # Ruby
    "ruby_proto_library": _DEV_DEP,
    "ruby_grpc_library": _DEV_DEP,
    "ruby_ads_gapic_library": _DEV_DEP,
    "ruby_cloud_gapic_library": _DEV_DEP,
    "ruby_gapic_assembly_pkg": _DEV_DEP,
    # C#
    "csharp_proto_library": _DEV_DEP,
    "csharp_grpc_library": _DEV_DEP,
    "csharp_gapic_library": _DEV_DEP,
    "csharp_gapic_assembly_pkg": _DEV_DEP,
}

def _imports_repo_impl(rctx):
    loads = []
    rules = []

    for rule_name, source in _INJECTABLE_RULES.items():
        if source == _NATIVE:
            rules.append("%s = native.%s" % (rule_name, rule_name))
        elif source == _DEV_DEP:
            if rctx.attr.inject_dev_deps:
                loads.append("load('@com_google_googleapis//:dev_dep_imports.bzl', _%s='%s')" % (rule_name, rule_name))
                rules.append("%s = _%s" % (rule_name, rule_name))
            else:
                rules.append("def %s(**kwargs): pass" % rule_name)
        else:
            repo, label_remainder = source
            injected_label = getattr(rctx.attr, repo)
            if injected_label == None:
                rules.append("def %s(**kwargs): pass" % rule_name)
            else:
                loads.append("load('@@%s%s', _%s='%s')" % (injected_label.repo_name, label_remainder, rule_name, rule_name))
                rules.append("%s = _%s" % (rule_name, rule_name))

    rctx.file("BUILD.bazel")
    rctx.file("imports.bzl", "\n".join(loads + rules))

imports_repo = repository_rule(
    implementation = _imports_repo_impl,
    attrs = _INJECT_ATTRS | {
        "inject_dev_deps": attr.bool(),
    },
)

def _injections_impl(mctx):
    attrs = {k: None for k in _INJECT_ATTRS}
    inject_dev_deps = False

    for module in mctx.modules:
        if module.is_root and module.name == "googleapis":
            inject_dev_deps = True
        if len(module.tags.inject) == 0:
            continue
        if len(module.tags.inject) > 1:
            fail("Multiple `inject` tags set by the module %s@%s. Only one `inject` tag may be set by each module." % (module.name, module.version))
        attrs = {k: v or getattr(module.tags.inject[0], k, None) for k, v in attrs.items()}

    imports_repo(
        name = "com_google_googleapis_imports",
        inject_dev_deps = inject_dev_deps,
        **attrs,
    )

    return mctx.extension_metadata(reproducible = True)

injections = module_extension(
    implementation = _injections_impl,
    tag_classes = {"inject": tag_class(attrs = _INJECT_ATTRS)},
)
