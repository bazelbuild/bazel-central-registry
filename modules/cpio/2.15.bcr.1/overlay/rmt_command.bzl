"""Generate `lib/rmt-command.h` from a build setting."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

def _c_string(value):
    """Render `value` as a C string literal."""
    return '"{}"'.format(value.replace("\\", "\\\\").replace('"', '\\"'))

def _rmt_command_h_impl(ctx):
    command = ctx.attr.command[BuildSettingInfo].value
    if not command:
        fail("{}: the rmt command path must not be empty".format(ctx.attr.command.label))

    out = ctx.actions.declare_file(ctx.attr.out)
    ctx.actions.write(
        output = out,
        content = """\
/* DO NOT EDIT! GENERATED AUTOMATICALLY! */
#ifndef DEFAULT_RMT_COMMAND
# define DEFAULT_RMT_COMMAND {}
#endif
""".format(_c_string(command)),
    )
    return [DefaultInfo(files = depset([out]))]

rmt_command_h = rule(
    implementation = _rmt_command_h_impl,
    doc = """\
Write an `rmt-command.h` defining `DEFAULT_RMT_COMMAND`.

Upstream builds this header in `lib/Makefile.am` from `$(DEFAULT_RMT_DIR)`,
which `m4/rmt.m4` fills in from either the `DEFAULT_RMT_DIR` variable or
`--with-rmt=FILE`.  The value becomes `rmt_command` in `lib/rtapelib.c`, which
passes it to the remote shell as the program to run *on the remote host* when
an archive is named `[user@]host:path`.  It therefore describes a remote
filesystem rather than the build or execution platform, which is why upstream
makes it configurable and why nothing here can infer it.

cpio has no runtime override for it -- `--rsh-command` only selects the
transport -- so it has to be a build setting.  The path is free-form, so
`select()` over `config_setting`s cannot express it and this rule reads the
flag value directly.
""",
    attrs = {
        "command": attr.label(
            doc = """\
A `string_flag` holding the path to the `rmt` program on the remote host.

Failing the build on an empty value keeps the flag from silently compiling in
a `DEFAULT_RMT_COMMAND` of `""`, which `execl` would reject only once a remote
archive was actually opened.
""",
            mandatory = True,
            providers = [BuildSettingInfo],
        ),
        "out": attr.string(
            doc = "The generated header, relative to this package.",
            mandatory = True,
        ),
    },
)
