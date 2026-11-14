"""Build ngx_http_perl_module.so and its Perl XS extension."""

load("@bazel_skylib//rules:expand_template.bzl", "expand_template")
load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("//:dynamic_modules.bzl", "NGINX_HTTP_MODULE_ORDER", "nginx_dynamic_module")
load(":xsubpp.bzl", "perl_xsubpp")

def _perl_target(name):
    return select({
        ":linux_aarch64": "@nginx_perl_aarch64//:" + name,
        "//conditions:default": "@nginx_perl_x86_64//:" + name,
    })

def nginx_perl_module():
    """Declare the nginx Perl module, XS extension, and installable Perl files."""
    for name in ["headers", "libperl", "stdlib", "strict_pm", "config_pm"]:
        native.alias(
            name = "perl_" + name,
            actual = _perl_target(name),
            visibility = ["//visibility:public"] if name in ["stdlib", "strict_pm", "config_pm"] else ["//visibility:private"],
        )
    cc_library(
        name = "nginx_perl_headers",
        hdrs = ["src/http/modules/perl/ngx_http_perl_module.h"],
        includes = ["src/http/modules/perl"],
        deps = [":nginx_headers", ":perl_headers"],
    )
    nginx_dynamic_module(
        name = "ngx_http_perl_module",
        srcs = ["src/http/modules/perl/ngx_http_perl_module.c"],
        order = NGINX_HTTP_MODULE_ORDER,
        local_defines = ["NGX_HAVE_PERL_MULTIPLICITY=1"],
        deps = [":nginx_perl_headers", ":perl_libperl"],
    )
    perl_xsubpp(
        name = "nginx_xs",
        src = "src/http/modules/perl/nginx.xs",
        typemaps = ["src/http/modules/perl/typemap"],
    )
    cc_binary(
        name = "perl_modules/auto/nginx/nginx.so",
        srcs = [":nginx_xs"],
        local_defines = ['XS_VERSION=\\"1.31.8\\"'],
        linkshared = True,
        linkstatic = True,
        deps = [":nginx_perl_headers"],
    )
    expand_template(
        name = "perl_nginx_pm",
        template = "src/http/modules/perl/nginx.pm",
        out = "perl_modules/nginx.pm",
        substitutions = {"%%VERSION%%": "1.31.8"},
        visibility = ["//visibility:public"],
    )
    native.filegroup(
        name = "perl_runtime",
        srcs = [":perl_nginx_pm", ":perl_modules/auto/nginx/nginx.so", ":perl_stdlib"],
        visibility = ["//visibility:public"],
    )
