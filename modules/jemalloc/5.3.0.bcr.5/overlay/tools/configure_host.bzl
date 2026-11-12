"Flags that configure.ac's host table adds to every check."

# copts are not inherited through deps, so each autoconf target that compiles a check passes these itself.
HOST_CPPFLAGS = select({
    "@platforms//os:android": ["-D_GNU_SOURCE"],
    "@platforms//os:freebsd": ["-D_BSD_SOURCE"],
    "@platforms//os:linux": ["-D_GNU_SOURCE"],
    "//conditions:default": [],
})

# configure.ac adds include/msvc_compat to CPPFLAGS when the compiler defines _MSC_VER, which clang-cl does too.
HOST_CC_DEPS = select({
    "@rules_cc//cc/compiler:clang-cl": ["//include/msvc_compat"],
    "@rules_cc//cc/compiler:msvc-cl": ["//include/msvc_compat"],
    "//conditions:default": [],
})

# configure.ac links every later check with -pthread once libpthread provides pthread_create, which it looks for
# outside the pecoff ABI.
HOST_LIBS = select({
    "@platforms//os:windows": [],
    "//conditions:default": ["//:pthread"],
})
