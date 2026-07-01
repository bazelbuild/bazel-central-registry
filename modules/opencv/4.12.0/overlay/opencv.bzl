load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@rules_cc//cc:defs.bzl", "cc_library")

OPENCV_COPTS = [
    "-D_USE_MATH_DEFINES",
    "-D__OPENCV_BUILD=1",
    "-D__STDC_CONSTANT_MACROS",
    "-D__STDC_FORMAT_MACROS",
    "-D__STDC_LIMIT_MACROS",
]

OPENCV_OPTIMIZATION_COPTS = select({
    "//:debug_build": [],
    "//conditions:default": [
        "-Os",
    ]
})

# NOTE: The copts here are compatible with GCC and Clang, except for PPCLE64 which are clang-specific.
# This is based on OpenCVCompilerOptimizations.cmake
# TODO: Add support for MSVC and ICC.

# NOTE: Starlark does not support while loops nor recursion, sw we have to manually compute full "implies" and "copts"
_KNOWN_OPTS = {
    "x86_64": {
        "sse": {
            "copts": ["-msse"],
            "implies": [],
        },
        "sse2": {
            "copts": ["-msse", "-msse2"],
            "implies": ["sse"],
        },
        "sse3": {
            "copts": ["-msse", "-msse2", "-msse3"],
            "implies": ["sse", "sse2"],
        },
        "ssse3": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3"],
            "implies": ["sse", "sse2", "sse3"],
        },
        "sse4_1": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1"],
            "implies": ["sse", "sse2", "sse3", "ssse3"],
        },
        "popcnt": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1"],
        },
        "sse4_2": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt"],
        },
        "avx": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mavx"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2"],
        },
        "fp16": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mavx"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx"],
        },
        "fma3": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mfma", "-mavx"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx"],
        },
        "avx2": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mfma", "-mavx", "-mavx2"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx", "fma3", "fp16"],
        },
        "avx_512f": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mfma", "-mavx", "-mavx2", "-mavx512f"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx", "fma3", "fp16", "avx2"],
        },
        "avx512_common": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mfma", "-mavx", "-mavx2", "-mavx512f", "-mavx512cd"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx", "fma3", "fp16", "avx2", "avx_512f"],
        },
        "avx512_knl": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mfma", "-mavx", "-mavx2", "-mavx512f", "-mavx512cd", "-mavx512er", "-mavx512pf"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx", "fma3", "fp16", "avx2", "avx_512f", "avx512_common"],
        },
        "avx512_knm": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mfma", "-mavx", "-mavx2", "-mavx512f", "-mavx512cd", "-mavx512er", "-mavx512pf", "-mavx5124fmaps", "-mavx5124vnniw", "-mavx512vpopcntdq"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx", "fma3", "fp16", "avx2", "avx_512f", "avx512_common", "avx512_knl"],
        },
        "avx512_skx": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mfma", "-mavx", "-mavx2", "-mavx512f", "-mavx512cd", "-mavx512bw", "-mavx512dq", "-mavx512vl"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx", "fma3", "fp16", "avx2", "avx_512f", "avx512_common"],
        },
        "avx512_cnl": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mfma", "-mavx", "-mavx2", "-mavx512f", "-mavx512cd", "-mavx512bw", "-mavx512dq", "-mavx512vl", "-mavx512ifma", "-mavx512vbmi"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx", "fma3", "fp16", "avx2", "avx_512f", "avx512_common", "avx512_skx"],
        },
        "avx512_clx": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mfma", "-mavx", "-mavx2", "-mavx512f", "-mavx512cd", "-mavx512bw", "-mavx512dq", "-mavx512vl", "-mavx512vnni"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx", "fma3", "fp16", "avx2", "avx_512f", "avx512_common", "avx512_skx"],
        },
        "avx512_icl": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mfma", "-mavx", "-mavx2", "-mavx512f", "-mavx512cd", "-mavx512bw", "-mavx512dq", "-mavx512vl", "-mavx512ifma", "-mavx512vbmi2", "-mavx512bitalg", "-mavx512vpopcntdq"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx", "fma3", "fp16", "avx2", "avx_512f", "avx512_common", "avx512_skx"],
        },
    },
    "armv7": {
        "vfpv3": {
            "copts": ["-mfpu=vfpv3"],
            "implies": [],
        },
        "neon": {
            "copts": ["-mfpu=neon"],
            "implies": [],
        },
        "fp16": {
            "copts": ["-mfpu=neon-fp16", "-mfp16-format=ieee"],
            "implies": ["neon"],
        },
    },
    "arm64": {
        "neon": {
            "copts": [],
            "implies": [],
        },
        "fp16": {
            "copts": [],
            "implies": ["neon"],
        },
        "neon_dotprod": {
            "copts": ["-march=armv8.2-a+dotprod"],
            "implies": ["neon"],
        },
        "neon_fp16": {
            "copts": ["-march=armv8.2-a+fp16"],
            "implies": ["neon"],
        },
        "neon_bf16": {
            "copts": ["-march=armv8.2-a+bf16"],
            "implies": ["neon"],
        },
    },
    "mips64": {
        "msa": {
            "copts": ["-mmsa"],
            "implies": [],
        },
    },
    "ppc64le": {
        "vsx": {
            "copts": ["-mvsx", "-maltivec"],
            "implies": [],
        },
        "vsx3": {
            "copts": ["-mvsx", "-maltivec", "-mpower9-vector"],
            "implies": ["vsx"],
        },
    },
    "riscv64": {
        "rvv": {
            "copts": [],
            "implies": [],
        },
    },
    "loongarch64": {
        "lsx": {
            "copts": ["-mlsx"],
            "implies": [],
        },
        "lasx": {
            "copts": ["-mlasx"],
            "implies": [],
        },
    },
}

def _arch_for_opt(opt):
    for arch, opts in _KNOWN_OPTS.items():
        if opt in opts:
            return arch
    fail("Unknown optimization: {}".format(opt))


# Optimizations that will always be enabled for a given architecture
# All other optimizations will be dispatched at runtime
# TODO: make these configurable via build flag
BASELINE_OPTS = {
    "x86_64": ["sse", "sse2", "sse3"],
    "armv7": ["neon"],
    "arm64": ["neon", "fp16"],
    "mips64": [],
    "ppc64le": [],
    "riscv64": [],
    "loongarch64": [],
}

def _calc_enabled_opts():
    enabled_opts = {}
    for arch, baseline_opts in BASELINE_OPTS.items():
        possible_opts = _KNOWN_OPTS[arch].keys()
        dispatched_opts = [opt for opt in possible_opts if opt not in baseline_opts]
        enabled_opts[arch] = {
            "baseline": baseline_opts,
            "dispatched": dispatched_opts,
        }
    return enabled_opts

ENABLED_OPTS = _calc_enabled_opts()

# OpenCV modules that will be built
# TODO: make this configurable via build flag
MODULES_COMMON = [
    "calib3d",
    "core",
    "features2d",
    "flann",
    "imgcodecs",
    "imgproc",
    "objdetect",
]

MODULES_DESKTOP = MODULES_COMMON + [
    "videoio",
    "highgui",
]

CONFIG_BASE = {
    "stub_opencl": [
        "core",
        "imgproc",
        "features2d",
        "calib3d",
        "objdetect",
    ],
    "contains_src_headers": [
        "imgproc",
        "imgcodecs",
        "features2d",
        "calib3d",
        "videoio",
    ],
    "contains_3rdparty": [
        "features2d",
    ],
}

def _merge_dicts(dict1, dict2):
    merged = dict(dict1)  # Create a copy of the first dictionary
    merged.update(dict2)  # Update with the second dictionary
    return merged

CONFIG_DESKTOP =_merge_dicts(CONFIG_BASE, {
    "modules": MODULES_DESKTOP,
})

CONFIG_NON_DESKTOP = _merge_dicts(CONFIG_BASE, {
    "modules": MODULES_COMMON,
})

def opencv_module(
        name,
        dispatched_files = {},
        deps = [],
        copts = [],
        linkopts = [],
        local_defines = [],
        compatible_with = [],
        sources = None,  # reserved for modules that list sources explicitly, such as videoio or highgui
    ):
    """
    Creates a Bazel rule for an OpenCV module.

    Args:
        name: The name of the module.
        dispatched_files: A mapping of keys to a list of operators.
        deps: A list of dependencies for the module.
        copts: Additional compiler options.
        linkopts: Additional linker options.
    """
    prefix = "modules/{}".format(name)
    dispatched_files = dispatched_files
    extra_headers = []

    glob_hdrs = [
        prefix + "/include/**/*.hpp",
        prefix + "/include/**/*.h",
    ]

    # Stub out opencl as all empty since we don't need to use any opencl functionality
    if name in CONFIG_BASE["stub_opencl"]:
        header_file = prefix + "/src/opencl_kernels_{}.hpp".format(name)
        write_file(
            name = "_{}".format(header_file),
            content = [
                "#include \"opencv2/core/ocl.hpp\"",
                "#include \"opencv2/core/ocl_genbase.hpp\"",
                "#include \"opencv2/core/opencl/ocl_defs.hpp\"",
            ],
            out = header_file,
        )
        extra_headers.append(header_file)

    # A Helper target to hold the headers generated in module's src dir
    # This is to avoid hacks with `copts` to include src dir as this can lead to issues
    # with include paths when target is used as a dependency from other modules
    cc_library(
        name = name + "_generated_headers",
        hdrs = extra_headers,
        strip_include_prefix = prefix + "/src",
    )

    simd_extra_headers = []

    dispatched_targets = {
        "@platforms//cpu:x86_64": [],
        "@platforms//cpu:armv7": [],
        "@platforms//cpu:arm64": [],
        "@platforms//cpu:mips64": [],
        "@platforms//cpu:ppc64le": [],
        "@platforms//cpu:riscv64": [],
        # "@platforms//cpu:loongarch64": [],
        "//conditions:default": [],
    }

    for fname, opts in dispatched_files.items():
        # Define file paths for SIMD declarations and SIMD header
        simd_declarations = "{}/src/{}.simd_declarations.hpp".format(prefix, fname)
        simd_filename = "{}/src/{}.simd.hpp".format(prefix, fname)

        simd_definitions_start = [
            "#define CV_CPU_SIMD_FILENAME \"{}\"".format(simd_filename),
        ]
        simd_opts = {
            "x86_64": [],
            "armv7": [],
            "arm64": [],
            "mips64": [],
            "ppc64le": [],
            "riscv64": [],
            "loongarch64": [],
        }
        dispatch_simd = {
            "x86_64": [],
            "armv7": [],
            "arm64": [],
            "mips64": [],
            "ppc64le": [],
            "riscv64": [],
            "loongarch64": [],
        }
        for opt in opts:
            arch = _arch_for_opt(opt)
            if opt not in ENABLED_OPTS[arch]["baseline"]:
                simd_opts[arch] += [
                    "#define CV_CPU_DISPATCH_MODE {}".format(opt.upper()),
                    "#include \"opencv2/core/private/cv_cpu_include_simd_declarations.hpp\"",
                ]
                dispatch_simd[arch] += [opt]

        dispatch_modes_simd = {}
        dispatch_modes_empty = [
            "#define CV_CPU_DISPATCH_MODES_ALL BASELINE",
        ]
        for arch, dispatched_opts in dispatch_simd.items():
            if len(dispatched_opts) > 0 and arch != "loongarch64": # loongarch64 currently not supported by bazel platforms
                dispatch_modes_simd[arch] = [
                    "#define CV_CPU_DISPATCH_MODES_ALL " + ", ".join([x.upper() for x in reversed(dispatched_opts) + ["BASELINE"]]),
                ]

                # also, create a cc_library for each dispatched file and add it to list of deps
                for opt in dispatched_opts:
                    simd_cpp_file = "{}/src/{}.{}.cpp".format(prefix, fname, opt)

                    write_file(
                        name = "_{}".format(simd_cpp_file),
                        out = simd_cpp_file,
                        content = [
                            "#include \"{}/src/precomp.hpp\"".format(prefix),
                            "#include \"{}/src/{}.simd.hpp\"".format(prefix, fname),
                        ],
                    )

                    simd_target_name = "_{}/src/{}_{}_{}_{}_simd".format(prefix, name, fname, arch, opt)

                    cc_library(
                        name = simd_target_name,
                        srcs = [
                            simd_cpp_file,
                            simd_declarations,
                        ] + native.glob([
                                prefix + "/src/**/*.hpp",
                                prefix + "/src/**/*.h"
                            ],
                            allow_empty = True
                        ),
                        hdrs = native.glob(glob_hdrs, allow_empty = True),
                        deps = deps + [":_base_headers"],
                        # note: some files don't include generated simd_declarations.hpp, so
                        # we need to define CV_CPU_DISPATCH_MODE here as well
                        # notable example: color_hsv operators in imgproc module
                        # This workaround also exist in OpenCVCompilerOptimizations.cmake
                        # in function ocv_compiler_optimization_process_sources
                        local_defines = [
                            "CV_CPU_DISPATCH_MODE={}".format(opt.upper()),
                            "CV_CPU_COMPILE_{}=1".format(opt.upper()),
                        ] + [
                            "CV_CPU_COMPILE_{}=1".format(x.upper())
                            for x in _KNOWN_OPTS[arch][opt]["implies"]
                            if x not in ENABLED_OPTS[arch]["baseline"]
                        ],
                        implementation_deps = [":" + name + "_generated_headers"],
                        copts = OPENCV_COPTS + OPENCV_OPTIMIZATION_COPTS +
                                 copts +
                                _KNOWN_OPTS[arch][opt]["copts"] +
                                 select({
                                    ":ubsan_enabled": [
                                        "-fno-sanitize=alignment", # alignment sanitizer will catch these, but they are intentional in most SIMD code
                                    ],
                                    "//conditions:default": [],
                                }),
                        target_compatible_with = ["@platforms//cpu:{}".format(arch)],
                        strip_include_prefix = prefix + "/include",
                        features = [
                            "exceptions", # enable exceptions for opencv modules
                        ],
                    )
                    dispatched_targets["@platforms//cpu:{}".format(arch)].append(Label(":" + simd_target_name))
            else:
                dispatch_modes_simd[arch] = dispatch_modes_empty

        simd_definitions_end = ["#undef CV_CPU_SIMD_FILENAME"]
        simd_extra_headers.append(simd_declarations)

        select_dict = {}
        for arch in simd_opts.keys():
            if arch != "loongarch64": # loongarch64 currently not supported by bazel platforms
                select_dict["@platforms//cpu:{}".format(arch)] = simd_definitions_start + simd_opts[arch] + dispatch_modes_simd[arch] + simd_definitions_end

        select_dict["//conditions:default"] = simd_definitions_start + dispatch_modes_empty + simd_definitions_end

        # Write the SIMD declarations to the file
        write_file(
            name = "_{}".format(simd_declarations),
            # note, simd_opts declarations are mainly for x86_64
            content = select(select_dict),
            out = simd_declarations,
        )

    glob_srcs = [prefix + "/src/**/*.cpp", prefix + "/src/**/*.hpp"]
    if name in CONFIG_BASE["contains_src_headers"]:
        glob_srcs.append(prefix + "/src/**/*.h")
    if name in CONFIG_BASE["contains_3rdparty"]:
        glob_srcs.append(prefix + "/3rdparty/**/*.h")

    baseline_copts = {
        "//conditions:default": [],
    }

    # exclude handcrafted SIMD files from the main srcs and include them only in their respective cc_library
    srcs_excludes = []
    # however, for baseline optimizations, any handcrafted SIMD files should be included back in the main srcs
    srcs_baseline_includes = []

    # A Helper target to hold the headers generated in module's src dir
    # This is to avoid hacks with `copts` to include src dir as this can lead to issues
    # with include paths when target is used as a dependency from other modules
    cc_library(
        name = name + "_generated_simd_headers",
        hdrs = simd_extra_headers,
        strip_include_prefix = prefix + "/src",
        deps = [":" + name + "_generated_headers"],
    )

    for arch, opts in ENABLED_OPTS.items():
        srcs_excludes += [
            prefix + "/src/**/*.{}.cpp".format(x)
            for x in opts["dispatched"]
        ]
        if arch != "loongarch64": # loongarch64 currently not supported by bazel platforms
            arch_flags = []
            for opt in opts["baseline"]:
                arch_flags += _KNOWN_OPTS[arch][opt]["copts"]
                srcs_baseline_includes.append(prefix + "/src/**/*.{}.cpp".format(opt))
            baseline_copts["@platforms//cpu:{}".format(arch)] = arch_flags

            # some modules have hand-optimized version for specific dispatched optimization
            # This will not be covered by the dispatched cc_library above, so we need to add additional target for it

            for opt in opts["dispatched"]:
                simd_target_name = "_{}/src/{}_{}_{}_simd_handcrafted".format(prefix, name, arch, opt)

                cc_library(
                    name = simd_target_name,
                    srcs = native.glob(
                        [
                            prefix + "/src/**/*.hpp",
                            prefix + "/src/**/*.h",
                            prefix + "/src/**/*.{}.cpp".format(opt)
                        ],
                        allow_empty = True
                    ),
                    hdrs = native.glob(glob_hdrs, allow_empty = True),
                    deps = deps + [":_base_headers"],
                    # note: some files don't include generated simd_declarations.hpp, so
                    # we need to define CV_CPU_DISPATCH_MODE here as well
                    # notable example: color_hsv operators in imgproc module
                    # This workaround also exist in OpenCVCompilerOptimizations.cmake
                    # in function ocv_compiler_optimization_process_sources
                    local_defines = [
                        "CV_CPU_DISPATCH_MODE={}".format(opt.upper()),
                        "CV_CPU_COMPILE_{}=1".format(opt.upper()),
                    ] + [
                        "CV_CPU_COMPILE_{}=1".format(x.upper())
                        for x in _KNOWN_OPTS[arch][opt]["implies"]
                        if x not in ENABLED_OPTS[arch]["baseline"]
                    ],
                    implementation_deps = [":" + name + "_generated_simd_headers"],
                    copts = OPENCV_COPTS + OPENCV_OPTIMIZATION_COPTS +
                             copts +
                            _KNOWN_OPTS[arch][opt]["copts"] +
                             select({
                                ":ubsan_enabled": [
                                    "-fno-sanitize=alignment", # alignment sanitizer will catch these, but they are intentional in most SIMD code
                                ],
                                "//conditions:default": [],
                            }),
                    target_compatible_with = ["@platforms//cpu:{}".format(arch)],
                    strip_include_prefix = prefix + "/include",
                    features = [
                        "exceptions", # enable exceptions for opencv modules
                    ],
                )
                dispatched_targets["@platforms//cpu:{}".format(arch)].append(Label(":" + simd_target_name))

    if sources != None:
        # used by videoio and highgui modules
        full_sources = sources
    else:
        full_sources = native.glob(glob_srcs, exclude = srcs_excludes) + native.glob(srcs_baseline_includes, allow_empty = True)

    cc_library(
        name = name,
        srcs = full_sources,
        hdrs = native.glob(glob_hdrs, allow_empty = True),
        deps = deps + [":_base_headers"] + select(dispatched_targets),
        copts = OPENCV_COPTS +
                OPENCV_OPTIMIZATION_COPTS +
                copts +
                select(baseline_copts) +
                select({
                    ":ubsan_enabled": [
                        "-fno-sanitize=alignment", # alignment sanitizer will catch these, but they are intentional in most SIMD code (which may be included in baseline)
                    ],
                    "//conditions:default": [],
                }),
        implementation_deps = [":" + name + "_generated_simd_headers"],
        linkopts = linkopts,
        local_defines = local_defines,
        target_compatible_with = compatible_with,
        strip_include_prefix = prefix + "/include",
        features = [
            "exceptions", # enable exceptions for opencv modules
        ],
        visibility = ["//visibility:public"],
    )
