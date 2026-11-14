# nginx

`@nginx` builds the nginx executable for x86-64 and AArch64 Linux with glibc.
`@nginx//:dynamic_modules` builds the seven shared objects for HTTP GeoIP,
image filtering, Perl, XSLT, mail, stream, and stream GeoIP. Each shared object
is also a target, for example `@nginx//:ngx_mail_module.so`.

The feature flags and compiled-in paths follow Ubuntu 26.10's
`nginx_1.30.4-7ubuntu1.1` source package. Regular expressions use the BCR
PCRE2 library with JIT disabled. The nginx XSLT module includes EXSLT with
its crypto extension disabled.

For packaging, `@nginx//:conf`, `@nginx//:html`, and `@nginx//:man` contain
the upstream distribution files. Ubuntu supplies its own `/etc/nginx/nginx.conf`.
Install the shared objects in `/usr/lib/nginx/modules`. For the optional Perl
module, install the contents of the `portable/lib/5.44.0/` tree in
`@nginx//:perl_stdlib` under `/usr/lib/nginx/perl/5.44.0/`. Install
`nginx.pm` and `auto/nginx/nginx.so` from `@nginx//:perl_runtime` alongside
that standard library. The module embeds a position-independent build of Perl
5.44.0 from source.

## Updating the build

Apply the feature and path flags from Ubuntu's `debian/rules` to the new
release's `configure` on Linux. Compare `objs/ngx_auto_config.h` and
`objs/ngx_auto_headers.h` with `overlay/config/`, including the differences
between x86-64 and AArch64. Compare the C source list in `objs/Makefile` and
the module order in `objs/ngx_modules.c` and `objs/*_modules.c` with
`nginx_sources.bzl` and `dynamic_modules.bzl`. Filter registration order
affects how nginx processes responses.

The nginx root module registers the LLVM development toolchain. To exercise
the build on an x86-64 Linux host, run
`bazel test --platforms=@llvm//platforms:linux_x86_64 //tests:upstream`.
