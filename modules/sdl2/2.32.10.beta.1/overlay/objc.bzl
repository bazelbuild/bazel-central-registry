# objc.bzl

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_test.bzl", "cc_test")

def _objc_rename_impl(ctx):
    outputs = []
    package_path = ctx.label.package

    for f in ctx.files.srcs:
        if f.extension in ["m", "mm"]:
            # Calculate relative path to the package to support Bzlmod and subdirectories
            short_path = f.short_path
            if package_path == "":
                rel_path = short_path.split("/")[-1] if "/" in short_path and "~" in short_path else short_path
            else:
                search_str = package_path + "/"
                index = short_path.find(search_str)
                if index != -1:
                    rel_path = short_path[index + len(search_str):]
                else:
                    rel_path = f.basename

            ext = ".c" if f.extension == "m" else ".cc"
            out = ctx.actions.declare_file(rel_path + ext)

            # Calculate include path relative to repo root
            include_path = f.path
            workspace_root = f.owner.workspace_root
            if workspace_root and include_path.startswith(workspace_root + "/"):
                include_path = include_path[len(workspace_root + "/"):]

            # Create a stub that includes the original source
            ctx.actions.write(
                output = out,
                content = '#include "%s"\n' % include_path,
            )
            outputs.append(out)

    return [DefaultInfo(files = depset(outputs))]

_objc_rename = rule(
    implementation = _objc_rename_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
    },
)

def _objc_common(name, rule_fn, srcs = [], hdrs = [], deps = [], copts = [], **kwargs):
    # Detect language type
    has_mm = False
    if type(srcs) == "list":
        has_mm = any([s.endswith(".mm") for s in srcs])
    lang = "objective-c++" if has_mm else "objective-c"

    # Generate stubs
    stub_name = name + "_stubs"
    _objc_rename(
        name = stub_name,
        srcs = srcs,
    )

    # Since cc_binary and cc_test do not support 'textual_hdrs',
    # we always wrap the compilation in a cc_library.
    impl_library_name = name + "_objc_impl"

    # Extract common attributes that apply to both library and binary/test
    common_attrs = {}
    if "testonly" in kwargs:
        common_attrs["testonly"] = kwargs["testonly"]
    if "tags" in kwargs:
        common_attrs["tags"] = kwargs["tags"]

    cc_library(
        name = impl_library_name,
        srcs = [":" + stub_name],
        # Original sources must be in textual_hdrs so the stub can include them
        textual_hdrs = srcs + hdrs,
        deps = deps,
        copts = copts + ["-x", lang, "-fobjc-arc"],
        visibility = ["//visibility:private"],
        **common_attrs
    )

    if rule_fn == cc_library:
        # If the user requested a library, we can just use an alias or
        # rename the implementation library. Here we use an alias-like approach.
        native.alias(
            name = name,
            actual = ":" + impl_library_name,
            visibility = kwargs.get("visibility"),
        )
    else:
        # For cc_binary and cc_test, depend on the internal library
        rule_fn(
            name = name,
            deps = [":" + impl_library_name],
            **kwargs
        )

def objc_library(name, **kwargs):
    _objc_common(name, cc_library, **kwargs)

def objc_binary(name, **kwargs):
    _objc_common(name, cc_binary, **kwargs)

def objc_test(name, **kwargs):
    _objc_common(name, cc_test, **kwargs)
