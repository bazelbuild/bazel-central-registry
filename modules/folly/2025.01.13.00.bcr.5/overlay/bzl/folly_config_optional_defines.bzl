"""Used to generate config flags that control settings in the generated folly-config.h file."""

load("@bazel_skylib//rules:common_settings.bzl", "bool_flag")

_FOLLY_CONFIG_FLAGS_AND_DEFINES = [
    # Toolchain / platform dependent flags. Enable these only if you know your compiler toolchain
    # and target platform support them. They are disabled by default to be conservative and ensure
    # compatibility the the most platforms.
    ("with_extrandom_sfmt19937", "FOLLY_HAVE_EXTRANDOM_SFMT19937"),
    ("with_getrandom", "FOLLY_HAVE_GETRANDOM"),
    ("with_int128", "FOLLY_HAVE_INT128_T"),
    ("with_vla", "FOLLY_HAVE_VLA"),

    # NOTE: dwarf is available for linux via the BCR. It is always compiled and linked to
    # folly for linux. If this flag is not specified then folly's dwarf functionality is disabled.
    ("use_dwarf", "FOLLY_HAVE_DWARF"),

    # NOTE: libunwind is available for linux via the BCR. It is always compiled and linked to
    # folly for linux. If this flag is not specified, libc backtrace will be used for stack traces
    # and libunwind will not actually be used.
    ("use_libunwind", "FOLLY_HAVE_LIBUNWIND"),
]

def folly_config_optional_defines(name = "folly_config_optional_defines"):
    """Creates optional flags and config settings for folly-config.h.

    Args:
      name: unused, required by linter

    Returns:
      A list of defines created from flags. Looks something like this:
      [] + select({":with_int128_setting": ["FOLLY_HAVE_INT128_T"], default: []})
         + select({":with_pipe2_setting":  ["FOLLY_HAVE_PIPE2"], ...})
    """
    out = []
    for (flag_name, define_name) in _FOLLY_CONFIG_FLAGS_AND_DEFINES:
        bool_flag(
            name = flag_name,
            build_setting_default = False,
            visibility = ["//visibility:public"],
        )
        config_setting_name = flag_name + "_setting"
        native.config_setting(
            name = config_setting_name,
            flag_values = {":" + flag_name: "true"},
            visibility = ["//visibility:public"],
        )
        out = out + select({
            config_setting_name: [define_name],
            "//conditions:default": [],
        })
    return out
