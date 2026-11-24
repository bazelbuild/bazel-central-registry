# This BUILD file is a translation of the various CMakeLists.txt in the
# original source.
load("@bazel_skylib//lib:selects.bzl", "selects")
load("@rules_cc//cc:defs.bzl", "cc_library")
load("@rules_license//rules:license.bzl", "license")
load("//:compiler_select.bzl", "compiler_select")
load("//:components.bzl", "AWS_SDK_COMMON_COPTS", "AWS_SDK_SERVICES", "aws_sdk_target_name")

package(default_applicable_licenses = [":license"])

license(
    name = "license",
    package_name = "AWS SDK for C++",
    license_kinds = ["@rules_license//licenses/spdx:Apache-2.0"],
    license_text = "LICENSE.txt",
    package_version = "1.11.876",
)

common_copts = AWS_SDK_COMMON_COPTS

config_setting(
    name = "use_boringssl",
    flag_values = {"@curl//:ssl_lib": "boringssl"},
)

config_setting(
    name = "use_openssl",
    flag_values = {"@curl//:ssl_lib": "openssl"},
)

crypto_deps = select(
    {
        ":use_boringssl": ["@boringssl//:crypto"],
        ":use_openssl": ["@openssl//:crypto"],
    },
    no_match_error = "aws_sdk requires --@curl//:ssl_lib=boringssl or --@curl//:ssl_lib=openssl; other curl TLS backends are unsupported.",
)

# Each generated service client is built in its own repository, which is only
# fetched when a build uses that service.
[
    alias(
        name = aws_sdk_target_name(service),
        actual = "@aws_sdk_service_{0}//:{0}".format(aws_sdk_target_name(service)),
        visibility = ["//visibility:public"],
    )
    for service in AWS_SDK_SERVICES
]

cc_library(
    name = "identity_management",
    srcs = glob(["src/aws-cpp-sdk-identity-management/source/**/*.cpp"]),
    hdrs = glob(["src/aws-cpp-sdk-identity-management/include/**/*.h"]),
    copts = common_copts,
    includes = ["src/aws-cpp-sdk-identity-management/include"],
    linkstatic = True,
    target_compatible_with = ["@platforms//os:linux"],
    visibility = ["//visibility:public"],
    deps = [
        ":cognito_identity",
        ":core",
        ":sts",
    ],
)

cc_library(
    name = "transfer",
    srcs = glob(["src/aws-cpp-sdk-transfer/source/**/*.cpp"]),
    hdrs = glob(["src/aws-cpp-sdk-transfer/include/**/*.h"]),
    copts = common_copts,
    includes = ["src/aws-cpp-sdk-transfer/include"],
    linkstatic = True,
    target_compatible_with = ["@platforms//os:linux"],
    visibility = ["//visibility:public"],
    deps = [
        ":core",
        ":s3",
    ],
)

cc_library(
    name = "access_management",
    srcs = glob(["src/aws-cpp-sdk-access-management/source/**/*.cpp"]),
    hdrs = glob(["src/aws-cpp-sdk-access-management/include/**/*.h"]),
    copts = common_copts,
    includes = ["src/aws-cpp-sdk-access-management/include"],
    linkstatic = True,
    target_compatible_with = ["@platforms//os:linux"],
    visibility = ["//visibility:public"],
    deps = [
        ":cognito_identity",
        ":core",
        ":iam",
    ],
)

cc_library(
    name = "queues",
    srcs = glob(["src/aws-cpp-sdk-queues/source/**/*.cpp"]),
    hdrs = glob(["src/aws-cpp-sdk-queues/include/**/*.h"]),
    copts = common_copts,
    includes = ["src/aws-cpp-sdk-queues/include"],
    linkstatic = True,
    target_compatible_with = ["@platforms//os:linux"],
    visibility = ["//visibility:public"],
    deps = [
        ":core",
        ":sqs",
    ],
)

cc_library(
    name = "s3_encryption",
    srcs = glob(["src/aws-cpp-sdk-s3-encryption/source/**/*.cpp"]),
    hdrs = glob(["src/aws-cpp-sdk-s3-encryption/include/**/*.h"]),
    copts = common_copts,
    includes = ["src/aws-cpp-sdk-s3-encryption/include"],
    linkstatic = True,
    target_compatible_with = ["@platforms//os:linux"],
    visibility = ["//visibility:public"],
    deps = [
        ":core",
        ":kms",
        ":s3",
    ],
)

cc_library(
    name = "s3_transfer",
    srcs = glob(["src/aws-cpp-sdk-s3-transfer/source/**/*.cpp"]),
    hdrs = glob(["src/aws-cpp-sdk-s3-transfer/include/**/*.h"]),
    copts = common_copts,
    includes = ["src/aws-cpp-sdk-s3-transfer/include"],
    linkstatic = True,
    target_compatible_with = ["@platforms//os:linux"],
    visibility = ["//visibility:public"],
    deps = [
        ":core",
        ":s3",
    ],
)

# Without PulseAudio, which BCR does not provide, CMake builds text-to-speech
# with no platform audio driver; applications supply their own PCMOutputDriver.
cc_library(
    name = "text_to_speech",
    srcs = glob(["src/aws-cpp-sdk-text-to-speech/source/text-to-speech/*.cpp"]),
    hdrs = glob(["src/aws-cpp-sdk-text-to-speech/include/aws/text-to-speech/*.h"]),
    copts = common_copts,
    includes = ["src/aws-cpp-sdk-text-to-speech/include"],
    linkstatic = True,
    target_compatible_with = ["@platforms//os:linux"],
    visibility = ["//visibility:public"],
    deps = [
        ":core",
        ":polly",
    ],
)

# Build settings are declared in @aws_sdk//:BUILD.bazel. Each mirrors a CMake
# option of the SDK; see the README for the defaults.
[
    config_setting(
        name = "http_client_" + client,
        flag_values = {"@aws_sdk//:http_client": client},
    )
    for client in [
        "crt",
        "curl",
        "none",
    ]
]

[
    config_setting(
        name = "min_tls_version_" + version.replace(".", "_"),
        flag_values = {"@aws_sdk//:min_tls_version": version},
    )
    for version in [
        "1.0",
        "1.2",
        "1.3",
    ]
]

[
    config_setting(
        name = setting,
        flag_values = {"@aws_sdk//:" + setting: "true"},
    )
    for setting in [
        "curl_logging",
        "disable_imdsv1",
        "memory_management",
        "opentelemetry",
        "request_compression",
    ]
]

config_setting(
    name = "no_user_agent_customization",
    flag_values = {"@aws_sdk//:user_agent_customization": ""},
)

genrule(
    name = "gen_SDKConfig",
    outs = ["src/aws-cpp-sdk-core/include/aws/core/SDKConfig.h"],
    cmd = select({
        ":memory_management": "echo '#define USE_AWS_MEMORY_MANAGEMENT' > $@",
        "//conditions:default": "echo '#undef USE_AWS_MEMORY_MANAGEMENT' > $@",
    }),
    target_compatible_with = ["@platforms//os:linux"],
)

# The SDK C++ libraries set linkstatic. @curl//:curl hides its symbols and has
# no shared library, so a dynamically linked libcore.so (as in cc_test's
# default dynamic mode) fails at startup with undefined curl symbols. Every
# library that depends on core must then also be linked statically.

_CORE_SOURCES = "src/aws-cpp-sdk-core/source/"

_CORE_HEADERS = "src/aws-cpp-sdk-core/include/"

_CURL_CLIENT_SOURCES = [_CORE_SOURCES + "http/curl/*.cpp"]

_CRT_CLIENT_SOURCES = [_CORE_SOURCES + "http/crt/*.cpp"]

_OPENTELEMETRY_SOURCES = [_CORE_SOURCES + "smithy/tracing/impl/opentelemetry/*.cpp"]

_OPENTELEMETRY_HEADERS = [_CORE_HEADERS + "smithy/tracing/impl/opentelemetry/*.h"]

cc_library(
    name = "core",
    srcs = glob(
        include = [_CORE_SOURCES + "**/*.cpp"],
        exclude = [
            _CORE_SOURCES + "utils/crypto/*/*.cpp",
            _CORE_SOURCES + "platform/**/*.cpp",
            # net/*.cpp is for not-(linux or windows), so exclude everything in there.
            _CORE_SOURCES + "net/**/*.cpp",
            _CORE_SOURCES + "http/windows/**/*.cpp",
        ] + _CURL_CLIENT_SOURCES + _CRT_CLIENT_SOURCES + _OPENTELEMETRY_SOURCES,
    ) + glob([
        _CORE_SOURCES + "utils/crypto/crt/*.cpp",
        _CORE_SOURCES + "utils/crypto/factory/*.cpp",
        _CORE_SOURCES + "platform/linux-shared/**/*.cpp",
        _CORE_SOURCES + "net/linux-shared/*.cpp",
    ]) + select({
        ":http_client_crt": glob(_CRT_CLIENT_SOURCES),
        ":http_client_curl": glob(_CURL_CLIENT_SOURCES),
        ":http_client_none": [],
    }) + select({
        ":opentelemetry": glob(_OPENTELEMETRY_SOURCES),
        "//conditions:default": [],
    }) + [
        ":gen_SDKConfig",
    ],
    hdrs = glob(
        include = [_CORE_HEADERS + "**/*.h"],
        exclude = [
            _CORE_HEADERS + "aws/core/utils/crypto/*/*.h",
            _CORE_HEADERS + "aws/core/http/windows/**/*.h",
            _CORE_HEADERS + "aws/core/http/crt/*.h",
            _CORE_HEADERS + "aws/core/http/curl/*.h",
        ] + _OPENTELEMETRY_HEADERS,
    ) + glob([
        _CORE_HEADERS + "aws/core/utils/crypto/crt/*.h",
    ]) + select({
        ":http_client_crt": glob([_CORE_HEADERS + "aws/core/http/crt/*.h"]),
        ":http_client_curl": glob([_CORE_HEADERS + "aws/core/http/curl/*.h"]),
        ":http_client_none": [],
    }) + select({
        ":opentelemetry": glob(_OPENTELEMETRY_HEADERS),
        "//conditions:default": [],
    }),
    copts = common_copts + [
        "-Wno-format-nonliteral",
    ],
    # DISABLE_IMDSV1 changes a class declared in a public header, so it must be
    # visible to every library that includes core.
    defines = select({
        ":disable_imdsv1": ["DISABLE_IMDSV1"],
        "//conditions:default": [],
    }),
    includes = ["src/aws-cpp-sdk-core/include"],
    local_defines = [
        "AWS_HAS_ALIGNED_ALLOC",
    ] + select({
        ":http_client_crt": [
            "AWS_SDK_USE_CRT_HTTP",
            "HAVE_H2_CLIENT",
        ],
        ":http_client_curl": ["ENABLE_CURL_CLIENT"],
        ":http_client_none": [],
    }) + select({
        ":curl_logging": ["ENABLE_CURL_LOGGING"],
        "//conditions:default": [],
    }) + select({
        ":min_tls_version_1_0": [],
        ":min_tls_version_1_2": ["ENFORCE_TLS_V1_2"],
        ":min_tls_version_1_3": ["ENFORCE_TLS_V1_3"],
    }) + select({
        ":request_compression": [
            "ENABLED_REQUEST_COMPRESSION",
            "ENABLED_ZLIB_REQUEST_COMPRESSION",
        ],
        "//conditions:default": [],
    }) + select({
        ":no_user_agent_customization": [],
        "//conditions:default": ["AWS_USER_AGENT_CUSTOMIZATION=$(AWS_USER_AGENT_CUSTOMIZATION)"],
    }),
    linkstatic = True,
    target_compatible_with = ["@platforms//os:linux"],
    toolchains = ["@aws_sdk//:user_agent_customization_variable"],
    visibility = ["//visibility:public"],
    deps = [
        ":aws-c-auth",
        ":aws-c-common",
        ":aws-c-http",
        ":crt",
    ] + select({
        ":http_client_curl": ["@curl"],
        "//conditions:default": [],
    }) + select({
        ":opentelemetry": [
            "@opentelemetry-cpp//api",
            "@opentelemetry-cpp//exporters/ostream:ostream_metric_exporter",
            "@opentelemetry-cpp//exporters/ostream:ostream_span_exporter",
            "@opentelemetry-cpp//sdk:headers",
        ],
        "//conditions:default": [],
    }) + select({
        ":request_compression": ["@zlib"],
        "//conditions:default": [],
    }) + crypto_deps,
)

genrule(
    name = "gen_Config",
    outs = ["crt/aws-crt-cpp/include/aws/crt/Config.h"],
    cmd = "; ".join([
        "echo '#define AWS_CRT_CPP_VERSION \"0.43.4\"' > $@",
        "echo '#define AWS_CRT_CPP_VERSION_MAJOR 0' >> $@",
        "echo '#define AWS_CRT_CPP_VERSION_MINOR 43' >> $@",
        "echo '#define AWS_CRT_CPP_VERSION_PATCH 4' >> $@",
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
        "crt/aws-crt-cpp/crt/aws-c-common/source/external/libcbor/*.c",
        "crt/aws-crt-cpp/crt/aws-c-common/source/external/libcbor/cbor/*.c",
        "crt/aws-crt-cpp/crt/aws-c-common/source/external/libcbor/cbor/internal/*.c",
        "crt/aws-crt-cpp/crt/aws-c-common/source/posix/*.c",
    ]) + [
        ":gen_config",
    ] + select({
        "@platforms//cpu:aarch64": glob(
            [
                "crt/aws-crt-cpp/crt/aws-c-common/source/arch/arm/auxv/*.c",
            ],
            allow_empty = True,
        ),
        "@platforms//cpu:armv7": glob(
            [
                "crt/aws-crt-cpp/crt/aws-c-common/source/arch/arm/auxv/*.c",
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
    hdrs = glob([
        "crt/aws-crt-cpp/crt/aws-c-common/include/**/*.h",
        "crt/aws-crt-cpp/crt/aws-c-common/source/external/libcbor/**/*.h",
    ]) + ["crt/aws-crt-cpp/crt/aws-c-common/source/external/cJSON.h"],
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
        "crt/aws-crt-cpp/crt/aws-c-common",
        "crt/aws-crt-cpp/crt/aws-c-common/include",
        "crt/aws-crt-cpp/crt/aws-c-common/source",
        "crt/aws-crt-cpp/crt/aws-c-common/source/external/libcbor",
        "crt/aws-crt-cpp/crt/aws-c-common/source/external/libcbor/cbor/internal",
    ],
    linkopts = [
        "-ldl",
        "-pthread",
    ],
    target_compatible_with = ["@platforms//os:linux"],
    textual_hdrs = glob(["crt/aws-crt-cpp/crt/aws-c-common/include/**/*.inl"]),
    visibility = ["//visibility:public"],
)

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
    visibility = ["//visibility:public"],
    deps = [
        ":aws-c-common",
        ":aws-c-io",
        ":aws-checksums",
    ],
)

# PCLMUL is not implied by any x86-64 level, nor is VPCLMUL by v4.
# The SSE assembly also uses PCLMUL for its large-buffer path.
selects.config_setting_group(
    name = "checksums_x86_sse42",
    match_all = [
        "@platforms_contrib//cpu/x86_64:at_least_v2",
        "@platforms_contrib//cpu/x86_64/feature:pclmul",
    ],
)

selects.config_setting_group(
    name = "checksums_x86_clmul",
    match_all = [
        ":checksums_x86_sse42",
        "@platforms_contrib//cpu/x86_64:at_least_v3",
    ],
)

selects.config_setting_group(
    name = "checksums_x86_avx512",
    match_all = [
        ":checksums_x86_clmul",
        "@platforms_contrib//cpu/x86_64:at_least_v4",
        "@platforms_contrib//cpu/x86_64/feature:vpclmulqdq",
    ],
)

# These are private to checksums: enabling them globally would also enable
# unrelated aws-c-common intrinsics that are not built with their ISA flags.
_CHECKSUMS_DEFINES = select({
    ":checksums_x86_sse42": [
        "AWS_USE_CPU_EXTENSIONS",
        "AWS_ARCH_INTEL",
        "AWS_ARCH_INTEL_X64",
    ],
    "@platforms//cpu:aarch64": [
        "AWS_USE_CPU_EXTENSIONS",
        "AWS_ARCH_ARM64",
        "AWS_HAVE_ARMv8_1",
    ],
    "//conditions:default": [],
}) + select({
    ":checksums_x86_clmul": [
        "AWS_HAVE_CLMUL",
        "AWS_HAVE_AVX2_INTRINSICS",
    ],
    "//conditions:default": [],
}) + select({
    ":checksums_x86_avx512": ["AWS_HAVE_AVX512_INTRINSICS"],
    "//conditions:default": [],
})

_CHECKSUMS_COPTS = common_copts + ["-Wno-implicit-function-declaration"]

cc_library(
    name = "aws-checksums-headers",
    hdrs = glob([
        "crt/aws-crt-cpp/crt/aws-checksums/include/**/*.h",
        "crt/aws-crt-cpp/crt/aws-checksums/source/external/*.h",
    ]),
    includes = ["crt/aws-crt-cpp/crt/aws-checksums/include"],
    target_compatible_with = ["@platforms//os:linux"],
    deps = [":aws-c-common"],
)

# ISA flags apply only to the selected intrinsic implementations. In particular,
# the ARM -march must not override the toolchain architecture for the dispatcher
# or for any other bundled library. AWS still checks CPU features at runtime.
cc_library(
    name = "aws-checksums-x86_64",
    srcs = [
        "crt/aws-crt-cpp/crt/aws-checksums/source/intel/asm/crc32c_sse42_asm.c",
        "crt/aws-crt-cpp/crt/aws-checksums/source/intel/intrin/crc32c_sse42_avx512.c",
    ] + select({
        ":checksums_x86_clmul": ["crt/aws-crt-cpp/crt/aws-checksums/source/intel/intrin/crc64nvme_clmul.c"],
        "//conditions:default": [],
    }) + select({
        ":checksums_x86_avx512": ["crt/aws-crt-cpp/crt/aws-checksums/source/intel/intrin/crc64nvme_avx512.c"],
        "//conditions:default": [],
    }),
    copts = _CHECKSUMS_COPTS + [
        "-msse4.2",
        "-mpclmul",
    ] + select({
        ":checksums_x86_clmul": ["-mavx2"],
        "//conditions:default": [],
    }) + select({
        ":checksums_x86_avx512": [
            "-mavx512f",
            "-mavx512vl",
            "-mvpclmulqdq",
        ],
        "//conditions:default": [],
    }),
    local_defines = _CHECKSUMS_DEFINES,
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ] + select({
        ":checksums_x86_sse42": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
    deps = [":aws-checksums-headers"],
)

cc_library(
    name = "aws-checksums-aarch64",
    srcs = [
        "crt/aws-crt-cpp/crt/aws-checksums/source/arm/crc32c_arm.c",
        "crt/aws-crt-cpp/crt/aws-checksums/source/arm/crc64_arm.c",
    ],
    copts = _CHECKSUMS_COPTS + ["-march=armv8-a+crc+crypto"],
    local_defines = _CHECKSUMS_DEFINES,
    target_compatible_with = [
        "@platforms//os:linux",
        "@platforms//cpu:aarch64",
    ],
    deps = [":aws-checksums-headers"],
)

cc_library(
    name = "aws-checksums",
    srcs = glob(["crt/aws-crt-cpp/crt/aws-checksums/source/*.c"]),
    copts = _CHECKSUMS_COPTS,
    local_defines = _CHECKSUMS_DEFINES,
    target_compatible_with = ["@platforms//os:linux"],
    visibility = ["//visibility:public"],
    deps = [
        ":aws-c-common",
        ":aws-checksums-headers",
    ] + select({
        ":checksums_x86_sse42": [":aws-checksums-x86_64"],
        "@platforms//cpu:aarch64": [":aws-checksums-aarch64"],
        "//conditions:default": [],
    }),
)

cc_library(
    name = "aws-c-cal",
    srcs = glob([
        "crt/aws-crt-cpp/crt/aws-c-cal/source/*.c",
        "crt/aws-crt-cpp/crt/aws-c-cal/source/unix/*.c",
    ]) + [
        "crt/aws-crt-cpp/crt/aws-c-cal/source/shared/ed25519.c",
        "crt/aws-crt-cpp/crt/aws-c-cal/source/shared/lccrypto_common.c",
        "crt/aws-crt-cpp/crt/aws-c-cal/source/shared/ref_hkdf.c",
    ],
    hdrs = glob(["crt/aws-crt-cpp/crt/aws-c-cal/include/**/*.h"]),
    copts = common_copts + [
        #"-DOPENSSL_IS_AWSLC",
        "-Wno-incompatible-pointer-types",
        "-Wno-unused-function",
        "-Wno-unused-parameter",
    ],
    includes = ["crt/aws-crt-cpp/crt/aws-c-cal/include"],
    target_compatible_with = ["@platforms//os:linux"],
    visibility = ["//visibility:public"],
    deps = [
        ":aws-c-common",
    ] + crypto_deps,
)

cc_library(
    name = "aws-c-s3",
    srcs = glob(["crt/aws-crt-cpp/crt/aws-c-s3/source/**/*.c"]),
    hdrs = glob(["crt/aws-crt-cpp/crt/aws-c-s3/include/**/*.h"]),
    copts = common_copts,
    includes = ["crt/aws-crt-cpp/crt/aws-c-s3/include"],
    target_compatible_with = ["@platforms//os:linux"],
    visibility = ["//visibility:public"],
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
    visibility = ["//visibility:public"],
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
    visibility = ["//visibility:public"],
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
    visibility = ["//visibility:public"],
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
    visibility = ["//visibility:public"],
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
    visibility = ["//visibility:public"],
    deps = [
        ":aws-c-common",
        ":aws-c-http",
        ":aws-c-io",
    ],
)

cc_library(
    name = "aws-c-io",
    srcs = glob(
        [
            "crt/aws-crt-cpp/crt/aws-c-io/source/*.c",
            "crt/aws-crt-cpp/crt/aws-c-io/source/linux/*.c",
            "crt/aws-crt-cpp/crt/aws-c-io/source/s2n/*.c",
            "crt/aws-crt-cpp/crt/aws-c-io/source/posix/*.c",
        ],
        exclude = ["crt/aws-crt-cpp/crt/aws-c-io/source/s2n/s2n_apple_keychain.c"],
    ),
    hdrs = glob(["crt/aws-crt-cpp/crt/aws-c-io/include/**/*.h"]) + [
        "crt/aws-crt-cpp/crt/aws-c-io/source/pkcs11_private.h",
        "crt/aws-crt-cpp/crt/aws-c-io/source/s2n/s2n_apple_keychain.h",
    ] + glob([
        "crt/aws-crt-cpp/crt/aws-c-io/source/pkcs11/v2.40/*.h",
    ]),
    copts = common_copts + [
        # Compiles out the Intel ITT tracing calls in aws/io/private/tracing.h.
        "-DINTEL_NO_ITTNOTIFY_API",
        "-DUSE_S2N",
        "-DAWS_USE_EPOLL",
        "-DAWS_ENABLE_EPOLL",
        "-Wno-sign-compare",
        "-Wno-unused-parameter",
    ],
    includes = ["crt/aws-crt-cpp/crt/aws-c-io/include"],
    linkopts = ["-ldl"],
    target_compatible_with = ["@platforms//os:linux"],
    visibility = ["//visibility:public"],
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
            "crt/aws-crt-cpp/crt/s2n/tls/**/*.c",
            "crt/aws-crt-cpp/crt/s2n/error/**/*.c",
            "crt/aws-crt-cpp/crt/s2n/utils/**/*.c",
            "crt/aws-crt-cpp/crt/s2n/stuffer/**/*.c",
            "crt/aws-crt-cpp/crt/s2n/crypto/**/*.c",
            "crt/aws-crt-cpp/crt/s2n/pq-crypto/*.c",
        ],
        allow_empty = True,
    ),
    hdrs = glob(["crt/aws-crt-cpp/crt/s2n/**/*.h"]),
    copts = common_copts + [
        "-DS2N_NO_PQ",
        "-include",
        "crt/aws-crt-cpp/crt/s2n/utils/s2n_prelude.h",
        "-Wno-unknown-pragmas",
        "-Wno-unused-parameter",
        "-Wno-sign-compare",
    ],
    includes = [
        "crt/aws-crt-cpp/crt/s2n",
        "crt/aws-crt-cpp/crt/s2n/api",
    ],
    target_compatible_with = ["@platforms//os:linux"],
    visibility = ["//visibility:public"],
    deps = crypto_deps,
)
