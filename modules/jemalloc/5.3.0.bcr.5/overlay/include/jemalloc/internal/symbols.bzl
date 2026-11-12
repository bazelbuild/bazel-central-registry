"""The public and wrapped symbol lists configure.ac assembles, and configure's SYM_PREFIX."""

load("//tools:version.bzl", "VERSION")

# configure.ac's public_syms: the symbols it always lists, in its order.
PUBLIC_SYMBOLS = [
    "aligned_alloc",
    "calloc",
    "dallocx",
    "free",
    "mallctl",
    "mallctlbymib",
    "mallctlnametomib",
    "malloc",
    "malloc_conf",
    "malloc_conf_2_conf_harder",
    "malloc_message",
    "malloc_stats_print",
    "malloc_usable_size",
    "mallocx",
    "smallocx_%s" % VERSION.gid,
    "nallocx",
    "posix_memalign",
    "rallocx",
    "realloc",
    "sallocx",
    "sdallocx",
    "xallocx",
]

# The symbols configure.ac appends to public_syms in the branch where it defines a macro, in its order, each mapped to
# [the configured header, that macro]. The list is written from the configured headers when the build runs (see
# symbol_list), so it follows the probes exactly, and a symbol jemalloc defines is always listed.
OPTIONAL_PUBLIC_SYMBOLS = {
    "memalign": ["jemalloc_defs.h", "JEMALLOC_OVERRIDE_MEMALIGN"],
    "valloc": ["jemalloc_defs.h", "JEMALLOC_OVERRIDE_VALLOC"],
    "malloc_size": ["jemalloc_internal_defs.h", "JEMALLOC_HAVE_MALLOC_SIZE"],
}

# configure.ac lists tls_callback for its mingw and cygwin hosts, without a macro.
_WRAP_OS = {
    "@platforms//os:windows": ["tls_callback"],
    "//conditions:default": [],
}

# configure.ac's wrap_syms: the symbols jemalloc defines under their own names, which private_namespace_gen leaves out
# of private renaming. These are the ones it lists without a macro. symbol_list writes them before the optional ones,
# while configure.ac puts tls_callback after __posix_memalign, so where both appear only the membership of wrap_syms
# follows configure.ac, not its order; private_namespace_gen and the upstream oracle treat it as a set.
WRAP_SYMBOLS = select(_WRAP_OS)

# The symbols configure.ac appends to wrap_syms in the branch where it defines a macro, in its order, each mapped to
# [the configured header, that macro]. As with OPTIONAL_PUBLIC_SYMBOLS, the list follows the probes exactly: each symbol
# src/jemalloc.c defines under one of these macros is exempt from private renaming, and none is listed where configure
# would not list it (the glibc hooks, for example, only without a prefix and where they link, before glibc 2.34).
OPTIONAL_WRAP_SYMBOLS = {
    "__libc_calloc": ["jemalloc_internal_defs.h", "JEMALLOC_OVERRIDE___LIBC_CALLOC"],
    "__libc_free": ["jemalloc_internal_defs.h", "JEMALLOC_OVERRIDE___LIBC_FREE"],
    "__libc_malloc": ["jemalloc_internal_defs.h", "JEMALLOC_OVERRIDE___LIBC_MALLOC"],
    "__libc_memalign": ["jemalloc_internal_defs.h", "JEMALLOC_OVERRIDE___LIBC_MEMALIGN"],
    "__libc_realloc": ["jemalloc_internal_defs.h", "JEMALLOC_OVERRIDE___LIBC_REALLOC"],
    "__libc_valloc": ["jemalloc_internal_defs.h", "JEMALLOC_OVERRIDE___LIBC_VALLOC"],
    "__posix_memalign": ["jemalloc_internal_defs.h", "JEMALLOC_OVERRIDE___POSIX_MEMALIGN"],
    "pthread_create": ["jemalloc_internal_defs.h", "JEMALLOC_HAVE_PTHREAD"],
    "_malloc_thread_cleanup": ["jemalloc_internal_defs.h", "JEMALLOC_MALLOC_THREAD_CLEANUP"],
    "_malloc_tsd_cleanup_register": ["jemalloc_internal_defs.h", "JEMALLOC_MALLOC_THREAD_CLEANUP"],
    "_malloc_prefork": ["jemalloc_internal_defs.h", "JEMALLOC_MUTEX_INIT_CB"],
    "_malloc_postfork": ["jemalloc_internal_defs.h", "JEMALLOC_MUTEX_INIT_CB"],
    "__free_hook": ["jemalloc_internal_defs.h", "JEMALLOC_GLIBC_MALLOC_HOOK"],
    "__malloc_hook": ["jemalloc_internal_defs.h", "JEMALLOC_GLIBC_MALLOC_HOOK"],
    "__realloc_hook": ["jemalloc_internal_defs.h", "JEMALLOC_GLIBC_MALLOC_HOOK"],
    "__memalign_hook": ["jemalloc_internal_defs.h", "JEMALLOC_GLIBC_MEMALIGN_HOOK"],
}

# Every symbol public_syms or wrap_syms can list, for comparison with configure.ac
ALL_PUBLIC_SYMBOLS = PUBLIC_SYMBOLS + list(OPTIONAL_PUBLIC_SYMBOLS)

ALL_WRAP_SYMBOLS = [symbol for symbols in _WRAP_OS.values() for symbol in symbols] + list(OPTIONAL_WRAP_SYMBOLS)

# configure.ac's SYM_PREFIX: "_" for every Apple OS (its *-*-darwin* and *-*-ios* hosts), as Mach-O symbol names
# carry a leading underscore.
SYM_PREFIX = select({
    os: "_"
    for os in [
        "@platforms//os:ios",
        "@platforms//os:macos",
        "@platforms//os:tvos",
        "@platforms//os:visionos",
        "@platforms//os:watchos",
    ]
} | {"//conditions:default": ""})
