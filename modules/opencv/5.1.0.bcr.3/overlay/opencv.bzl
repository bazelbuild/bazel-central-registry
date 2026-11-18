load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_cc//cc:cc_test.bzl", "cc_test")

# Select MSVC-style flags for both cl.exe and clang-cl.exe. The compiler identifiers
# are provided by rules_cc and come from the selected C++ toolchain.
def _compiler_copts(copts, cl_copts):
    return select({
        "@rules_cc//cc/compiler:clang-cl": cl_copts,
        "@rules_cc//cc/compiler:msvc-cl": cl_copts,
        "//conditions:default": copts,
    })

OPENCV_COPTS = _compiler_copts(
    copts = [
        "-D_USE_MATH_DEFINES",
        "-D__OPENCV_BUILD=1",
        "-D__STDC_CONSTANT_MACROS",
        "-D__STDC_FORMAT_MACROS",
        "-D__STDC_LIMIT_MACROS",
    ],
    cl_copts = [
        "/D_USE_MATH_DEFINES",
        "/D__OPENCV_BUILD=1",
        "/D__STDC_CONSTANT_MACROS",
        "/D__STDC_FORMAT_MACROS",
        "/D__STDC_LIMIT_MACROS",
    ],
)

OPENCV_OPTIMIZATION_COPTS = select({
    "//:debug_clang_cl_build": [],
    "//:debug_msvc_cl_build": [],
    "@rules_cc//cc/compiler:clang-cl": [
        "/O2",
    ],
    "@rules_cc//cc/compiler:msvc-cl": [
        "/O2",
    ],
    "//:debug_build": [],
    "//conditions:default": [
        "-O3",
    ],
})

# NOTE: The copts here are compatible with GCC and Clang, except for PPCLE64 which are clang-specific.
# cl_copts contains the corresponding options for compilers with an MSVC-compatible command line.
# This is based on OpenCVCompilerOptimizations.cmake
# TODO: Add support for ICC.

# NOTE: Starlark does not support while loops nor recursion, sw we have to manually compute full "implies" and "copts"
_KNOWN_OPTS = {
    "x86_64": {
        "sse": {
            "copts": ["-msse"],
            "cl_copts": [],
            "implies": [],
        },
        "sse2": {
            "copts": ["-msse", "-msse2"],
            "cl_copts": [],
            "implies": ["sse"],
        },
        "sse3": {
            "copts": ["-msse", "-msse2", "-msse3"],
            "cl_copts": [],
            "implies": ["sse", "sse2"],
        },
        "ssse3": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3"],
            "cl_copts": [],
            "implies": ["sse", "sse2", "sse3"],
            "detect_macro": "defined(__SSSE3__) || defined(__AVX__)",
        },
        "sse4_1": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1"],
            "cl_copts": [],
            "implies": ["sse", "sse2", "sse3", "ssse3"],
            "detect_macro": "defined(__SSE4_1__) || defined(__AVX__)",
        },
        "popcnt": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt"],
            "cl_copts": [],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1"],
            "detect_macro": "defined(__POPCNT__) || defined(__SSE4_2__) || defined(__AVX__)",
        },
        "sse4_2": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2"],
            "cl_copts": [],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt"],
            "detect_macro": "defined(__SSE4_2__) || defined(__AVX__)",
        },
        "avx": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mavx"],
            "cl_copts": ["/arch:AVX"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2"],
            "detect_macro": "defined(__AVX__)",
        },
        "fp16": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mavx"],
            "cl_copts": ["/arch:AVX"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx"],
            "detect_macro": "defined(__F16C__) || defined(__AVX2__)",
        },
        "fma3": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mfma", "-mavx"],
            "cl_copts": ["/arch:AVX"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx"],
            "detect_macro": "defined(__FMA__) || defined(__AVX2__)",
        },
        "avx2": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mfma", "-mavx", "-mavx2"],
            "cl_copts": ["/arch:AVX2"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx", "fma3", "fp16"],
            "detect_macro": "defined(__AVX2__)",
        },
        "avx_vnni": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mfma", "-mavx", "-mavx2", "-mavxvnni"],
            "cl_copts": ["/arch:AVX2"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx", "fma3", "fp16", "avx2"],
            "detect_macro": "defined(__AVXVNNI__)",
        },
        "avx_512f": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mfma", "-mavx", "-mavx2", "-mavx512f"],
            "cl_copts": ["/arch:AVX512"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx", "fma3", "fp16", "avx2"],
            "detect_macro": "defined(__AVX512F__)",
        },
        "avx512_common": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mfma", "-mavx", "-mavx2", "-mavx512f", "-mavx512cd"],
            "cl_copts": ["/arch:AVX512"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx", "fma3", "fp16", "avx2", "avx_512f"],
            "detect_macro": "defined(CV_CPU_COMPILE_AVX_512F) && defined(__AVX512CD__)",
        },
        "avx512_knl": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mfma", "-mavx", "-mavx2", "-mavx512f", "-mavx512cd", "-mavx512er", "-mavx512pf"],
            "cl_copts": ["/arch:AVX512"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx", "fma3", "fp16", "avx2", "avx_512f", "avx512_common"],
            "detect_macro": "defined(CV_CPU_COMPILE_AVX512_COMMON) && defined(__AVX512ER__) && defined(__AVX512PF__)",
        },
        "avx512_knm": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mfma", "-mavx", "-mavx2", "-mavx512f", "-mavx512cd", "-mavx512er", "-mavx512pf", "-mavx5124fmaps", "-mavx5124vnniw", "-mavx512vpopcntdq"],
            "cl_copts": ["/arch:AVX512"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx", "fma3", "fp16", "avx2", "avx_512f", "avx512_common", "avx512_knl"],
            "detect_macro": "defined(CV_CPU_COMPILE_AVX512_KNL) && defined(__AVX5124FMAPS__) && defined(__AVX5124VNNIW__) && defined(__AVX512VPOPCNTDQ__)",
        },
        "avx512_skx": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mfma", "-mavx", "-mavx2", "-mavx512f", "-mavx512cd", "-mavx512bw", "-mavx512dq", "-mavx512vl"],
            "cl_copts": ["/arch:AVX512"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx", "fma3", "fp16", "avx2", "avx_512f", "avx512_common"],
            "detect_macro": "defined(CV_CPU_COMPILE_AVX512_COMMON) && defined(__AVX512BW__) && defined(__AVX512DQ__) && defined(__AVX512VL__)",
        },
        "avx512_cnl": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mfma", "-mavx", "-mavx2", "-mavx512f", "-mavx512cd", "-mavx512bw", "-mavx512dq", "-mavx512vl", "-mavx512ifma", "-mavx512vbmi"],
            "cl_copts": ["/arch:AVX512"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx", "fma3", "fp16", "avx2", "avx_512f", "avx512_common", "avx512_skx"],
            "detect_macro": "defined(CV_CPU_COMPILE_AVX512_SKX) && defined(__AVX512IFMA__) && defined(__AVX512VBMI__)",
        },
        "avx512_clx": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mfma", "-mavx", "-mavx2", "-mavx512f", "-mavx512cd", "-mavx512bw", "-mavx512dq", "-mavx512vl", "-mavx512vnni"],
            "cl_copts": ["/arch:AVX512"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx", "fma3", "fp16", "avx2", "avx_512f", "avx512_common", "avx512_skx"],
            "detect_macro": "defined(CV_CPU_COMPILE_AVX512_SKX) && defined(__AVX512VNNI__)",
        },
        "avx512_icl": {
            "copts": ["-msse", "-msse2", "-msse3", "-mssse3", "-msse4.1", "-mpopcnt", "-msse4.2", "-mf16c", "-mfma", "-mavx", "-mavx2", "-mavx512f", "-mavx512cd", "-mavx512bw", "-mavx512dq", "-mavx512vl", "-mavx512ifma", "-mavx512vbmi", "-mavx512vnni", "-mavx512vbmi2", "-mavx512bitalg", "-mavx512vpopcntdq"],
            "cl_copts": ["/arch:AVX512"],
            "implies": ["sse", "sse2", "sse3", "ssse3", "sse4_1", "popcnt", "sse4_2", "avx", "fma3", "fp16", "avx2", "avx_512f", "avx512_common", "avx512_skx", "avx512_cnl", "avx512_clx"],
            "detect_macro": "defined(CV_CPU_COMPILE_AVX512_CNL) && defined(CV_CPU_COMPILE_AVX512_CLX) && defined(__AVX512VBMI2__) && defined(__AVX512BITALG__) && defined(__AVX512VPOPCNTDQ__)",
        },
    },
    "armv7": {
        "neon": {
            "copts": ["-mfpu=neon"],
            "cl_copts": [],
            "implies": [],
        },
        "fp16": {
            "copts": ["-mfpu=neon-fp16", "-mfp16-format=ieee"],
            "cl_copts": [],
            "implies": ["neon"],
            "detect_macro": "defined(__ARM_FP) && (__ARM_FP & 2)",
        },
    },
    "arm64": {
        "neon": {
            "copts": [],
            "cl_copts": [],
            "implies": [],
        },
        "fp16": {
            "copts": [],
            "cl_copts": [],
            "implies": ["neon"],
        },
        "neon_dotprod": {
            "copts": ["-march=armv8.2-a+dotprod"],
            "cl_copts": [],
            "implies": ["neon"],
            "detect_macro": "defined(__ARM_FEATURE_DOTPROD)",
        },
        "neon_fp16": {
            "copts": ["-march=armv8.2-a+fp16"],
            "cl_copts": [],
            "implies": ["neon"],
            "detect_macro": "defined(__ARM_FEATURE_FP16_VECTOR_ARITHMETIC)",
        },
        "neon_bf16": {
            "copts": ["-march=armv8.2-a+bf16"],
            "cl_copts": [],
            "implies": ["neon"],
            "detect_macro": "defined(__ARM_FEATURE_BF16_VECTOR_ARITHMETIC)",
        },
        "sve": {
            "copts": ["-march=armv8.2-a+sve"],
            "cl_copts": [],
            "implies": [],
            "detect_macro": "defined(__ARM_FEATURE_SVE)",
        }
    },
    "mips64": {
        "msa": {
            "copts": ["-mmsa"],
            "cl_copts": [],
            "implies": [],
            "detect_macro": "defined(__mips_msa)",
        },
    },
    "ppc64le": {
        "vsx": {
            "copts": ["-mvsx", "-maltivec"],
            "cl_copts": [],
            "implies": [],
            "detect_macro": "defined(__VSX__)",
        },
        "vsx3": {
            "copts": ["-mvsx", "-maltivec", "-mpower9-vector"],
            "cl_copts": [],
            "implies": ["vsx"],
            "detect_macro": "defined(__POWER9_VECTOR__)",
        },
    },
    "riscv64": {
        "rvv": {
            "copts": [],
            "cl_copts": [],
            "implies": [],
            "detect_macro": "defined(__riscv_vector) || defined(__riscv_v)",
        },
    },
    "loongarch64": {
        "lsx": {
            "copts": ["-mlsx"],
            "cl_copts": [],
            "implies": [],
            "detect_macro": "defined(__loongarch_sx)",
        },
        "lasx": {
            "copts": ["-mlasx"],
            "cl_copts": [],
            "implies": ["lsx"],
            "detect_macro": "defined(__loongarch_asx)",
        },
    },
}

def _arches_for_opt(opt):
    arches = []
    for arch, opts in _KNOWN_OPTS.items():
        if opt in opts:
            arches.append(arch)
    if len(arches) == 0:
        fail("Unknown optimization: {}".format(opt))
    else:
        return arches


# Optimizations that will always be enabled for a given architecture by default.
# Higher baselines can be selected via --@opencv//:cpu_baseline=<opt> or compiler target flags (-march=...).
BASELINE_OPTS = {
    "x86_64": ["sse", "sse2", "sse3"],
    "armv7": ["neon"],
    "arm64": ["neon", "fp16"],
    "mips64": [],
    "ppc64le": [],
    "riscv64": [],
    "loongarch64": [],
}

CONFIGURABLE_BASELINES_BY_ARCH = {
    arch: list(opts.keys())
    for arch, opts in _KNOWN_OPTS.items()
}

ALL_CONFIGURABLE_BASELINES = list({
    opt: True
    for opts in _KNOWN_OPTS.values()
    for opt in opts.keys()
}.keys())

def _is_opt_in_baseline(arch, opt, baseline_opt):
    return (
        opt in ENABLED_OPTS[arch]["baseline"] or
        opt == baseline_opt or
        opt in _KNOWN_OPTS[arch][baseline_opt]["implies"]
    )

def _calc_enabled_opts():
    enabled_opts = {}
    for arch, baseline_opts in BASELINE_OPTS.items():
        possible_opts = _KNOWN_OPTS[arch].keys()
        dispatched_opts = [opt for opt in possible_opts if opt not in baseline_opts]
        detect_macros = {
            opt: _KNOWN_OPTS[arch][opt]["detect_macro"]
            for opt in dispatched_opts
            if "detect_macro" in _KNOWN_OPTS[arch][opt]
        }
        enabled_opts[arch] = {
            "baseline": baseline_opts,
            "dispatched": dispatched_opts,
            "detect_macros": detect_macros,
        }
    return enabled_opts

ENABLED_OPTS = _calc_enabled_opts()

# OpenCV modules that will be built
# TODO: make this configurable via build flag
MODULES_COMMON = [
    "calib",
    "core",
    "dnn",
    "features",
    "flann",
    "geometry",
    "imgcodecs",
    "imgproc",
    "objdetect",
    "photo",
    "stereo",
    "stitching",
    "video",
]

MODULES_DESKTOP = MODULES_COMMON + [
    "ptcloud",
    "videoio",
    "highgui",
]

CONFIG_BASE = {
    "stub_opencl": [
        "calib",
        "core",
        "geometry",
        "features",
        "imgproc",
        "objdetect",
        "photo",
        "ptcloud",
        "stereo",
        "stitching",
        "video",
    ],
    "contains_src_headers": [
        "dnn",
        "geometry",
        "imgcodecs",
        "videoio",
    ],
    "contains_3rdparty": [
        "features",
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
        force_dispatch = False,
        deps = [],
        copts = [],
        cl_copts = [],
        linkopts = [],
        local_defines = [],
        compatible_with = [],
        srcs_excludes_globs = [],
        sources = None,  # reserved for modules that list sources explicitly, such as videoio or highgui
        test_enabled = True,
        test_srcs_excludes_globs = [],
        test_sources = None, # reserved for modules that list sources explicitly, such as videoio or highgui
    ):
    """
    Creates a Bazel rule for an OpenCV module.

    Args:
        name: The name of the module.
        dispatched_files: A mapping of keys to a list of operators.
        force_dispatch: If enabled, all optimizations for the files in dispatched_files will be forced to be dispatched, even if they are included in baseline.
        deps: A list of dependencies for the module.
        copts: Additional compiler options for GCC-compatible command lines.
        cl_copts: Additional compiler options for MSVC-compatible command lines.
        linkopts: Additional linker options.
        local_defines: A list of preprocessor definitions to be added to the module.
        compatible_with: A list of labels that specify the platforms compatible with this module.
        srcs_excludes_globs: A list of glob patterns to exclude from the module's sources.
        sources: A list of sources for the module. If None, sources will be determined by globbing the src directory. This is useful for modules that need to explicitly list their sources, such as videoio or highgui.
    """
    prefix = "modules/{}".format(name)
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
        "//conditions:default": [],
    }
    for arch, baseline_opts in CONFIGURABLE_BASELINES_BY_ARCH.items():
        dispatched_targets["@platforms//cpu:{}".format(arch)] = []
        for baseline_opt in baseline_opts:
            dispatched_targets["//:{}_baseline_{}".format(arch, baseline_opt)] = []

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
            arches = _arches_for_opt(opt)
            for arch in arches:
                if force_dispatch or opt not in ENABLED_OPTS[arch]["baseline"]:
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
            if len(dispatched_opts) > 0:
                dispatch_modes_simd[arch] = [
                    "#define CV_CPU_DISPATCH_MODES_ALL " + ", ".join([x.upper() for x in reversed(dispatched_opts) + ["BASELINE"]]),
                ]

                # also, create a cc_library for each dispatched file and add it to list of deps
                for opt in dispatched_opts:
                    simd_cpp_file = "{}/src/{}.{}.{}.cpp".format(prefix, fname, opt, arch)

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
                        copts = OPENCV_COPTS +
                                OPENCV_OPTIMIZATION_COPTS +
                                _compiler_copts(
                                    copts + _KNOWN_OPTS[arch][opt]["copts"],
                                    cl_copts + _KNOWN_OPTS[arch][opt]["cl_copts"],
                                ),
                        target_compatible_with = ["@platforms//cpu:{}".format(arch)],
                        strip_include_prefix = prefix + "/include",
                        features = [
                            "exceptions", # enable exceptions for opencv modules
                            "-ubsan",     # disable UBSAN for opencv modules
                        ],
                    )
                    dispatched_targets["@platforms//cpu:{}".format(arch)].append(Label(":" + simd_target_name))
                    for baseline_opt in CONFIGURABLE_BASELINES_BY_ARCH[arch]:
                        if force_dispatch or fname in ["lut", "equalize_hist"] or not _is_opt_in_baseline(arch, opt, baseline_opt):
                            dispatched_targets["//:{}_baseline_{}".format(arch, baseline_opt)].append(Label(":" + simd_target_name))
            else:
                dispatch_modes_simd[arch] = dispatch_modes_empty

        simd_definitions_end = ["#undef CV_CPU_SIMD_FILENAME"]
        simd_extra_headers.append(simd_declarations)

        select_dict = {}
        for arch in simd_opts.keys():
            select_dict["@platforms//cpu:{}".format(arch)] = simd_definitions_start + simd_opts[arch] + dispatch_modes_simd[arch] + simd_definitions_end
            for baseline_opt in CONFIGURABLE_BASELINES_BY_ARCH[arch]:
                if force_dispatch or fname in ["lut", "equalize_hist"]:
                    baseline_dispatched_opts = dispatch_simd[arch]
                else:
                    baseline_dispatched_opts = [
                        opt
                        for opt in dispatch_simd[arch]
                        if not _is_opt_in_baseline(arch, opt, baseline_opt)
                    ]
                if len(baseline_dispatched_opts) > 0:
                    baseline_simd_opts = []
                    for opt in baseline_dispatched_opts:
                        baseline_simd_opts += [
                            "#define CV_CPU_DISPATCH_MODE {}".format(opt.upper()),
                            "#include \"opencv2/core/private/cv_cpu_include_simd_declarations.hpp\"",
                        ]
                    baseline_dispatch_modes = [
                        "#define CV_CPU_DISPATCH_MODES_ALL " + ", ".join([x.upper() for x in reversed(baseline_dispatched_opts) + ["BASELINE"]]),
                    ]
                    select_dict["//:{}_baseline_{}".format(arch, baseline_opt)] = simd_definitions_start + baseline_simd_opts + baseline_dispatch_modes + simd_definitions_end
                else:
                    select_dict["//:{}_baseline_{}".format(arch, baseline_opt)] = simd_definitions_start + dispatch_modes_empty + simd_definitions_end

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
    srcs_excludes += srcs_excludes_globs
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
        arch_flags = []
        arch_cl_flags = []
        for opt in opts["baseline"]:
            arch_flags += _KNOWN_OPTS[arch][opt]["copts"]
            arch_cl_flags += _KNOWN_OPTS[arch][opt]["cl_copts"]
            srcs_baseline_includes.append(prefix + "/src/**/*.{}.cpp".format(opt))
        baseline_copts["@platforms//cpu:{}".format(arch)] = arch_flags
        if arch in ["x86_64", "armv7"]:
            baseline_copts["//:{}_clang_cl".format(arch)] = arch_cl_flags
            baseline_copts["//:{}_msvc_cl".format(arch)] = arch_cl_flags
        for opt in CONFIGURABLE_BASELINES_BY_ARCH[arch]:
            opt_flags = arch_flags if opt in opts["baseline"] else _KNOWN_OPTS[arch][opt]["copts"]
            opt_cl_flags = arch_cl_flags if opt in opts["baseline"] else _KNOWN_OPTS[arch][opt]["cl_copts"]
            baseline_copts["//:{}_baseline_{}".format(arch, opt)] = opt_flags
            if arch in ["x86_64", "armv7"]:
                baseline_copts["//:{}_clang_cl_baseline_{}".format(arch, opt)] = opt_cl_flags
                baseline_copts["//:{}_msvc_cl_baseline_{}".format(arch, opt)] = opt_cl_flags

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
                copts = OPENCV_COPTS +
                        OPENCV_OPTIMIZATION_COPTS +
                        _compiler_copts(
                            copts + _KNOWN_OPTS[arch][opt]["copts"],
                            cl_copts + _KNOWN_OPTS[arch][opt]["cl_copts"],
                        ),
                target_compatible_with = ["@platforms//cpu:{}".format(arch)],
                strip_include_prefix = prefix + "/include",
                features = [
                    "exceptions", # enable exceptions for opencv modules
                    "-ubsan",     # disable UBSAN for opencv modules
                ],
            )
            dispatched_targets["@platforms//cpu:{}".format(arch)].append(Label(":" + simd_target_name))
            for baseline_opt in CONFIGURABLE_BASELINES_BY_ARCH[arch]:
                dispatched_targets["//:{}_baseline_{}".format(arch, baseline_opt)].append(Label(":" + simd_target_name))

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
                _compiler_copts(copts, cl_copts) +
                select(baseline_copts),
        implementation_deps = [":" + name + "_generated_simd_headers"],
        linkopts = linkopts,
        local_defines = local_defines,
        target_compatible_with = compatible_with,
        strip_include_prefix = prefix + "/include",
        features = [
            "exceptions", # enable exceptions for opencv modules
            "-ubsan",     # disable UBSAN for opencv modules
        ],
        visibility = ["//visibility:public"],
    )

    if test_enabled:
        glob_test_srcs = [prefix + "/test/**/*.cpp", prefix + "/test/**/*.hpp"]

        if sources != None:
            # used by videoio and highgui modules
            full_test_sources = test_sources
        else:
            full_test_sources = native.glob(glob_test_srcs, exclude = test_srcs_excludes_globs)

        cc_test(
            name = name + "_test",
            srcs = full_test_sources,
            deps = [
                ":" + name,
                ":ts",
            ],
            copts = OPENCV_COPTS +
                    OPENCV_OPTIMIZATION_COPTS +
                    _compiler_copts(copts, cl_copts) +
                    select(baseline_copts),
            features = [
                "exceptions", # enable exceptions for opencv modules
                "-ubsan",     # disable UBSAN for opencv modules
            ],
        )
