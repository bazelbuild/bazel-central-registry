"""DO NOT MODIFY: the fast lexical analyser generator 2.6.4's targets, generated
by rules_cc_autoconf from configure.ac and the Makefile.am files with the
choices in decisions.bzl. To regenerate, from a clone of rules_cc_autoconf:

    bazel run //tools/convert -- convert --bcr-entry ../bazel-central-registry/modules/flex/2.6.4.bcr.9

@generated. BUILD.bazel beside this file is hand-written: it loads this file
and calls autoconf_targets(), and a rule it declares with a generated target's
name replaces that target here.

https://periareon.github.io/rules_cc_autoconf/convert.html
"""

load("@bazel_skylib//rules:common_settings.bzl", "bool_flag")
load("@bison//:bison.bzl", "bison")
load("@package_metadata//licenses/rules:license.bzl", "license")
load("@package_metadata//purl:purl.bzl", "purl")
load("@package_metadata//rules:package_metadata.bzl", "package_metadata")
load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_shared_library.bzl", "cc_shared_library")
load("@rules_cc_autoconf//autoconf:autoconf.bzl", "autoconf")
load("@rules_cc_autoconf//autoconf:autoconf_hdr.bzl", "autoconf_hdr")
load("@rules_cc_autoconf//autoconf:autoconf_linkopts.bzl", "autoconf_linkopts")
load("@rules_cc_autoconf//autoconf:autoconf_package_info.bzl", "autoconf_package_info")
load("@rules_cc_autoconf//autoconf:checks.bzl", "checks", "macros")

visibility("private")

GNULIB_M4_DEPS = [
    "@rules_cc_autoconf//gnulib/m4/iconv",
    "@rules_cc_autoconf//gnulib/m4/intlmacosx",
    "@rules_cc_autoconf//gnulib/m4/lib-ld",
    "@rules_cc_autoconf//gnulib/m4/lib-link",
    "@rules_cc_autoconf//gnulib/m4/lib-prefix",
    "@rules_cc_autoconf//gnulib/m4/nls",
    "@rules_cc_autoconf//gnulib/m4/po",
]

NO_WARNINGS = select({
    "@rules_cc//cc/compiler:clang-cl": ["/w"],
    "@rules_cc//cc/compiler:msvc-cl": ["/w"],
    "//conditions:default": ["-w"],
})

# buildifier: disable=unnamed-macro
def autoconf_targets():
    """The targets configure.ac and the Makefile.am files describe, in the package that calls this."""

    # buildifier: disable=native-package
    native.package(default_package_metadata = [":package_metadata"])

    native.exports_files(["COPYING"])

    license(
        name = "license_COPYING",
        kind = "@package_metadata//licenses/spdx:BSD-3-Clause",
        text = "COPYING",
        visibility = ["//:__subpackages__"],
    )

    package_metadata(
        name = "package_metadata",
        attributes = [":license_COPYING"],
        purl = purl.bazel(
            native.module_name(),
            native.module_version(),
        ),
        visibility = ["//:__subpackages__"],
    )

    autoconf_package_info(
        name = "package",
        package_name = "the fast lexical analyser generator",
        aliases = {
            "PACKAGE": "PACKAGE_TARNAME",
            "VERSION": "PACKAGE_VERSION",
        },
        module_bazel = "//:MODULE.bazel",
        package_bugreport = "flex-help@lists.sourceforge.net",
        package_tarname = "flex",
        strip_bcr_version = True,
        visibility = ["//:__subpackages__"],
    )

    bool_flag(
        name = "libfl_option",
        build_setting_default = True,
        visibility = ["//visibility:public"],
    )

    native.config_setting(
        name = "libfl_enabled",
        flag_values = {
            ":libfl_option": "True",
        },
        visibility = ["//:__subpackages__"],
    )

    autoconf(
        name = "autoconf",
        checks = [
            checks.M4_VARIABLE("lt_cv_ld_reload_flag", "-r"),
            checks.AC_SUBST("OBJDUMP", "objdump"),
            checks.AC_SUBST("DLLTOOL", "dlltool"),
            checks.AC_SUBST("STRIP", "strip"),
            checks.AC_SUBST("RANLIB", "ranlib"),
            checks.AC_SUBST("MANIFEST_TOOL", "mt"),
        ] + macros.AC_CHECK_HEADERS(
            ["dlfcn.h"],
            includes = ["AC_INCLUDES_DEFAULT"],
        ) + [
            checks.AC_SUBST("HELP2MAN", "help2man"),
            checks.AC_SUBST("TEXI2DVI", "gtexi2dvi"),
            checks.M4_VARIABLE("ac_cv_path_M4", "m4"),
            checks.AC_SUBST("M4", "m4"),
            checks.AC_DEFINE("M4", "\"m4\""),
            checks.AC_SUBST("INDENT", "indent"),
        ] + macros.AC_CHECK_HEADERS(
            [
                "regex.h",
                "sys/wait.h",
                "libintl.h",
                "limits.h",
                "locale.h",
                "malloc.h",
                "netinet/in.h",
            ],
        ) + [
            checks.AC_CHECK_LIB("pthread", "pthread_mutex_lock"),
            checks.AC_CHECK_LIB("m", "log10"),
            checks.AC_DEFINE("HAVE_STDBOOL_H", 1),
            checks.AC_DEFINE("HAVE__BOOL", 1),
            checks.AC_DEFINE("HAVE_MALLOC", 1),
            checks.AC_DEFINE("HAVE_REALLOC", 1),
        ] + macros.AC_CHECK_FUNCS(
            [
                "dup2",
                "memset",
                "regcomp",
                "strcasecmp",
                "strchr",
                "strdup",
                "strtol",
                "pow",
                "setlocale",
            ],
        ) + [
            checks.AC_SUBST("GREP", "grep"),
            checks.AC_SUBST("SHARED_VERSION_INFO", "2:0:0"),
            checks.AC_SUBST("LIBPTHREAD", ""),
        ] + select({
            "@platforms//os:macos": [
                checks.AC_SUBST("DSYMUTIL", "dsymutil"),
                checks.AC_SUBST("NMEDIT", "nmedit"),
                checks.AC_SUBST("LIPO", "lipo"),
                checks.AC_SUBST("OTOOL", "otool"),
                checks.AC_SUBST("OTOOL64", "otool64"),
            ],
            "//conditions:default": [],
        }),
        visibility = ["//:__subpackages__"],
        deps = [
            ":package",
            "@rules_cc_autoconf//autoconf/macros/AC_CANONICAL_BUILD",
            "@rules_cc_autoconf//autoconf/macros/AC_CANONICAL_HOST",
            "@rules_cc_autoconf//autoconf/macros/AC_CHECK_INCLUDES_DEFAULT",
            "@rules_cc_autoconf//autoconf/macros/AC_CONFIG_AUX_DIR_DEFAULT",
            "@rules_cc_autoconf//autoconf/macros/AC_FUNC_ALLOCA",
            "@rules_cc_autoconf//autoconf/macros/AC_TYPE_SIZE_T",
        ] + GNULIB_M4_DEPS,
    )

    autoconf_hdr(
        name = "config",
        out = "src/config.h",
        template = "src/config.h.in",
        visibility = ["//:__subpackages__"],
        deps = [":autoconf"],
    )

    cc_library(
        name = "config_headers",
        hdrs = [":config"] + native.glob(
            [
                "*.h",
                "src/*.h",
            ],
            allow_empty = True,
        ),
        include_prefix = ".",
        includes = ["src"],
        strip_include_prefix = "/",
        visibility = ["//:__subpackages__"],
    )

    cc_library(
        name = "src/fl_private_headers",
        hdrs = native.glob(
            ["src/**/*.h"],
            allow_empty = True,
            exclude = [
                "src/FlexLexer.h",
            ],
        ),
        include_prefix = ".",
        includes = ["src"],
        strip_include_prefix = "/",
        visibility = ["//:__subpackages__"],
    )

    cc_library(
        name = "src/fl",
        srcs = [
            "src/libmain.c",
            "src/libyywrap.c",
        ],
        hdrs = ["src/FlexLexer.h"],
        copts = NO_WARNINGS,
        implementation_deps = [
            ":config_headers",
            ":src/fl_private_headers",
        ],
        include_prefix = ".",
        includes = ["src"],
        linkstatic = True,
        local_defines = [
            "HAVE_CONFIG_H",
            "LOCALEDIR=\\\"/usr/local/share/locale\\\"",
        ],
        strip_include_prefix = "/",
        target_compatible_with = select({
            ":libfl_enabled": [],
            "//conditions:default": ["@platforms//:incompatible"],
        }),
        visibility = ["//visibility:public"],
    )

    cc_shared_library(
        name = "src/fl_shared",
        shared_lib_name = select({
            "@platforms//os:macos": "src/libfl.dylib",
            "@platforms//os:windows": "src/fl.dll",
            "//conditions:default": "src/libfl.so",
        }),
        target_compatible_with = select({
            "@platforms//os:windows": ["@platforms//:incompatible"],
            "//conditions:default": [],
        }),
        user_link_flags = select({
            "@platforms//os:macos": ["-Wl,-undefined,dynamic_lookup"],
            "//conditions:default": [],
        }),
        visibility = ["//visibility:public"],
        deps = [":src/fl"],
    )

    native.alias(
        name = "fl",
        actual = ":src/fl",
        visibility = ["//visibility:public"],
    )

    autoconf_linkopts(
        name = "linkopts",
        vars = ["LIBOBJS"],
        visibility = ["//:__subpackages__"],
        deps = [":autoconf"],
    )

    cc_library(
        name = "src/headers",
        hdrs = native.glob(
            ["src/**/*.h"],
            allow_empty = True,
        ),
        include_prefix = ".",
        includes = ["src"],
        strip_include_prefix = "/",
        visibility = ["//:__subpackages__"],
        deps = [":config_headers"],
    )

    bison(
        name = "src/bison/parse",
        srcs = ["src/parse.y"],
        outs = [
            "src/bison/parse.c",
            "src/bison/parse.h",
        ],
        args = [
            "-o",
            "$(execpath src/bison/parse.c)",
            "--defines=$(execpath src/bison/parse.h)",
            "-Wnone",
            "$(execpath src/parse.y)",
        ],
        visibility = ["//:__subpackages__"],
    )

    cc_binary(
        name = "src/flex",
        srcs = [
            "src/bison/parse.c",
            "src/bison/parse.h",
            "src/buf.c",
            "src/ccl.c",
            "src/dfa.c",
            "src/ecs.c",
            "src/filter.c",
            "src/gen.c",
            "src/main.c",
            "src/misc.c",
            "src/nfa.c",
            "src/options.c",
            "src/regex.c",
            "src/scanflags.c",
            "src/scanopt.c",
            "src/skel.c",
            "src/stage1scan.c",
            "src/sym.c",
            "src/tables.c",
            "src/tables_shared.c",
            "src/tblcmp.c",
            "src/yylex.c",
        ],
        copts = NO_WARNINGS,
        includes = ["src/bison"],
        local_defines = [
            "HAVE_CONFIG_H",
            "LOCALEDIR=\\\"/usr/local/share/locale\\\"",
        ],
        visibility = ["//visibility:public"],
        deps = [
            ":linkopts",
            ":src/headers",
        ],
    )

    native.alias(
        name = "flex",
        actual = ":src/flex",
        visibility = ["//visibility:public"],
    )
