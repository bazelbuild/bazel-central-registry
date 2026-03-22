"""Test rule to validate CcInfo provider for sed library.

This test ensures that sed's custom headers (like lib/stdlib.h, lib/stdio.h)
take precedence over system headers with the same names.
"""

load("@bazel_skylib//rules:build_test.bzl", "build_test")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

def _cc_header_validation_impl(ctx):
    """Validates that sed headers are properly exposed in CcInfo.

    This test checks that stdlib.h exists in one of the include directories
    from the compilation context, which ensures sed's custom headers are
    accessible with higher precedence than system headers.

    Args:
        ctx: The rule context

    Returns:
        DefaultInfo with test result file
    """
    target = ctx.attr.target
    cc_info = target[CcInfo]
    compilation_context = cc_info.compilation_context

    # Get includes (-I) directories from compilation context
    includes = compilation_context.includes.to_list()

    # Get all header files from the compilation context
    headers = compilation_context.headers.to_list()

    # Check if stdlib.h exists in any of the include directories
    stdlib_paths = []
    for header in headers:
        if header.path.endswith("/stdlib.h"):
            for inc in includes:
                if inc in header.path:
                    stdlib_paths.append(header.path)
                    break

    # Create output file with validation result
    output = ctx.actions.declare_file(ctx.label.name + ".result")

    if stdlib_paths:
        content = "PASS: Found stdlib.h in compilation context includes\n"
        content += "Path:\n"
        for stdlib_path in stdlib_paths:
            content += "  {}\n".format(stdlib_path)
        content += "Includes directories:\n"
        for include in includes:
            content += "  {}\n".format(include)
        content += "\nThis ensures sed's custom headers (stdlib.h, etc.) "
        content += "are accessible and take precedence over system headers.\n"
    else:
        content = "FAIL: stdlib.h not found in compilation context includes\n"
        content += "Includes directories:\n"
        for include in includes:
            content += "  {}\n".format(include)
        content += "Available headers: {}\n".format([h.path for h in headers if "stdlib" in h.path])
        content += "\nThis means sed's headers may not be properly exposed or "
        content += "may be overridden by system headers.\n"
        fail(content)

    ctx.actions.write(
        output = output,
        content = content,
    )

    return [DefaultInfo(files = depset([output]))]

_cc_header_validation = rule(
    implementation = _cc_header_validation_impl,
    attrs = {
        "target": attr.label(
            mandatory = True,
            providers = [CcInfo],
            doc = "The cc_library target to validate",
        ),
    },
    doc = """Validates CcInfo compilation context for sed headers.

    This rule ensures that sed's custom headers are properly exposed through
    the CcInfo provider with the correct include paths, preventing system
    headers from overriding sed's custom implementations.
    """,
)

def cc_header_validation_test(name, target, **kwargs):
    """Creates a test that validates CcInfo compilation context.

    Args:
        name: Name of the test
        target: The cc_library target to validate
        **kwargs: Additional arguments passed to build_test
    """
    validation_name = name + "_validation"

    _cc_header_validation(
        name = validation_name,
        target = target,
        tags = ["manual"],
    )

    build_test(
        name = name,
        targets = [validation_name],
        **kwargs
    )
