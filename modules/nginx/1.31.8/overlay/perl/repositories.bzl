"""Build Perl 5.44.0 for embedding using portable-perl's matching headers and standard library."""

# Released together at https://github.com/bazel-contrib/portable-perl/releases/tag/20260929
_PORTABLE = {
    "aarch64": "sha256-Kl91TsCoItX5Wp3VoyqsszFvrGSn0uVD57Strr+b8Es=",
    "x86_64": "sha256-yaoQckCTJyYU9cCXkPH3NaX8LvwuKroiuMX7rLqR4pk=",
}

def _perl_impl(ctx):
    ctx.download_and_extract(
        "https://cpan.metacpan.org/src/5.0/perl-5.44.0.tar.gz",
        integrity = "sha256-O4VQZrkkkctA6Gr/scpX0aOIqkPlG5HHgGoywvZflsM=",
        stripPrefix = "perl-5.44.0",
    )

    # portable-perl builds libperl.a without -fPIC. Compile libperl from the
    # matching CPAN release for linking into ngx_http_perl_module.so.
    cpu = ctx.attr.cpu
    archive = "perl-5.44.0-{}-linux-gnu".format(cpu)
    ctx.download_and_extract(
        "https://github.com/bazel-contrib/portable-perl/releases/download/20260929/{}.tar.xz".format(archive),
        output = "portable",
        integrity = _PORTABLE[cpu],
        stripPrefix = archive,
    )
    core = "portable/lib/5.44.0/{}-linux-thread-multi/CORE/".format(cpu)
    for header in ["bitcount.h", "git_version.h", "mg_data.h", "uudmap.h"]:
        ctx.symlink(core + header, header)

    # The portable interpreter resolves standard library paths relative to its
    # executable. The embedding executable is nginx at /usr/sbin/nginx.
    ctx.template("config.h", core + "config.h", {
        ".../../lib/": "/usr/lib/nginx/perl/",
        # glibc 2.27 removed _LIB_VERSION and defaults to IEEE math.
        "#define LIBM_LIB_VERSION": "/* #undef LIBM_LIB_VERSION */",
    }, executable = False)
    ctx.template("BUILD.bazel", ctx.attr._build, {"{ARCH}": cpu}, executable = False)

perl_for_nginx = repository_rule(
    implementation = _perl_impl,
    attrs = {
        "cpu": attr.string(mandatory = True, values = sorted(_PORTABLE)),
        "_build": attr.label(default = Label("//perl:libperl.BUILD.bazel")),
    },
)
