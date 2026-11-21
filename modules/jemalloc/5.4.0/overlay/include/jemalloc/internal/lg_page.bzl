"""A rule that checks lg_page's minimum, as configure does, before LG_PAGE reaches the header."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

def shell_integer(value):
    """The integer value spells as an optional leading + or - followed by decimal digits, or None otherwise.

    configure compares LG_PAGE with `test -lt` and `test -le`, which read such a value as a signed integer, so +7 is 7
    and -1 is -1, and which also accept it with surrounding whitespace, so " 7" is 7 as well. Surrounding spaces and
    tabs are therefore stripped before the value is read; anything else that is not such a spelling gets None.

    Args:
        value: The string to read.

    Returns:
        The integer, or None.
    """
    stripped = value.strip(" \t")
    digits = stripped[1:] if stripped[:1] in ("+", "-") else stripped
    if not digits.isdigit():
        return None
    return -int(digits, 10) if stripped[:1] == "-" else int(digits, 10)

def _checked_lg_page_impl(ctx):
    lg_page = ctx.attr._lg_page[BuildSettingInfo].value

    # configure.ac's "LG_PAGE must be at least 8 (PAGE >= 256)". lg_page, a string flag, is written into the header as
    # is, so it is compared only where shell_integer reads it as an integer; anything else passes through uncompared.
    lg_page_integer = shell_integer(lg_page)
    if lg_page_integer != None and lg_page_integer < 8:
        fail(" ".join([
            "LG_PAGE must be at least 8 (PAGE >= 256):",
            "--@jemalloc//settings/platform:lg_page resolved to {}.".format(lg_page),
        ]))
    return [BuildSettingInfo(value = lg_page)]

checked_lg_page = rule(
    doc = "The resolved lg_page setting, as a BuildSettingInfo for rules_cc_autoconf's AC_BUILD_SETTING, after " +
          "checking at analysis time that it is at least 8. LG_PAGE reaches the header only through this rule.",
    implementation = _checked_lg_page_impl,
    attrs = {
        "_lg_page": attr.label(default = "//settings/platform:lg_page_resolved"),
    },
)
