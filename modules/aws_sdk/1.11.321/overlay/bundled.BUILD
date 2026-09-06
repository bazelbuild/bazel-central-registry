# This BUILD file is a translation of the various CMakeLists.txt in the
# original source.
load("@rules_cc//cc:defs.bzl", "cc_library")
load("@rules_license//rules:license.bzl", "license")
load("//:compiler_select.bzl", "compiler_select")

package(default_applicable_licenses = [":license"])

license(
    name = "license",
    package_name = "AWS SDK for C++",
    license_kinds = ["@rules_license//licenses/spdx:Apache-2.0"],
    license_text = "LICENSE.txt",
    package_version = "1.11.321",
)

common_copts = [
    "-DPLATFORM_LINUX",
    "-DINTEL_NO_ITTNOTIFY_API",
    "-Wno-cast-align",
    "-Wno-cast-qual",
]

cc_library(
    name = "s3",
    srcs = glob(["generated/src/aws-cpp-sdk-s3/source/**/*.cpp"]),
    hdrs = glob(["generated/src/aws-cpp-sdk-s3/include/**/*.h"]),
    copts = common_copts,
    includes = ["generated/src/aws-cpp-sdk-s3/include"],
    target_compatible_with = ["@platforms//os:linux"],
    visibility = ["//visibility:public"],
    deps = [
        ":aws-c-auth",
        ":core",
    ],
)

genrule(
    name = "gen_SDKConfig",
    outs = ["src/aws-cpp-sdk-core/include/aws/core/SDKConfig.h"],
    cmd = "echo '#undef USE_AWS_MEMORY_MANAGEMENT' > $@",
    target_compatible_with = ["@platforms//os:linux"],
)

cc_library(
    name = "core",
    srcs = glob(
        include = ["src/aws-cpp-sdk-core/source/**/*.cpp"],
        exclude = [
            "src/aws-cpp-sdk-core/source/utils/crypto/*/*.cpp",
            "src/aws-cpp-sdk-core/source/platform/**/*.cpp",
            "src/aws-cpp-sdk-core/source/platform/windows/**/*.cpp",
            # net/*.cpp is for not-(linux or windows), so exclude everything in there.
            "src/aws-cpp-sdk-core/source/net/**/*.cpp",
            "src/aws-cpp-sdk-core/source/http/windows/**/*.cpp",
        ],
    ) + glob([
        "src/aws-cpp-sdk-core/source/utils/crypto/openssl/*.cpp",
        "src/aws-cpp-sdk-core/source/utils/crypto/factory/*.cpp",
        "src/aws-cpp-sdk-core/source/platform/linux-shared/**/*.cpp",
        "src/aws-cpp-sdk-core/source/net/linux-shared/*.cpp",
    ]) + [
        ":gen_SDKConfig",
    ],
    hdrs = glob(
        include = ["src/aws-cpp-sdk-core/include/**/*.h"],
        exclude = [
            "src/aws-cpp-sdk-core/include/aws/core/utils/crypto/*/*.h",
            "src/aws-cpp-sdk-core/include/aws/core/http/windows/**/*.h",
        ],
    ) + glob([
        "src/aws-cpp-sdk-core/include/aws/core/utils/crypto/openssl/*.h",
    ]),
    copts = common_copts + [
        "-DAWS_SDK_VERSION_MAJOR=10",
        "-DAWS_SDK_VERSION_MINOR=34",
        "-DAWS_SDK_VERSION_PATCH=\"\\\"BCR\"\\\"",
        "-DENABLE_OPENSSL_ENCRYPTION",
        "-DENABLE_CURL_CLIENT",
        "-Wno-format-nonliteral",
    ],
    includes = ["src/aws-cpp-sdk-core/include"],
    target_compatible_with = ["@platforms//os:linux"],
    visibility = ["//visibility:public"],
    deps = [
        ":aws-c-auth",
        ":aws-c-common",
        ":aws-c-http",
        ":crt",
        "@boringssl//:crypto",
        "@curl",
        "@opentelemetry-cpp//api",
        "@opentelemetry-cpp//exporters/ostream:ostream_metric_exporter",
        "@opentelemetry-cpp//exporters/ostream:ostream_span_exporter",
        "@opentelemetry-cpp//sdk:headers",
    ],
)

genrule(
    name = "gen_Config",
    outs = ["crt/aws-crt-cpp/include/aws/crt/Config.h"],
    cmd = "; ".join([
        "echo '#define AWS_CRT_CPP_VERSION \"1.11.321\"' > $@",
        "echo '#define AWS_CRT_CPP_VERSION_MAJOR 1' >> $@",
        "echo '#define AWS_CRT_CPP_VERSION_MINOR 11' >> $@",
        "echo '#define AWS_CRT_CPP_VERSION_PATCH 321' >> $@",
    ]),
    target_compatible_with = ["@platforms//os:linux"],
)

cc_library(
    name = "crt",
    srcs = glob(["crt/aws-crt-cpp/source/**/*.cpp"]),
    hdrs = glob(["crt/aws-crt-cpp/include/**/*.h"]) + [
        ":gen_Config",
    ],
    copts = common_copts + [
        "-Wno-sign-compare",
        "-Wno-tautological-type-limit-compare",
        "-Wno-missing-field-initializers",
    ],
    includes = ["crt/aws-crt-cpp/include"],
    target_compatible_with = ["@platforms//os:linux"],
    visibility = ["//visibility:public"],
    deps = [
        ":aws-c-auth",
        ":aws-c-common",
        ":aws-c-event-stream",
        ":aws-c-mqtt",
        ":aws-c-s3",
        ":aws-c-sdkutils",
    ],
)

genrule(
    name = "gen_config",
    outs = ["crt/aws-crt-cpp/crt/aws-c-common/include/aws/common/config.h"],
    cmd = "\n".join([
        "cat >$@ <<END",
        "#define AWS_HAVE_GCC_OVERFLOW_MATH_EXTENSIONS 1",
        "#define AWS_HAVE_GCC_INLINE_ASM 1",
        "#undef AWS_HAVE_MSVC_MULX",
        "#define AWS_HAVE_EXECINFO 1",
        "#define AWS_AFFINITY_METHOD 0",
        "END",
    ]),
    target_compatible_with = ["@platforms//os:linux"],
)

cc_library(
    name = "aws-c-common",
    srcs = glob([
        "crt/aws-crt-cpp/crt/aws-c-common/source/*.c",
        "crt/aws-crt-cpp/crt/aws-c-common/source/linux/*.c",
        "crt/aws-crt-cpp/crt/aws-c-common/source/external/*.c",
        "crt/aws-crt-cpp/crt/aws-c-common/source/posix/*.c",
    ]) + [
        ":gen_config",
    ] + select({
        "@platforms//cpu:aarch64": glob(
            [
                "crt/aws-crt-cpp/crt/aws-c-common/source/arch/arm/asm/*.c",
            ],
            allow_empty = True,
        ),
        "@platforms//cpu:armv7": glob(
            [
                "crt/aws-crt-cpp/crt/aws-c-common/source/arch/arm/asm/*.c",
            ],
            allow_empty = True,
        ),
        # See the paths in crt/aws-crt-cpp/crt/aws-c-common/CMakeLists.txt for the appropriate globs for each architecture.
        "@platforms//cpu:x86_64": glob(
            include = [
                "crt/aws-crt-cpp/crt/aws-c-common/source/arch/intel/*.c",
                "crt/aws-crt-cpp/crt/aws-c-common/source/arch/intel/asm/*.c",
            ],
            allow_empty = True,
            exclude = [
                # We don't build with AVX, see crt/aws-crt-cpp/crt/aws-c-common/CMakeLists.txt for details of the macros that need to be set if this is enabled.
                "crt/aws-crt-cpp/crt/aws-c-common/source/arch/intel/encoding_avx2.c",
            ],
        ),
        "//conditions:default": [],
    }),
    hdrs = glob(["crt/aws-crt-cpp/crt/aws-c-common/include/**/*.h"]) + ["crt/aws-crt-cpp/crt/aws-c-common/source/external/cJSON.h"],
    copts = common_copts + [
        "-Wno-sign-compare",
        "-Wno-format-nonliteral",
    ] + compiler_select({
        "clang": [],
        "gcc": [
            "-Wno-old-style-declaration",
        ],
    }),
    includes = [
        "crt/aws-crt-cpp/crt/aws-c-common/include",
        "crt/aws-crt-cpp/crt/aws-c-common/source",
    ],
    target_compatible_with = ["@platforms//os:linux"],
    textual_hdrs = glob(["crt/aws-crt-cpp/crt/aws-c-common/include/**/*.inl"]),
    visibility = ["//visibility:public"],
)

# -march=armv8-a+crc
cc_library(
    name = "aws-c-event-stream",
    srcs = glob(["crt/aws-crt-cpp/crt/aws-c-event-stream/source/*.c"]) + select({
        "@platforms//cpu:aarch64": glob(
            ["crt/aws-crt-cpp/crt/aws-c-event-stream/source/arm/*.c"],
            allow_empty = True,
        ),
        "@platforms//cpu:armv7": glob(
            ["crt/aws-crt-cpp/crt/aws-c-event-stream/source/arm/*.c"],
            allow_empty = True,
        ),
        "@platforms//cpu:x86_64": glob(
            ["crt/aws-crt-cpp/crt/aws-c-event-stream/source/intel/asm/*.c"],
            allow_empty = True,
        ),
        "//conditions:default": [],
    }),
    hdrs = glob(["crt/aws-crt-cpp/crt/aws-c-event-stream/include/**/*.h"]),
    copts = common_copts,
    includes = ["crt/aws-crt-cpp/crt/aws-c-event-stream/include"],
    deps = [
        ":aws-c-common",
        ":aws-c-io",
        ":aws-checksums",
    ],
)

cc_library(
    name = "aws-checksums",
    srcs = glob(["crt/aws-crt-cpp/crt/aws-checksums/source/*.c"]) + select({
        "@platforms//cpu:aarch64": glob(
            ["crt/aws-crt-cpp/crt/aws-checksums/source/arm/*.c"],
            allow_empty = True,
        ),
        "@platforms//cpu:armv7": glob(
            ["crt/aws-crt-cpp/crt/aws-checksums/source/arm/*.c"],
            allow_empty = True,
        ),
        "@platforms//cpu:x86_64": glob(
            ["crt/aws-crt-cpp/crt/aws-checksums/source/intel/asm/*.c"],
            allow_empty = True,
        ),
        "//conditions:default": [],
    }),
    hdrs = glob(["crt/aws-crt-cpp/crt/aws-checksums/include/**/*.h"]),
    copts = common_copts + [
        "-Wno-implicit-function-declaration",
    ],
    includes = ["crt/aws-crt-cpp/crt/aws-checksums/include"],
    target_compatible_with = ["@platforms//os:linux"],
    deps = [
        ":aws-c-common",
    ],
)

cc_library(
    name = "aws-c-cal",
    srcs = glob([
        "crt/aws-crt-cpp/crt/aws-c-cal/source/*.c",
        "crt/aws-crt-cpp/crt/aws-c-cal/source/unix/*.c",
    ]),
    hdrs = glob(["crt/aws-crt-cpp/crt/aws-c-cal/include/**/*.h"]),
    copts = common_copts + [
        #"-DOPENSSL_IS_AWSLC",
        "-Wno-incompatible-pointer-types",
        "-Wno-unused-function",
        "-Wno-unused-parameter",
    ],
    includes = ["crt/aws-crt-cpp/crt/aws-c-cal/include"],
    target_compatible_with = ["@platforms//os:linux"],
    deps = [
        ":aws-c-common",
        "@boringssl//:crypto",
    ],
)

cc_library(
    name = "aws-c-s3",
    srcs = glob(["crt/aws-crt-cpp/crt/aws-c-s3/source/**/*.c"]),
    hdrs = glob(["crt/aws-crt-cpp/crt/aws-c-s3/include/**/*.h"]),
    copts = common_copts,
    includes = ["crt/aws-crt-cpp/crt/aws-c-s3/include"],
    target_compatible_with = ["@platforms//os:linux"],
    deps = [
        ":aws-c-auth",
        ":aws-c-common",
        ":aws-checksums",
    ],
)

cc_library(
    name = "aws-c-compression",
    srcs = glob(["crt/aws-crt-cpp/crt/aws-c-compression/source/*.c"]),
    hdrs = glob(["crt/aws-crt-cpp/crt/aws-c-compression/include/**/*.h"]),
    copts = common_copts,
    includes = ["crt/aws-crt-cpp/crt/aws-c-compression/include"],
    target_compatible_with = ["@platforms//os:linux"],
    deps = [
        ":aws-c-common",
    ],
)

cc_library(
    name = "aws-c-http",
    srcs = glob(["crt/aws-crt-cpp/crt/aws-c-http/source/**/*.c"]),
    hdrs = glob(["crt/aws-crt-cpp/crt/aws-c-http/include/**/*.h"]),
    copts = common_copts + [
        "-Wno-unused-but-set-variable",
    ],
    includes = ["crt/aws-crt-cpp/crt/aws-c-http/include"],
    target_compatible_with = ["@platforms//os:linux"],
    textual_hdrs = glob(["crt/aws-crt-cpp/crt/aws-c-http/include/**/*.def"]),
    deps = [
        ":aws-c-common",
        ":aws-c-compression",
        ":aws-c-io",
    ],
)

cc_library(
    name = "aws-c-sdkutils",
    srcs = glob(["crt/aws-crt-cpp/crt/aws-c-sdkutils/source/**/*.c"]),
    hdrs = glob(["crt/aws-crt-cpp/crt/aws-c-sdkutils/include/**/*.h"]),
    copts = common_copts,
    includes = ["crt/aws-crt-cpp/crt/aws-c-sdkutils/include"],
    target_compatible_with = ["@platforms//os:linux"],
    deps = [
        ":aws-c-common",
    ],
)

cc_library(
    name = "aws-c-auth",
    srcs = glob(["crt/aws-crt-cpp/crt/aws-c-auth/source/**/*.c"]),
    hdrs = glob(["crt/aws-crt-cpp/crt/aws-c-auth/include/**/*.h"]),
    copts = common_copts,
    includes = ["crt/aws-crt-cpp/crt/aws-c-auth/include"],
    target_compatible_with = ["@platforms//os:linux"],
    deps = [
        ":aws-c-common",
        ":aws-c-http",
        ":aws-c-io",
        ":aws-c-sdkutils",
    ],
)

cc_library(
    name = "aws-c-mqtt",
    srcs = glob(["crt/aws-crt-cpp/crt/aws-c-mqtt/source/**/*.c"]),
    hdrs = glob(["crt/aws-crt-cpp/crt/aws-c-mqtt/include/**/*.h"]),
    copts = common_copts + [
        "-DAWS_MQTT_WITH_WEBSOCKETS",
    ],
    includes = ["crt/aws-crt-cpp/crt/aws-c-mqtt/include"],
    target_compatible_with = ["@platforms//os:linux"],
    deps = [
        ":aws-c-common",
        ":aws-c-http",
        ":aws-c-io",
    ],
)

cc_library(
    name = "aws-c-io",
    srcs = glob([
        "crt/aws-crt-cpp/crt/aws-c-io/source/*.c",
        "crt/aws-crt-cpp/crt/aws-c-io/source/linux/*.c",
        "crt/aws-crt-cpp/crt/aws-c-io/source/s2n/*.c",
        "crt/aws-crt-cpp/crt/aws-c-io/source/posix/*.c",
    ]),
    hdrs = glob(["crt/aws-crt-cpp/crt/aws-c-io/include/**/*.h"]) + [
        "crt/aws-crt-cpp/crt/aws-c-io/source/pkcs11_private.h",
    ] + glob([
        "crt/aws-crt-cpp/crt/aws-c-io/source/pkcs11/v2.40/*.h",
    ]),
    copts = common_copts + [
        "-DUSE_S2N",
        "-DAWS_USE_EPOLL",
        "-Wno-sign-compare",
        "-Wno-unused-parameter",
    ],
    includes = ["crt/aws-crt-cpp/crt/aws-c-io/include"],
    target_compatible_with = ["@platforms//os:linux"],
    deps = [
        ":aws-c-cal",
        ":aws-c-common",
        ":s2n",
    ],
)

cc_library(
    name = "s2n",
    srcs = glob(
        [
            "crt/aws-crt-cpp/crt/s2n/**/*.h",
            "crt/aws-crt-cpp/crt/s2n/tls/**/*.c",
            "crt/aws-crt-cpp/crt/s2n/error/**/*.c",
            "crt/aws-crt-cpp/crt/s2n/utils/**/*.c",
            "crt/aws-crt-cpp/crt/s2n/stuffer/**/*.c",
            "crt/aws-crt-cpp/crt/s2n/crypto/**/*.c",
            "crt/aws-crt-cpp/crt/s2n/pq-crypto/*.c",
        ],
        allow_empty = True,
    ),
    hdrs = ["crt/aws-crt-cpp/crt/s2n/api/s2n.h"],
    copts = common_copts + [
        "-DS2N_NO_PQ",
        "-Wno-unknown-pragmas",
        "-Wno-unused-parameter",
        "-Wno-sign-compare",
    ],
    includes = [
        "crt/aws-crt-cpp/crt/s2n",
        "crt/aws-crt-cpp/crt/s2n/api",
    ],
    target_compatible_with = ["@platforms//os:linux"],
    deps = [
        "@boringssl//:crypto",
    ],
)
