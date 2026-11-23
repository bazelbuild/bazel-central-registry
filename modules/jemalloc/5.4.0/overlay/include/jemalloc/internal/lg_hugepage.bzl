"""A rule that checks lg_hugepage against lg_page, as configure does, before LG_HUGEPAGE reaches the header."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(":lg_page.bzl", "shell_integer")

def _checked_lg_hugepage_impl(ctx):
    lg_hugepage = ctx.attr._lg_hugepage[BuildSettingInfo].value
    lg_page = ctx.attr._lg_page[BuildSettingInfo].value

    # configure.ac's "Huge page size must be greater than page size", which pages.h also enforces when it compiles. It
    # skips the check when LG_PAGE is "undefined"; here lg_page, a string flag, is written into the header as is, so it
    # is compared only where shell_integer reads it as an integer; any other lg_page passes through uncompared.
    # lg_hugepage is an int_flag, so it is always an integer.
    lg_page_integer = shell_integer(lg_page)
    if lg_page_integer != None and lg_hugepage <= lg_page_integer:
        fail(" ".join([
            "Huge page size (2^{}) must be greater than page size (2^{}):".format(lg_hugepage, lg_page),
            "--@jemalloc//settings/platform:lg_hugepage is {} and".format(lg_hugepage),
            "--@jemalloc//settings/platform:lg_page resolved to {}.".format(lg_page),
            "Raise lg_hugepage or set lg_page.",
        ]))
    return [BuildSettingInfo(value = lg_hugepage)]

checked_lg_hugepage = rule(
    doc = "The lg_hugepage flag, as a BuildSettingInfo for rules_cc_autoconf's AC_BUILD_SETTING, after checking at " +
          "analysis time that it is greater than lg_page. LG_HUGEPAGE reaches the header only through this rule.",
    implementation = _checked_lg_hugepage_impl,
    attrs = {
        "_lg_hugepage": attr.label(default = "//settings/platform:lg_hugepage"),
        "_lg_page": attr.label(default = "//settings/platform:lg_page_resolved"),
    },
)
