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
    package_version = "1.11.876",
)

common_copts = [
    "-DPLATFORM_LINUX",
    "-DINTEL_NO_ITTNOTIFY_API",
    "-Wno-cast-align",
    "-Wno-cast-qual",
]

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

cc_library(
    name = "sts",
    srcs = glob(["generated/src/aws-cpp-sdk-sts/source/**/*.cpp"]),
    hdrs = glob(["generated/src/aws-cpp-sdk-sts/include/**/*.h"]),
    copts = common_copts,
    includes = ["generated/src/aws-cpp-sdk-sts/include"],
    target_compatible_with = ["@platforms//os:linux"],
    visibility = ["//visibility:public"],
    deps = [
        ":aws-c-auth",
        ":core",
    ],
)

cc_library(
    name = "cognito_identity",
    srcs = glob(["generated/src/aws-cpp-sdk-cognito-identity/source/**/*.cpp"]),
    hdrs = glob(["generated/src/aws-cpp-sdk-cognito-identity/include/**/*.h"]),
    copts = common_copts,
    includes = ["generated/src/aws-cpp-sdk-cognito-identity/include"],
    target_compatible_with = ["@platforms//os:linux"],
    visibility = ["//visibility:public"],
    deps = [":core"],
)

cc_library(
    name = "identity_management",
    srcs = glob(["src/aws-cpp-sdk-identity-management/source/**/*.cpp"]),
    hdrs = glob(["src/aws-cpp-sdk-identity-management/include/**/*.h"]),
    copts = common_copts,
    includes = ["src/aws-cpp-sdk-identity-management/include"],
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
    target_compatible_with = ["@platforms//os:linux"],
    visibility = ["//visibility:public"],
    deps = [
        ":core",
        ":s3",
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
        "src/aws-cpp-sdk-core/source/utils/crypto/crt/*.cpp",
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
        "src/aws-cpp-sdk-core/include/aws/core/utils/crypto/crt/*.h",
    ]),
    copts = common_copts + [
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
        "@curl",
        "@opentelemetry-cpp//api",
        "@opentelemetry-cpp//exporters/ostream:ostream_metric_exporter",
        "@opentelemetry-cpp//exporters/ostream:ostream_span_exporter",
        "@opentelemetry-cpp//sdk:headers",
    ] + crypto_deps,
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
    deps = [
        ":aws-c-common",
        ":aws-c-io",
        ":aws-checksums",
    ],
    visibility = ["//visibility:public"],
)

# gen_config leaves AWS_USE_CPU_EXTENSIONS undefined, so CRC dispatch uses
# software implementations. Unused ARM intrinsics must not impose a -march
# option that overrides the toolchain's architecture.
cc_library(
    name = "aws-checksums",
    srcs = glob([
        "crt/aws-crt-cpp/crt/aws-checksums/source/*.c",
    ]) + select({
        "@platforms//cpu:x86_64": glob(
            [
                "crt/aws-crt-cpp/crt/aws-checksums/source/intel/asm/*.c",
            ],
            allow_empty = True,
        ),
        "//conditions:default": [],
    }),
    hdrs = glob([
        "crt/aws-crt-cpp/crt/aws-checksums/include/**/*.h",
        "crt/aws-crt-cpp/crt/aws-checksums/source/external/*.h",
    ]),
    copts = common_copts + [
        "-Wno-implicit-function-declaration",
    ],
    includes = ["crt/aws-crt-cpp/crt/aws-checksums/include"],
    target_compatible_with = ["@platforms//os:linux"],
    deps = [
        ":aws-c-common",
    ],
    visibility = ["//visibility:public"],
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
    deps = [
        ":aws-c-common",
    ] + crypto_deps,
    visibility = ["//visibility:public"],
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
    visibility = ["//visibility:public"],
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
    visibility = ["//visibility:public"],
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
    visibility = ["//visibility:public"],
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
    visibility = ["//visibility:public"],
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
    visibility = ["//visibility:public"],
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
    visibility = ["//visibility:public"],
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
        "-DUSE_S2N",
        "-DAWS_USE_EPOLL",
        "-DAWS_ENABLE_EPOLL",
        "-Wno-sign-compare",
        "-Wno-unused-parameter",
    ],
    linkopts = ["-ldl"],
    includes = ["crt/aws-crt-cpp/crt/aws-c-io/include"],
    target_compatible_with = ["@platforms//os:linux"],
    deps = [
        ":aws-c-cal",
        ":aws-c-common",
        ":s2n",
    ],
    visibility = ["//visibility:public"],
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
    deps = crypto_deps,
    visibility = ["//visibility:public"],
)
