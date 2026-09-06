load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@rules_cc//cc:defs.bzl", "cc_library")

_OPENCV_COPTS = [
    "-D_USE_MATH_DEFINES",
    "-D__OPENCV_BUILD=1",
    "-D__STDC_CONSTANT_MACROS",
    "-D__STDC_FORMAT_MACROS",
    "-D__STDC_LIMIT_MACROS",
    "-I$(GENDIR)/external/opencv/private/",
]

_KNOWN_OPTS = [
    ("neon", "armeabihf"),
    ("vfpv3", "armeabihf"),
    ("avx", "x86_64"),
    ("avx2", "x86_64"),
    ("avx512_skx", "x86_64"),
    ("cuda", "x86_64"),
    ("fp16", "x86_64"),
    ("fp16", "armeabihf"),
    ("sse", "x86_64"),
    ("sse2", "x86_64"),
    ("sse3", "x86_64"),
    ("sse4_1", "x86_64"),
    ("sse4_2", "x86_64"),
    ("lasx", "x86_64"),
]

CONFIG = {
    "modules": [
        "calib3d",
        "core",  # lacks
        "features2d",
        "flann",  # lacks
        "imgcodecs",
        "imgproc",
    ],
    "stub_opencl": [
        "core",
        "imgproc",
        "features2d",
        "calib3d",
    ],
    "contains_src_headers": [
        "imgproc",
        "imgcodecs",
        "features2d",
        "calib3d",
    ],
}

def opencv_module(
        name,
        dispatched_files = {},
        deps = [],
        copts = [],
        **kwargs):
    """
    Creates a Bazel rule for an OpenCV module.

    Args:
        name: The name of the module.
        dispatched_files: A mapping of keys to a list of operators.
        deps: A list of dependencies for the module.
        copts: Additional compiler options.
        **kwargs: Additional arguments passed to the main cc_library target.
    """
    prefix = "modules/{}".format(name)
    dispatched_files = dispatched_files
    extra_headers = []

    enabled_opts_aarch64 = {}
    enabled_opts_x86_64 = {}
    for _, opts in dispatched_files.items():
        for opt in opts:
            enabled_opts_x86_64[opt] = True

    # Stub out opencl as all empty since we don't need to use any opencl functionality
    if name in CONFIG["stub_opencl"]:
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

    for fname, opts in dispatched_files.items():
        # Define file paths for SIMD declarations and SIMD header
        simd_declarations = "{}/src/{}.simd_declarations.hpp".format(prefix, fname)
        simd_filename = "{}/src/{}.simd.hpp".format(prefix, fname)

        simd_definitions_start = [
            "#define CV_CPU_SIMD_FILENAME \"{}\"".format(simd_filename),
        ]
        simd_opts = []
        for opt in opts:
            simd_opts += [
                "#define CV_CPU_DISPATCH_MODE {}".format(opt.upper()),
                "#include \"opencv2/core/private/cv_cpu_include_simd_declarations.hpp\"",
            ]

        dispatch_modes_simd = [
            "#define CV_CPU_DISPATCH_MODES_ALL " + ", ".join([x.upper() for x in reversed(opts) + ["BASELINE"]]),
        ]
        dispatch_modes_empty = [
            "#define CV_CPU_DISPATCH_MODES_ALL BASELINE",
        ]
        simd_definitions_end = ["#undef CV_CPU_SIMD_FILENAME"]
        extra_headers.append(simd_declarations)

        # Write the SIMD declarations to the file
        write_file(
            name = "_{}".format(simd_declarations),
            # note, simd_opts declarations are mainly for x86_64
            content = select({
                "@platforms//cpu:aarch64": simd_definitions_start + dispatch_modes_empty + simd_definitions_end,
                "@platforms//cpu:x86_64": simd_definitions_start + simd_opts + dispatch_modes_simd + simd_definitions_end,
            }),
            out = simd_declarations,
        )
    glob_srcs = [prefix + "/src/**/*.cpp", prefix + "/src/**/*.hpp"]
    if name in CONFIG["contains_src_headers"]:
        glob_srcs.append(prefix + "/src/**/*.h")
    cc_library(
        name = name,
        srcs = select({
            "@platforms//cpu:aarch64": native.glob(
                glob_srcs,
                exclude = [
                    prefix + "/src/**/*.{}.cpp".format(x[0])
                    for x in _KNOWN_OPTS
                    if x[0] not in enabled_opts_aarch64
                ],
            ),
            "@platforms//cpu:x86_64": native.glob(
                glob_srcs,
                exclude = [
                    prefix + "/src/**/*.{}.cpp".format(x[0])
                    for x in _KNOWN_OPTS
                    if x[0] not in enabled_opts_x86_64
                ],
            ),
        }),
        hdrs = native.glob([
            prefix + "/**/*.hpp",
            prefix + "/**/*.h",
        ]) + extra_headers,
        deps = deps + [":_base_headers"],
        includes = [
            prefix + "/include",
            prefix + "/src",
            prefix,
        ],
        copts = _OPENCV_COPTS + [
                    "-Iexternal/opencv/" + prefix + "/src",
                    "-I$(GENDIR)/external/opencv/" + prefix + "/src",
                ] + copts +
                select({
                    "@platforms//cpu:aarch64": [],
                    "@platforms//cpu:x86_64": [
                        "-msse",
                        "-msse2",
                        "-msse3",
                        "-mssse3",
                        "-msse4.1",
                        "-mpopcnt",
                        "-msse4.2",
                        "-mf16c",
                        "-mfma",
                        "-mavx",
                        "-mavx2",
                    ],
                }),
        **kwargs
    )
