"Project specific configuration of rules_cc"

# The language standards jemalloc's sources are written in, configure.ac's
# preferred -std=gnu11 and -std=c++17. They are a property of these sources, so
# they are declared here rather than left to the toolchain's default. MSVC has
# no GNU C dialect, so cl and clang-cl get C11, as upstream's configure gives cl
# (AC_PROG_CC adds -std:c11); 5.4.0's unit tests use C11's _Static_assert.
CONLYOPTS = select({
    "//settings/compiler:msvc_compatible": ["/std:c11"],
    "//conditions:default": ["-std=gnu11"],
})

# The toolchain features that go with CONLYOPTS. From rules_cc 0.2.19, the toolchain for cl and clang-cl enables
# default_c_std, which compiles C as /std:c17. The C standard is a property of jemalloc's sources, not of the toolchain,
# so the feature is removed and CONLYOPTS alone sets it. A toolchain without it ignores its removal.
C_FEATURES = ["-default_c_std"]

CXXOPTS = select({
    "//settings/compiler:msvc_compatible": ["/std:c++17"],
    "//conditions:default": ["-std=c++17"],
})

# The flags that change what jemalloc's sources and the system headers mean: -D_REENTRANT (configure.ac:2278), the
# host's feature test macros (configure.ac:806-864), -fvisibility=hidden, -fcommon on Windows, and the frame pointers
# prof's gcc unwinder walks (configure.ac:1635). Then the warnings jemalloc's sources trip on purpose.
#
# configure.ac's other defaults are the builder's choices. Target copts come after --copt, so anything here would
# override them wherever jemalloc is compiled, including in every build that depends on this module:
# - Turning warnings on (configure.ac:273-278, 280, 295, 343-344, 1097-1098) is done with --copt, --conlyopt and
#   --cxxopt. Only the suppressions below stay.
# - Debug info (-g3, -Zi; configure.ac:290, 293, 350) comes from --compilation_mode. -FS (configure.ac:296) only
#   matters when compiles share a PDB, and Bazel's /Z7 embeds the debug info in each object instead.
# - -pipe (configure.ac:289) only changes the speed of the build; --copt sets it.
# - The C runtime (-MT; configure.ac:294) is the toolchain's, from its static_link_msvcrt and dynamic_link_msvcrt
#   features. Forcing it here breaks consumers linking the other runtime (LNK2038).
# - -DPIC (configure.ac:689) is defined by upstream only for its PIC objects (Makefile.in:498-501), which go into the
#   shared library and libjemalloc_pic.a, and nothing reads it. Position independent code is the toolchain's job.
COPTS = ["-D_REENTRANT"] + select({
    # configure.ac adds it only for GCC=yes on the ELF ABI. Here it goes to every compiler that takes GCC's command
    # line, so Mach-O, which also honours visibility, gets it too. clang-cl and mingw-gcc target only PE/COFF, where
    # exports come from dllexport or .def files, and clang-cl ignores the flag.
    "@rules_cc//cc/compiler:clang": ["-fvisibility=hidden"],
    "@rules_cc//cc/compiler:emscripten": ["-fvisibility=hidden"],
    "@rules_cc//cc/compiler:gcc": ["-fvisibility=hidden"],
    "//conditions:default": [],
}) + select({
    "@platforms//os:android": ["-D_GNU_SOURCE"],
    "@platforms//os:freebsd": ["-D_BSD_SOURCE"],
    "@platforms//os:linux": ["-D_GNU_SOURCE"],
    "//conditions:default": [],
}) + select({
    # On _WIN32, je_malloc_conf and je_malloc_conf_2_conf_harder are not weak (src/jemalloc.c:36-40, 58-62), so a
    # program overrides them with its own malloc_conf only if the library's uninitialized definitions are common
    # symbols. cl makes them so; GCC 10, clang 11 and clang-cl default to -fno-common. Upstream's CI passes -fcommon to
    # every Windows compiler other than cl (scripts/gen_travis.py:158-166), and so does this, since without it any
    # program that sets malloc_conf, as nine of the unit tests do, fails to link with a duplicate symbol.
    "//settings/compiler:windows_gcc_compatible": ["-fcommon"],
    "@rules_cc//cc/compiler:clang-cl": ["-fcommon"],
    "//conditions:default": [],
}) + select({
    "//settings/flags:prof_gcc": ["-fno-omit-frame-pointer"],
    "//conditions:default": [],
}) + select({
    # The warnings configure.ac turns off for patterns jemalloc's sources use on purpose:
    # - -Wno-missing-braces (configure.ac:281-285) for the universal zero initializer {0}, as in the tcache's static
    #   initializer of nested structs, which older GCC flags (https://gcc.gnu.org/bugzilla/show_bug.cgi?id=53119).
    # - -Wno-missing-field-initializers (configure.ac:286-287), for the same initializers and for struct initializers
    #   that leave their trailing fields zero, as test/unit/hpa.c's options do.
    # - -Wno-missing-attributes (configure.ac:288), for the __libc_* aliases of je_* (src/jemalloc.c:1285-1313), which
    #   are compiled only where glibc still links its malloc hooks (before 2.34), and which GCC 9 and later flag for
    #   having fewer attributes than their targets. Clang has no such warning and warns about the unknown flag on every
    #   compile, so only GCC gets it.
    # Turning a warning off can't fail a build the way turning one on can, so the library declares these. Target copts
    # come after --copt, so a builder who wants one of these warnings anyway turns it back on with --per_file_copt,
    # which comes after both. clang-cl takes clang's -W flags as they are, and its /W4 turns on -Wextra, so it gets them
    # too. cl has no counterpart and upstream's MSVC flags suppress nothing (configure.ac:291-297).
    "@rules_cc//cc/compiler:clang": ["-Wno-missing-braces", "-Wno-missing-field-initializers"],
    "@rules_cc//cc/compiler:clang-cl": ["-Wno-missing-braces", "-Wno-missing-field-initializers"],
    "@rules_cc//cc/compiler:emscripten": ["-Wno-missing-braces", "-Wno-missing-field-initializers"],
    "@rules_cc//cc/compiler:gcc": [
        "-Wno-missing-braces",
        "-Wno-missing-field-initializers",
        "-Wno-missing-attributes",
    ],
    "@rules_cc//cc/compiler:mingw-gcc": [
        "-Wno-missing-braces",
        "-Wno-missing-field-initializers",
        "-Wno-missing-attributes",
    ],
    "//conditions:default": [],
})
