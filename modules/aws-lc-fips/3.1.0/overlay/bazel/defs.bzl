"""Native FIPS library variants using caller-supplied symbol prefixes."""

load("@aws-lc//bazel:fips.bzl", "aws_lc_fips_module")
load("@rules_cc//cc:defs.bzl", "cc_library")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

_PUBLIC_HEADERS = Label("//:public_headers")
_PRIVATE_HEADERS = Label("//:private_headers")
_MODULE_HEADERS = Label("//:module_headers")
_CRYPTO_SOURCES = Label("//:crypto_sources")
_SSL_SOURCES = Label("//:ssl_sources")
_FIPS_ASSEMBLY = Label("//:fips_assembly")
_ASSEMBLY_HEADERS = Label("//:assembly_headers")
_BCM = Label("//:crypto/fipsmodule/bcm.c")
_DELOCATE = Label("//:delocate")
_INJECT_HASH = Label("//:inject_hash")
_SUPPORTED = select({
    Label("//:linux_x86_64"): [],
    Label("//:linux_aarch64"): [],
    "//conditions:default": ["@platforms//:incompatible"],
})

def _prefixed_headers_impl(ctx):
    headers = []
    for src in ctx.files.hdrs:
        relative = src.path.split("/include/openssl/")[-1]
        if relative == src.path:
            relative = src.path.split("/generated-include/openssl/")[-1]
        if relative == src.path:
            fail("Expected an OpenSSL header: " + src.path)
        out = ctx.actions.declare_file(ctx.label.name + "/include/openssl/" + relative)
        ctx.actions.symlink(output = out, target_file = src)
        headers.append(out)
    include = headers[0].path.split("/include/openssl/")[0] + "/include"
    return [
        DefaultInfo(files = depset(headers)),
        CcInfo(compilation_context = cc_common.create_compilation_context(
            headers = depset(headers),
            includes = depset([include]),
            defines = depset(["BORINGSSL_PREFIX=" + ctx.attr.prefix]),
        )),
    ]

_prefixed_headers = rule(
    implementation = _prefixed_headers_impl,
    attrs = {
        "hdrs": attr.label_list(allow_files = True, mandatory = True),
        "prefix": attr.string(mandatory = True),
    },
)

def aws_lc_fips_libraries(name, prefix, prefix_headers, visibility = None):
    """Builds a prefixed crypto/SSL pair from this FIPS release.

    Args:
      name: Variant name; creates <name>_headers, <name>_crypto and <name>_ssl.
      prefix: Symbol namespace supplied by the consumer, without trailing underscore.
      prefix_headers: Matching C and assembly prefix headers supplied by the consumer.
      visibility: Visibility of the libraries and public headers.
    """
    if not prefix or not prefix_headers:
        fail("A prefixed variant requires both prefix and prefix_headers")
    headers = name + "_headers"
    bcm = name + "_bcm"
    crypto = name + "_crypto"
    _prefixed_headers(
        name = headers,
        hdrs = [_PUBLIC_HEADERS] + prefix_headers,
        prefix = prefix,
        visibility = visibility,
    )
    copts = ["-std=c11", "-D_XOPEN_SOURCE=700", "-fvisibility=hidden"]
    defines = ["BORINGSSL_FIPS", "FIPS_ENTROPY_SOURCE_PASSIVE"]
    aws_lc_fips_module(
        name = bcm,
        src = _BCM,
        asm_srcs = [_FIPS_ASSEMBLY],
        asm_headers = [_ASSEMBLY_HEADERS],
        copts = copts,
        defines = defines + ["BORINGSSL_IMPLEMENTATION", "S2N_BN_HIDE_SYMBOLS"],
        deps = [_MODULE_HEADERS],
        assembly_deps = [":" + headers, _PRIVATE_HEADERS],
        delocate = _DELOCATE,
        inject_hash = _INJECT_HASH,
        target_compatible_with = _SUPPORTED,
    )
    cc_library(
        name = crypto,
        srcs = [_CRYPTO_SOURCES, ":" + bcm],
        copts = copts,
        defines = defines,
        local_defines = ["BORINGSSL_IMPLEMENTATION", "S2N_BN_HIDE_SYMBOLS"],
        deps = [":" + headers, _PRIVATE_HEADERS],
        # Rust can append native archives after its standard-library runtime flags.
        linkopts = ["-pthread", "-lc", "-lgcc"],
        linkstatic = True,
        target_compatible_with = _SUPPORTED,
        visibility = visibility,
    )
    cc_library(
        name = name + "_ssl",
        srcs = [_SSL_SOURCES],
        local_defines = ["BORINGSSL_IMPLEMENTATION"],
        deps = [":" + crypto],
        linkstatic = True,
        target_compatible_with = _SUPPORTED,
        visibility = visibility,
    )
