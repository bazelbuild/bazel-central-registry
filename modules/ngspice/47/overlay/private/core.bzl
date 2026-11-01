"""Native static simulator variants for the embedding API and command line."""

load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load(":outputs.bzl", "linking_only")
load(":sources.bzl", "API_SRCS", "CLI_SRCS", "CORE_SRCS", "DEVICE_SRCS", "FRONTEND_SRCS", "INTERNAL_HDRS", "KLU_COMMON_SRCS", "KLU_COMPLEX_SRCS", "KLU_REAL_SRCS", "PUBLIC_HDRS", "XSPICE_CORE_SRCS")

visibility("//...")

def _flatten(groups):
    return [source for sources in groups.values() for source in sources]

def ngspice_libraries(name, target_compatible_with):
    """Build separately configured API and CLI objects with one final runtime.

    Args:
      name: Public static API library name.
      target_compatible_with: Supported target platforms.
    """
    cc_library(
        name = "internal_headers",
        hdrs = INTERNAL_HDRS + PUBLIC_HDRS,
        includes = [
            "src/include",
            "src/include/cppduals",
            "src/frontend",
            "src/maths/poly",
            "src/spicelib/devices",
        ],
        deps = [":config"],
    )

    # klusmp dispatches to both KLU and Sparse. Keep both solver backends in
    # one archive so GNU ld can resolve the Sparse references it introduces.
    core_groups = dict(CORE_SRCS)
    sparse_sources = core_groups.pop("src/maths/sparse")
    common_sources = _flatten(core_groups) + _flatten(FRONTEND_SRCS) + _flatten(DEVICE_SRCS)
    openmp_copts = select({
        ":clang_openmp": ["-Xclang", "-fopenmp"],
        ":gcc_openmp": ["-fopenmp"],
        "//conditions:default": [],
    })
    compile_deps = [":internal_headers"] + select({
        ":clang_openmp": [":openmp_header"],
        "//conditions:default": [],
    })
    runtime_deps = select({
        ":with_openmp": [":openmp_runtime"],
        "//conditions:default": [],
    })
    system_linkopts = select({
        "@platforms//os:linux": ["-lm", "-pthread", "-ldl"],
        "//conditions:default": [],
    })
    for variant in ["api", "cli"]:
        # SHARED_MODULE rewrites stdio in ngspice.h throughout the simulator.
        # Sharing these objects between the API and CLI is therefore incorrect.
        defines = ["HAVE_CONFIG_H"] + (["SHARED_MODULE"] if variant == "api" else [])
        for group_name, srcs, extra_defines in [
            ("core", common_sources + select({
                ":with_xspice": _flatten(XSPICE_CORE_SRCS),
                "//conditions:default": [],
            }), []),
            ("solvers", KLU_COMMON_SRCS + KLU_REAL_SRCS + sparse_sources, []),
            ("klu_complex", KLU_COMPLEX_SRCS, ["COMPLEX"]),
        ]:
            cc_library(
                name = variant + "_" + group_name,
                srcs = srcs,
                conlyopts = ["-std=gnu11"],
                cxxopts = ["-std=c++11"],
                copts = openmp_copts,
                local_defines = defines + extra_defines,
                linkstatic = True,
                deps = compile_deps,
                target_compatible_with = target_compatible_with,
            )
        deps = [":" + variant + "_" + suffix for suffix in ["core", "solvers", "klu_complex"]] + compile_deps + runtime_deps
        if variant == "api":
            cc_library(
                name = "api_library",
                srcs = API_SRCS,
                hdrs = PUBLIC_HDRS,
                strip_include_prefix = "src/include",
                conlyopts = ["-std=gnu11"],
                copts = openmp_copts,
                local_defines = defines + ["SIMULATOR", 'SHAREDSPICE_version="47"'],
                defines = select({
                    ":with_xspice": ["XSPICE"],
                    "//conditions:default": [],
                }),
                deps = deps,
                linkopts = system_linkopts,
                linkstatic = True,
                target_compatible_with = target_compatible_with,
            )
        else:
            cc_binary(
                name = "cli_native",
                srcs = CLI_SRCS,
                conlyopts = ["-std=gnu11"],
                copts = openmp_copts,
                local_defines = defines + ["SIMULATOR"],
                deps = deps,
                linkopts = system_linkopts,
                linkstatic = True,
                target_compatible_with = target_compatible_with,
            )
    linking_only(
        name = "api_linking",
        dep = ":api_library",
    )

    # Export only the public header and ABI definition. Internal config and
    # LLVM omp.h must never change a consumer's compilation environment.
    cc_library(
        name = name,
        hdrs = PUBLIC_HDRS,
        strip_include_prefix = "src/include",
        defines = select({
            ":with_xspice": ["XSPICE"],
            "//conditions:default": [],
        }),
        deps = [":api_linking"],
        target_compatible_with = target_compatible_with,
        visibility = ["//visibility:public"],
    )
