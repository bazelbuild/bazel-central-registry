# Generated code. DO NOT EDIT.

load("@bazel_skylib//lib:selects.bzl", "selects")
load("@bazel_skylib//rules:common_settings.bzl", "bool_flag")

FEATURE_DEFINES = select({
    "//configs:argon2_disabled": ["-DOPENSSL_NO_ARGON2"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:aria_disabled": ["-DOPENSSL_NO_ARIA"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:async_disabled": ["-DOPENSSL_NO_ASYNC"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:atexit_disabled": ["-DOPENSSL_NO_ATEXIT"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:bf_disabled": ["-DOPENSSL_NO_BF"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:blake2_disabled": ["-DOPENSSL_NO_BLAKE2"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:brotli_dynamic_disabled": ["-DOPENSSL_NO_BROTLI_DYNAMIC"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:camellia_disabled": ["-DOPENSSL_NO_CAMELLIA"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:cast_disabled": ["-DOPENSSL_NO_CAST"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:chacha_disabled": ["-DOPENSSL_NO_CHACHA"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:cmac_disabled": ["-DOPENSSL_NO_CMAC"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:cmp_disabled": ["-DOPENSSL_NO_CMP"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:cms_disabled": ["-DOPENSSL_NO_CMS"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:comp_disabled": ["-DOPENSSL_NO_COMP"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:ct_disabled": ["-DOPENSSL_NO_CT"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:deprecated_disabled": ["-DOPENSSL_NO_DEPRECATED"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:des_disabled": ["-DOPENSSL_NO_DES"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:dh_disabled": ["-DOPENSSL_NO_DH"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:docs_disabled": ["-DOPENSSL_NO_DOCS"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:dsa_disabled": ["-DOPENSSL_NO_DSA"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:dtls_disabled": ["-DOPENSSL_NO_DTLS"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:dtls1_disabled": ["-DOPENSSL_NO_DTLS1"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:dtls1_method_disabled": ["-DOPENSSL_NO_DTLS1_METHOD"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:dtls1_2_disabled": ["-DOPENSSL_NO_DTLS1_2"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:dtls1_2_method_disabled": ["-DOPENSSL_NO_DTLS1_2_METHOD"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:ec_disabled": ["-DOPENSSL_NO_EC"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:ec2m_disabled": ["-DOPENSSL_NO_EC2M"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:ec_nistp_64_gcc_128_disabled": ["-DOPENSSL_NO_EC_NISTP_64_GCC_128"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:ecdh_disabled": ["-DOPENSSL_NO_ECDH"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:ecdsa_disabled": ["-DOPENSSL_NO_ECDSA"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:ecx_disabled": ["-DOPENSSL_NO_ECX"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:egd_disabled": ["-DOPENSSL_NO_EGD"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:engine_disabled": ["-DOPENSSL_NO_ENGINE"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:fips_jitter_disabled": ["-DOPENSSL_NO_FIPS_JITTER"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:gost_disabled": ["-DOPENSSL_NO_GOST"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:h3demo_disabled": ["-DOPENSSL_NO_H3DEMO"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:hqinterop_disabled": ["-DOPENSSL_NO_HQINTEROP"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:http_disabled": ["-DOPENSSL_NO_HTTP"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:idea_disabled": ["-DOPENSSL_NO_IDEA"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:jitter_disabled": ["-DOPENSSL_NO_JITTER"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:ktls_disabled": ["-DOPENSSL_NO_KTLS"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:md2_disabled": ["-DOPENSSL_NO_MD2"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:md4_disabled": ["-DOPENSSL_NO_MD4"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:mdc2_disabled": ["-DOPENSSL_NO_MDC2"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:ml_dsa_disabled": ["-DOPENSSL_NO_ML_DSA"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:ml_kem_disabled": ["-DOPENSSL_NO_ML_KEM"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:nextprotoneg_disabled": ["-DOPENSSL_NO_NEXTPROTONEG"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:ocb_disabled": ["-DOPENSSL_NO_OCB"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:ocsp_disabled": ["-DOPENSSL_NO_OCSP"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:pie_disabled": ["-DOPENSSL_NO_PIE"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:poly1305_disabled": ["-DOPENSSL_NO_POLY1305"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:psk_disabled": ["-DOPENSSL_NO_PSK"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:quic_disabled": ["-DOPENSSL_NO_QUIC"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:rc2_disabled": ["-DOPENSSL_NO_RC2"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:rc4_disabled": ["-DOPENSSL_NO_RC4"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:rc5_disabled": ["-DOPENSSL_NO_RC5"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:rfc3779_disabled": ["-DOPENSSL_NO_RFC3779"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:rmd160_disabled": ["-DOPENSSL_NO_RMD160"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:scrypt_disabled": ["-DOPENSSL_NO_SCRYPT"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:sctp_disabled": ["-DOPENSSL_NO_SCTP"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:seed_disabled": ["-DOPENSSL_NO_SEED"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:siphash_disabled": ["-DOPENSSL_NO_SIPHASH"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:siv_disabled": ["-DOPENSSL_NO_SIV"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:slh_dsa_disabled": ["-DOPENSSL_NO_SLH_DSA"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:sm2_disabled": ["-DOPENSSL_NO_SM2"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:sm2_precomp_disabled": ["-DOPENSSL_NO_SM2_PRECOMP"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:sm3_disabled": ["-DOPENSSL_NO_SM3"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:sm4_disabled": ["-DOPENSSL_NO_SM4"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:sock_disabled": ["-DOPENSSL_NO_SOCK"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:srp_disabled": ["-DOPENSSL_NO_SRP"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:srtp_disabled": ["-DOPENSSL_NO_SRTP"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:ssl_trace_disabled": ["-DOPENSSL_NO_SSL_TRACE"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:ssl3_disabled": ["-DOPENSSL_NO_SSL3"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:ssl3_method_disabled": ["-DOPENSSL_NO_SSL3_METHOD"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:sslkeylog_disabled": ["-DOPENSSL_NO_SSLKEYLOG"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:tfo_disabled": ["-DOPENSSL_NO_TFO"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:tls_deprecated_ec_disabled": ["-DOPENSSL_NO_TLS_DEPRECATED_EC"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:tls1_disabled": ["-DOPENSSL_NO_TLS1"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:tls1_method_disabled": ["-DOPENSSL_NO_TLS1_METHOD"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:tls1_1_disabled": ["-DOPENSSL_NO_TLS1_1"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:tls1_1_method_disabled": ["-DOPENSSL_NO_TLS1_1_METHOD"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:tls1_2_disabled": ["-DOPENSSL_NO_TLS1_2"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:tls1_2_method_disabled": ["-DOPENSSL_NO_TLS1_2_METHOD"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:tls1_3_disabled": ["-DOPENSSL_NO_TLS1_3"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:ts_disabled": ["-DOPENSSL_NO_TS"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:ui_console_disabled": ["-DOPENSSL_NO_UI_CONSOLE"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:unstable_qlog_disabled": ["-DOPENSSL_NO_UNSTABLE_QLOG"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:whirlpool_disabled": ["-DOPENSSL_NO_WHIRLPOOL"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:winstore_disabled": ["-DOPENSSL_NO_WINSTORE"],
    "//conditions:default": [],
}) + \
    select({
    "//configs:zstd_dynamic_disabled": ["-DOPENSSL_NO_ZSTD_DYNAMIC"],
    "//conditions:default": [],
})

def openssl_feature_flags():
    bool_flag(name = "no-argon2", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-aria", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-async", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-atexit", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-bf", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-blake2", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-brotli-dynamic", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-camellia", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-cast", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-chacha", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-cmac", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-cmp", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-cms", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-comp", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-ct", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-deprecated", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-des", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-dh", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-docs", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-dsa", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-dtls", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-dtls1", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-dtls1-method", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-dtls1_2", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-dtls1_2-method", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-ec", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-ec2m", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-ec_nistp_64_gcc_128", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-ecdh", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-ecdsa", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-ecx", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-egd", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-engine", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-fips-jitter", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-gost", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-h3demo", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-hqinterop", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-http", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-idea", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-jitter", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-ktls", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-md2", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-md4", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-mdc2", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-ml-dsa", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-ml-kem", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-nextprotoneg", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-ocb", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-ocsp", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-pie", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-poly1305", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-psk", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-quic", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-rc2", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-rc4", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-rc5", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-rfc3779", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-rmd160", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-scrypt", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-sctp", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-seed", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-siphash", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-siv", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-slh-dsa", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-sm2", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-sm2-precomp", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-sm3", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-sm4", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-sock", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-srp", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-srtp", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-ssl-trace", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-ssl3", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-ssl3-method", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-sslkeylog", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-tfo", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-tls-deprecated-ec", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-tls1", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-tls1-method", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-tls1_1", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-tls1_1-method", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-tls1_2", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-tls1_2-method", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-tls1_3", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-ts", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-ui-console", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-unstable-qlog", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-whirlpool", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-winstore", build_setting_default = False, visibility = ["//visibility:public"])
    bool_flag(name = "no-zstd-dynamic", build_setting_default = False, visibility = ["//visibility:public"])

def openssl_feature_config_settings():
    native.config_setting(
        name = "argon2_disabled",
        flag_values = {"//:no-argon2": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "aria_disabled",
        flag_values = {"//:no-aria": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "async_disabled",
        flag_values = {"//:no-async": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "atexit_disabled",
        flag_values = {"//:no-atexit": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "bf_disabled",
        flag_values = {"//:no-bf": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "blake2_disabled",
        flag_values = {"//:no-blake2": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "brotli_dynamic_disabled",
        flag_values = {"//:no-brotli-dynamic": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "camellia_disabled",
        flag_values = {"//:no-camellia": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "cast_disabled",
        flag_values = {"//:no-cast": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "chacha_disabled",
        flag_values = {"//:no-chacha": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "cmac_disabled",
        flag_values = {"//:no-cmac": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "cmp_disabled",
        flag_values = {"//:no-cmp": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "cms_disabled",
        flag_values = {"//:no-cms": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "comp_disabled",
        flag_values = {"//:no-comp": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "ct_disabled",
        flag_values = {"//:no-ct": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "deprecated_disabled",
        flag_values = {"//:no-deprecated": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "des_disabled",
        flag_values = {"//:no-des": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "dh_disabled",
        flag_values = {"//:no-dh": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "docs_disabled",
        flag_values = {"//:no-docs": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "dsa_disabled",
        flag_values = {"//:no-dsa": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "dtls_disabled",
        flag_values = {"//:no-dtls": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "dtls1_disabled",
        flag_values = {"//:no-dtls1": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "dtls1_method_disabled",
        flag_values = {"//:no-dtls1-method": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "dtls1_2_disabled",
        flag_values = {"//:no-dtls1_2": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "dtls1_2_method_disabled",
        flag_values = {"//:no-dtls1_2-method": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "ec_disabled",
        flag_values = {"//:no-ec": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "ec2m_disabled",
        flag_values = {"//:no-ec2m": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "ec_nistp_64_gcc_128_disabled",
        flag_values = {"//:no-ec_nistp_64_gcc_128": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "ecdh_disabled",
        flag_values = {"//:no-ecdh": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "ecdsa_disabled",
        flag_values = {"//:no-ecdsa": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "ecx_disabled",
        flag_values = {"//:no-ecx": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "egd_disabled",
        flag_values = {"//:no-egd": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "engine_disabled",
        flag_values = {"//:no-engine": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "fips_jitter_disabled",
        flag_values = {"//:no-fips-jitter": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "gost_disabled",
        flag_values = {"//:no-gost": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "h3demo_disabled",
        flag_values = {"//:no-h3demo": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "hqinterop_disabled",
        flag_values = {"//:no-hqinterop": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "http_disabled",
        flag_values = {"//:no-http": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "idea_disabled",
        flag_values = {"//:no-idea": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "jitter_disabled",
        flag_values = {"//:no-jitter": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "ktls_disabled",
        flag_values = {"//:no-ktls": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "md2_disabled",
        flag_values = {"//:no-md2": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "md4_disabled",
        flag_values = {"//:no-md4": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "mdc2_disabled",
        flag_values = {"//:no-mdc2": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "ml_dsa_disabled",
        flag_values = {"//:no-ml-dsa": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "ml_kem_disabled",
        flag_values = {"//:no-ml-kem": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "nextprotoneg_disabled",
        flag_values = {"//:no-nextprotoneg": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "ocb_disabled",
        flag_values = {"//:no-ocb": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "ocsp_disabled",
        flag_values = {"//:no-ocsp": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "pie_disabled",
        flag_values = {"//:no-pie": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "poly1305_disabled",
        flag_values = {"//:no-poly1305": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "psk_disabled",
        flag_values = {"//:no-psk": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "quic_disabled",
        flag_values = {"//:no-quic": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "rc2_disabled",
        flag_values = {"//:no-rc2": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "rc4_disabled",
        flag_values = {"//:no-rc4": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "rc5_disabled",
        flag_values = {"//:no-rc5": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "rfc3779_disabled",
        flag_values = {"//:no-rfc3779": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "rmd160_disabled",
        flag_values = {"//:no-rmd160": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "scrypt_disabled",
        flag_values = {"//:no-scrypt": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "sctp_disabled",
        flag_values = {"//:no-sctp": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "seed_disabled",
        flag_values = {"//:no-seed": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "siphash_disabled",
        flag_values = {"//:no-siphash": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "siv_disabled",
        flag_values = {"//:no-siv": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "slh_dsa_disabled",
        flag_values = {"//:no-slh-dsa": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "sm2_disabled",
        flag_values = {"//:no-sm2": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "sm2_precomp_disabled",
        flag_values = {"//:no-sm2-precomp": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "sm3_disabled",
        flag_values = {"//:no-sm3": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "sm4_disabled",
        flag_values = {"//:no-sm4": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "sock_disabled",
        flag_values = {"//:no-sock": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "srp_disabled",
        flag_values = {"//:no-srp": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "srtp_disabled",
        flag_values = {"//:no-srtp": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "ssl_trace_disabled",
        flag_values = {"//:no-ssl-trace": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "ssl3_disabled",
        flag_values = {"//:no-ssl3": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "ssl3_method_disabled",
        flag_values = {"//:no-ssl3-method": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "sslkeylog_disabled",
        flag_values = {"//:no-sslkeylog": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "tfo_disabled",
        flag_values = {"//:no-tfo": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "tls_deprecated_ec_disabled",
        flag_values = {"//:no-tls-deprecated-ec": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "tls1_disabled",
        flag_values = {"//:no-tls1": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "tls1_method_disabled",
        flag_values = {"//:no-tls1-method": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "tls1_1_disabled",
        flag_values = {"//:no-tls1_1": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "tls1_1_method_disabled",
        flag_values = {"//:no-tls1_1-method": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "tls1_2_disabled",
        flag_values = {"//:no-tls1_2": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "tls1_2_method_disabled",
        flag_values = {"//:no-tls1_2-method": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "tls1_3_disabled",
        flag_values = {"//:no-tls1_3": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "ts_disabled",
        flag_values = {"//:no-ts": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "ui_console_disabled",
        flag_values = {"//:no-ui-console": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "unstable_qlog_disabled",
        flag_values = {"//:no-unstable-qlog": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "whirlpool_disabled",
        flag_values = {"//:no-whirlpool": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "winstore_disabled",
        flag_values = {"//:no-winstore": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "zstd_dynamic_disabled",
        flag_values = {"//:no-zstd-dynamic": "True"},
        visibility = ["//visibility:public"],
    )

def openssl_pregen_config_settings():
    """Create config_setting targets for assembly and pre-generated file routing."""
    native.config_setting(
        name = "_no_asm_fallback",
        flag_values = {"//:use-no-asm-fallback": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_use_pregenerated",
        flag_values = {"//:use-pregenerated": "True"},
        visibility = ["//visibility:public"],
    )
    selects.config_setting_group(
        name = "_known_platform",
        match_any = [":android_arm64", ":android_x86_64", ":darwin_arm64", ":darwin_x86_64", ":freebsd_aarch64", ":freebsd_x86_64", ":ios_arm64", ":linux_aarch64", ":linux_arm", ":linux_ppc64le", ":linux_riscv64", ":linux_s390x", ":linux_x86_64", ":windows_arm64", ":windows_x64"],
        visibility = ["//visibility:public"],
    )
    selects.config_setting_group(
        name = "_pregen_enabled",
        match_all = [":_use_pregenerated", ":_known_platform"],
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_asm_android_arm64",
        constraint_values = ["@platforms//os:android", "@platforms//cpu:arm64"],
        flag_values = {"//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_asm_android_x86_64",
        constraint_values = ["@platforms//os:android", "@platforms//cpu:x86_64"],
        flag_values = {"//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_asm_darwin_arm64",
        constraint_values = ["@platforms//os:macos", "@platforms//cpu:arm64"],
        flag_values = {"//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_asm_darwin_x86_64",
        constraint_values = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        flag_values = {"//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_asm_freebsd_aarch64",
        constraint_values = ["@platforms//os:freebsd", "@platforms//cpu:aarch64"],
        flag_values = {"//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_asm_freebsd_x86_64",
        constraint_values = ["@platforms//os:freebsd", "@platforms//cpu:x86_64"],
        flag_values = {"//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_asm_ios_arm64",
        constraint_values = ["@platforms//os:ios", "@platforms//cpu:arm64"],
        flag_values = {"//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_asm_linux_aarch64",
        constraint_values = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        flag_values = {"//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_asm_linux_arm",
        constraint_values = ["@platforms//os:linux", "@platforms//cpu:arm"],
        flag_values = {"//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_asm_linux_ppc64le",
        constraint_values = ["@platforms//os:linux", "@platforms//cpu:ppc64le"],
        flag_values = {"//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_asm_linux_riscv64",
        constraint_values = ["@platforms//os:linux", "@platforms//cpu:riscv64"],
        flag_values = {"//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_asm_linux_s390x",
        constraint_values = ["@platforms//os:linux", "@platforms//cpu:s390x"],
        flag_values = {"//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_asm_linux_x86_64",
        constraint_values = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        flag_values = {"//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_asm_windows_arm64",
        constraint_values = ["@platforms//os:windows", "@platforms//cpu:arm64"],
        flag_values = {"//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_asm_windows_x64",
        constraint_values = ["@platforms//os:windows", "@platforms//cpu:x86_64"],
        flag_values = {"//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_android_arm64",
        constraint_values = ["@platforms//os:android", "@platforms//cpu:arm64"],
        flag_values = {"//:use-pregenerated": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_android_x86_64",
        constraint_values = ["@platforms//os:android", "@platforms//cpu:x86_64"],
        flag_values = {"//:use-pregenerated": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_darwin_arm64",
        constraint_values = ["@platforms//os:macos", "@platforms//cpu:arm64"],
        flag_values = {"//:use-pregenerated": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_darwin_x86_64",
        constraint_values = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        flag_values = {"//:use-pregenerated": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_freebsd_aarch64",
        constraint_values = ["@platforms//os:freebsd", "@platforms//cpu:aarch64"],
        flag_values = {"//:use-pregenerated": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_freebsd_x86_64",
        constraint_values = ["@platforms//os:freebsd", "@platforms//cpu:x86_64"],
        flag_values = {"//:use-pregenerated": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_ios_arm64",
        constraint_values = ["@platforms//os:ios", "@platforms//cpu:arm64"],
        flag_values = {"//:use-pregenerated": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_linux_aarch64",
        constraint_values = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        flag_values = {"//:use-pregenerated": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_linux_arm",
        constraint_values = ["@platforms//os:linux", "@platforms//cpu:arm"],
        flag_values = {"//:use-pregenerated": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_linux_ppc64le",
        constraint_values = ["@platforms//os:linux", "@platforms//cpu:ppc64le"],
        flag_values = {"//:use-pregenerated": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_linux_riscv64",
        constraint_values = ["@platforms//os:linux", "@platforms//cpu:riscv64"],
        flag_values = {"//:use-pregenerated": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_linux_s390x",
        constraint_values = ["@platforms//os:linux", "@platforms//cpu:s390x"],
        flag_values = {"//:use-pregenerated": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_linux_x86_64",
        constraint_values = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        flag_values = {"//:use-pregenerated": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_windows_arm64",
        constraint_values = ["@platforms//os:windows", "@platforms//cpu:arm64"],
        flag_values = {"//:use-pregenerated": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_windows_x64",
        constraint_values = ["@platforms//os:windows", "@platforms//cpu:x86_64"],
        flag_values = {"//:use-pregenerated": "True"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_asm_android_arm64",
        constraint_values = ["@platforms//os:android", "@platforms//cpu:arm64"],
        flag_values = {"//:use-pregenerated": "True", "//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_asm_android_x86_64",
        constraint_values = ["@platforms//os:android", "@platforms//cpu:x86_64"],
        flag_values = {"//:use-pregenerated": "True", "//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_asm_darwin_arm64",
        constraint_values = ["@platforms//os:macos", "@platforms//cpu:arm64"],
        flag_values = {"//:use-pregenerated": "True", "//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_asm_darwin_x86_64",
        constraint_values = ["@platforms//os:macos", "@platforms//cpu:x86_64"],
        flag_values = {"//:use-pregenerated": "True", "//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_asm_freebsd_aarch64",
        constraint_values = ["@platforms//os:freebsd", "@platforms//cpu:aarch64"],
        flag_values = {"//:use-pregenerated": "True", "//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_asm_freebsd_x86_64",
        constraint_values = ["@platforms//os:freebsd", "@platforms//cpu:x86_64"],
        flag_values = {"//:use-pregenerated": "True", "//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_asm_ios_arm64",
        constraint_values = ["@platforms//os:ios", "@platforms//cpu:arm64"],
        flag_values = {"//:use-pregenerated": "True", "//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_asm_linux_aarch64",
        constraint_values = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
        flag_values = {"//:use-pregenerated": "True", "//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_asm_linux_arm",
        constraint_values = ["@platforms//os:linux", "@platforms//cpu:arm"],
        flag_values = {"//:use-pregenerated": "True", "//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_asm_linux_ppc64le",
        constraint_values = ["@platforms//os:linux", "@platforms//cpu:ppc64le"],
        flag_values = {"//:use-pregenerated": "True", "//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_asm_linux_riscv64",
        constraint_values = ["@platforms//os:linux", "@platforms//cpu:riscv64"],
        flag_values = {"//:use-pregenerated": "True", "//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_asm_linux_s390x",
        constraint_values = ["@platforms//os:linux", "@platforms//cpu:s390x"],
        flag_values = {"//:use-pregenerated": "True", "//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
    native.config_setting(
        name = "_pregen_asm_linux_x86_64",
        constraint_values = ["@platforms//os:linux", "@platforms//cpu:x86_64"],
        flag_values = {"//:use-pregenerated": "True", "//:use-no-asm-fallback": "False"},
        visibility = ["//visibility:public"],
    )
