"""The install layout as build settings.

configure bakes the install directories into GRUB twice over: as
`AC_DEFINE_UNQUOTED`s the programs read (GRUB_LIBDIR tells grub-install where
the platform modules are, configure.ac:2041) and as `@bindir@`-style
substitutions in the shell scripts (`config.status --file`).  A build
setting's value is not known when `autoconf` checks are declared, so the
defines travel as `-D`s instead: `local_defines` is subject to "Make" variable
expansion, and a target in `toolchains` can supply variables through
`TemplateVariableInfo`.  `install_dirs` bridges a `string_flag` into that, and
`configure_script` is `config.status --file` with the same settings.
"""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

visibility("private")

def _install_dirs_impl(ctx):
    return [platform_common.TemplateVariableInfo({
        variable: setting[BuildSettingInfo].value
        for setting, variable in ctx.attr.settings.items()
    })]

install_dirs = rule(
    doc = "Publishes each string build setting as the named \"Make\" variable.",
    implementation = _install_dirs_impl,
    attrs = {
        "settings": attr.label_keyed_string_dict(
            doc = "Build setting to the \"Make\" variable name it should be exposed as.",
            mandatory = True,
            providers = [BuildSettingInfo],
        ),
    },
)

def _configure_script_impl(ctx):
    substitutions = dict(ctx.attr.substitutions)
    for setting, placeholder in ctx.attr.settings.items():
        substitutions[placeholder] = setting[BuildSettingInfo].value
    ctx.actions.expand_template(
        template = ctx.file.template,
        output = ctx.outputs.out,
        substitutions = substitutions,
        is_executable = ctx.attr.is_executable,
    )
    return [DefaultInfo(
        files = depset([ctx.outputs.out]),
        executable = ctx.outputs.out if ctx.attr.is_executable else None,
    )]

configure_script = rule(
    doc = "Expands a `.in` template with literal substitutions and build setting values.",
    implementation = _configure_script_impl,
    attrs = {
        "is_executable": attr.bool(
            doc = "Whether the output is a script (`chmod a+x` in the Makefile) or data.",
            default = True,
        ),
        "out": attr.output(
            doc = "The expanded file.",
            mandatory = True,
        ),
        "settings": attr.label_keyed_string_dict(
            doc = "Build setting to the `@placeholder@` its value replaces.",
            providers = [BuildSettingInfo],
        ),
        "substitutions": attr.string_dict(
            doc = "Literal `@placeholder@` replacements.",
        ),
        "template": attr.label(
            doc = "The `.in` file.",
            allow_single_file = True,
            mandatory = True,
        ),
    },
)
