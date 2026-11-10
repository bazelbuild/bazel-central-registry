"""A rule that checks lg_hugepage against lg_page, as configure does, before LG_HUGEPAGE reaches the header."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

def _checked_lg_hugepage_impl(ctx):
    lg_hugepage = ctx.attr._lg_hugepage[BuildSettingInfo].value
    lg_page = ctx.attr._lg_page[BuildSettingInfo].value

    # configure.ac's "Huge page size must be at least page size". It skips the check when LG_PAGE is "undefined"; here
    # lg_page is written into the header as is, so only a decimal value can be compared.
    if lg_page.isdigit() and lg_hugepage < int(lg_page):
        fail(" ".join([
            "Huge page size (2^{}) must be at least page size (2^{}):".format(lg_hugepage, lg_page),
            "--@jemalloc//settings/platform:lg_hugepage is {} and".format(lg_hugepage),
            "--@jemalloc//settings/platform:lg_page resolved to {}.".format(lg_page),
            "Raise lg_hugepage or set lg_page.",
        ]))
    return [BuildSettingInfo(value = lg_hugepage)]

checked_lg_hugepage = rule(
    doc = "The lg_hugepage flag, as a BuildSettingInfo for rules_cc_autoconf's AC_BUILD_SETTING, after checking at " +
          "analysis time that it is at least lg_page. LG_HUGEPAGE reaches the header only through this rule, so the " +
          "check holds with or without jemalloc's transition.",
    implementation = _checked_lg_hugepage_impl,
    attrs = {
        "_lg_hugepage": attr.label(default = "//settings/platform:lg_hugepage"),
        "_lg_page": attr.label(default = "//settings/platform:lg_page"),
    },
)
