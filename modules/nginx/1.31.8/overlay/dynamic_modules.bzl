"""Build the nginx module tables and Ubuntu's loadable nginx modules."""

load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("@rules_cc//cc:cc_binary.bzl", "cc_binary")
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
load("@with_cfg.bzl", "with_cfg")
load(":nginx_sources.bzl", "HTTP_FILTER_MODULES")

# ngx_module_order in auto/modules determines the HTTP filter execution order.
NGINX_HTTP_MODULE_ORDER = [
    "ngx_http_static_module",
    "ngx_http_gzip_static_module",
    "ngx_http_dav_module",
    "ngx_http_autoindex_module",
    "ngx_http_index_module",
    "ngx_http_random_index_module",
    "ngx_http_access_module",
    "ngx_http_realip_module",
] + HTTP_FILTER_MODULES

_MAIL_MODULES = [
    "ngx_mail_module",
    "ngx_mail_core_module",
    "ngx_mail_ssl_module",
    "ngx_mail_pop3_module",
    "ngx_mail_imap_module",
    "ngx_mail_smtp_module",
    "ngx_mail_auth_http_module",
    "ngx_mail_proxy_module",
    "ngx_mail_realip_module",
]

_STREAM_MODULES = [
    "ngx_stream_module",
    "ngx_stream_core_module",
    "ngx_stream_log_module",
    "ngx_stream_proxy_module",
    "ngx_stream_upstream_module",
    "ngx_stream_write_filter_module",
    "ngx_stream_ssl_module",
    "ngx_stream_realip_module",
    "ngx_stream_limit_conn_module",
    "ngx_stream_access_module",
    "ngx_stream_geo_module",
    "ngx_stream_map_module",
    "ngx_stream_split_clients_module",
    "ngx_stream_return_module",
    "ngx_stream_pass_module",
    "ngx_stream_set_module",
    "ngx_stream_upstream_hash_module",
    "ngx_stream_upstream_least_conn_module",
    "ngx_stream_upstream_least_time_module",
    "ngx_stream_upstream_random_module",
    "ngx_stream_upstream_zone_module",
    "ngx_stream_ssl_preread_module",
]

def _module_array(declaration, values):
    return [declaration + "[] = {"] + ["    %s," % value for value in values] + ["    NULL", "};", ""]

def nginx_module_table(name, modules, order = None):
    """Write the ngx_module_t pointers and names exported by nginx or a module.

    Args:
        name: Output C file basename.
        modules: ngx_module_t symbols in initialization order.
        order: ngx_module_order entries for a shared object. Omit for the executable.
    """
    content = [
        "#include <ngx_config.h>",
        "#include <ngx_core.h>",
        "",
    ] + ["extern ngx_module_t %s;" % m for m in modules] + [""]
    content += _module_array("ngx_module_t *ngx_modules", ["&" + m for m in modules])
    content += _module_array("char *ngx_module_names", ['"%s"' % m for m in modules])
    if order != None:
        content += _module_array("char *ngx_module_order", ['"%s"' % m for m in order])
    write_file(name = name, out = name + ".c", content = content, newline = "unix")

def nginx_dynamic_module(name, srcs, modules = None, order = [], deps = []):
    """Build a shared object that nginx can load with the load_module directive.

    Args:
        name: Shared object basename and first module symbol.
        srcs: nginx module C sources.
        modules: ngx_module_t symbols exported by the shared object. Defaults to [name].
        order: ngx_module_order entries used by ngx_add_module().
        deps: Additional libraries used by the module.
    """
    nginx_module_table(name + "_modules", modules or [name], order)
    cc_binary(
        name = name + ".so",
        srcs = srcs + [":" + name + "_modules"],
        deps = [":nginx_headers"] + deps,
        linkshared = True,
        linkstatic = True,
        visibility = ["//visibility:public"],
    )

# libgd disables these codecs by default. ngx_http_image_filter_module handles
# JPEG, GIF, PNG, and WebP. GIF support is built into libgd.
# buildifier: disable=unused-variable
_image_filter_gd, _image_filter_gd_internal = with_cfg(
    native.alias,
    extra_providers = [CcInfo],
).set(Label("@libgd//:enable_jpeg"), True).set(
    Label("@libgd//:enable_png"),
    True,
).set(
    Label("@libgd//:enable_webp"),
    True,
).set(
    Label("@libgd//:enable_zlib"),
    True,
).build()

def nginx_dynamic_modules():
    """Declare mail, stream, GeoIP, image filter and XSLT loadable modules."""
    nginx_dynamic_module(
        name = "ngx_mail_module",
        srcs = native.glob(["src/mail/*.c"]),
        modules = _MAIL_MODULES,
    )
    nginx_dynamic_module(
        name = "ngx_stream_module",
        srcs = native.glob(["src/stream/*.c"], exclude = ["src/stream/ngx_stream_geoip_module.c"]),
        modules = _STREAM_MODULES,
    )
    nginx_dynamic_module(
        name = "ngx_http_geoip_module",
        srcs = ["src/http/modules/ngx_http_geoip_module.c"],
        order = NGINX_HTTP_MODULE_ORDER,
        deps = ["@nginx_geoip//:geoip"],
    )
    nginx_dynamic_module(
        name = "ngx_stream_geoip_module",
        srcs = ["src/stream/ngx_stream_geoip_module.c"],
        deps = ["@nginx_geoip//:geoip"],
    )
    _image_filter_gd(name = "image_filter_gd", actual = "@libgd")
    nginx_dynamic_module(
        name = "ngx_http_image_filter_module",
        srcs = ["src/http/modules/ngx_http_image_filter_module.c"],
        order = NGINX_HTTP_MODULE_ORDER,
        deps = [":image_filter_gd"],
    )
    nginx_dynamic_module(
        name = "ngx_http_xslt_filter_module",
        srcs = ["src/http/modules/ngx_http_xslt_filter_module.c"],
        order = NGINX_HTTP_MODULE_ORDER,
        deps = ["@libxml2", "@libxslt//libexslt", "@libxslt//libxslt"],
    )
