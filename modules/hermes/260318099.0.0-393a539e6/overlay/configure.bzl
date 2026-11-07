"""Expand pinned Hermes headers using target ABI values and Bazel actions."""

_COMMON = """
LLVM_ENABLE_THREADS LLVM_HAS_ATOMICS LLVM_ON_UNIX
HAVE_BACKTRACE HAVE_DECL_FE_ALL_EXCEPT HAVE_DECL_FE_INEXACT
HAVE_DLFCN_H HAVE_DLOPEN HAVE_DLADDR HAVE_ERRNO_H HAVE_FCNTL_H
HAVE_FENV_H HAVE_FUTIMENS HAVE_FUTIMES HAVE_GETPAGESIZE
HAVE_GETRLIMIT HAVE_GETRUSAGE HAVE_ISATTY HAVE_LIBPTHREAD
HAVE_PTHREAD_GETNAME_NP HAVE_PTHREAD_SETNAME_NP HAVE_POSIX_SPAWN
HAVE_PREAD HAVE_PTHREAD_GETSPECIFIC HAVE_PTHREAD_H
HAVE_PTHREAD_MUTEX_LOCK HAVE_PTHREAD_RWLOCK_INIT HAVE_REALPATH
HAVE_SBRK HAVE_SETENV HAVE_SETRLIMIT HAVE_SIGNAL_H HAVE_STRERROR
HAVE_STRERROR_R HAVE_SYSCONF HAVE_SYS_IOCTL_H HAVE_SYS_MMAN_H
HAVE_SYS_PARAM_H HAVE_SYS_RESOURCE_H HAVE_SYS_STAT_H
HAVE_SYS_TIME_H HAVE_SYS_TYPES_H HAVE_TERMIOS_H HAVE_UNISTD_H
HAVE__UNWIND_BACKTRACE
"""

_BOOLEAN = """
LLVM_ENABLE_THREADS LLVM_HAS_ATOMICS LLVM_USE_INTEL_JITEVENTS LLVM_USE_OPROFILE
LLVM_USE_PERF LLVM_FORCE_ENABLE_STATS ENABLE_BACKTRACES ENABLE_CRASH_OVERRIDES
LLVM_ENABLE_CRASH_DUMPS HAVE_CRASHREPORTER_INFO HAVE_DECL_ARC4RANDOM
HAVE_DECL_FE_ALL_EXCEPT HAVE_DECL_FE_INEXACT HAVE_DECL_STRERROR_S LLVM_ENABLE_DIA_SDK
LLVM_ENABLE_ZLIB LLVM_VERSION_PRINTER_SHOW_HOST_TARGET_INFO LLVM_GISEL_COV_ENABLED
HERMESVM_SANITIZE_HANDLES
"""

_PLAIN = """
LLVM_ENABLE_DUMP LINK_POLLY_INTO_TOOLS HAVE_CRASHREPORTERCLIENT_H
HERMESVM_COMPRESSED_POINTERS HERMESVM_BOXED_DOUBLES HERMESVM_CONTIGUOUS_HEAP
HERMES_IS_MOBILE_BUILD
"""

_VALUE = """
LLVM_NATIVE_ARCH LLVM_ON_UNIX HAVE_BACKTRACE HAVE_DLFCN_H HAVE_DLOPEN HAVE_DLADDR
HAVE_ERRNO_H HAVE_FCNTL_H HAVE_FENV_H HAVE_FFI_CALL HAVE_FFI_FFI_H HAVE_FFI_H
HAVE_FUTIMENS HAVE_FUTIMES HAVE_GETPAGESIZE HAVE_GETRLIMIT HAVE_GETRUSAGE
HAVE_LIBEDIT HAVE_LIBPFM HAVE_LIBPSAPI HAVE_LIBPTHREAD HAVE_PTHREAD_GETNAME_NP
HAVE_PTHREAD_SETNAME_NP HAVE_LIBZ HAVE_LINK_H HAVE_LSEEK64 HAVE_MACH_MACH_H
HAVE_MALLCTL HAVE_MALLINFO HAVE_MALLOC_H HAVE_MALLOC_MALLOC_H
HAVE_MALLOC_ZONE_STATISTICS HAVE_POSIX_FALLOCATE HAVE_POSIX_SPAWN HAVE_PREAD
HAVE_PTHREAD_GETSPECIFIC HAVE_PTHREAD_H HAVE_PTHREAD_MUTEX_LOCK HAVE_PTHREAD_RWLOCK_INIT
HAVE_REALPATH HAVE_SBRK HAVE_SETENV HAVE_SCHED_GETAFFINITY HAVE_CPU_COUNT
HAVE_SETRLIMIT HAVE_SIGALTSTACK HAVE_SIGNAL_H HAVE_STRERROR HAVE_STRERROR_R
HAVE_SYSCONF HAVE_SYS_IOCTL_H HAVE_SYS_MMAN_H HAVE_SYS_PARAM_H HAVE_SYS_RESOURCE_H
HAVE_SYS_STAT_H HAVE_SYS_TIME_H HAVE_SYS_TYPES_H HAVE_TERMINFO HAVE_LIBXAR
HAVE_TERMIOS_H HAVE_UNISTD_H HAVE_VALGRIND_VALGRIND_H HAVE_ZLIB_H HAVE__ALLOCA
HAVE__CHSIZE_S HAVE__UNWIND_BACKTRACE HAVE___ALLOCA HAVE___ASHLDI3 HAVE___ASHRDI3
HAVE___CHKSTK HAVE___CHKSTK_MS HAVE___CMPDI2 HAVE___DIVDI3 HAVE___FIXDFDI
HAVE___FIXSFDI HAVE___FLOATDIDF HAVE___LSHRDI3 HAVE___MAIN HAVE___MODDI3
HAVE___UDIVDI3 HAVE___UMODDI3 HAVE____CHKSTK HAVE____CHKSTK_MS LLVM_LIBXML2_ENABLED
RETSIGTYPE stricmp strdup
"""

_QUOTED = """
LLVM_DEFAULT_TARGET_TRIPLE LLVM_HOST_TRIPLE HOST_LINK_VERSION LLVM_TARGET_TRIPLE_ENV
LLVM_VERSION_INFO LTDL_SHLIB_EXT PACKAGE_BUGREPORT PACKAGE_NAME PACKAGE_STRING
PACKAGE_VERSION PACKAGE_VENDOR LLVM_GISEL_COV_PREFIX
"""

_SPECIAL = {
    "LLVM_NATIVE_ASMPARSER": " LLVMInitialize${LLVM_NATIVE_ARCH}AsmParser",
    "LLVM_NATIVE_ASMPRINTER": " LLVMInitialize${LLVM_NATIVE_ARCH}AsmPrinter",
    "LLVM_NATIVE_DISASSEMBLER": " LLVMInitialize${LLVM_NATIVE_ARCH}Disassembler",
    "LLVM_NATIVE_TARGET": " LLVMInitialize${LLVM_NATIVE_ARCH}Target",
    "LLVM_NATIVE_TARGETINFO": " LLVMInitialize${LLVM_NATIVE_ARCH}TargetInfo",
    "LLVM_NATIVE_TARGETMC": " LLVMInitialize${LLVM_NATIVE_ARCH}TargetMC",
    "HAVE_ISATTY": " 1",
}

def _words(text):
    return [word for word in text.replace("\n", " ").split(" ") if word]

def _values(platform, arch):
    apple = platform == "macos"
    triple = ("aarch64" if arch == "arm64" else "x86_64") + ("-apple-darwin" if apple else "-unknown-linux-gnu")
    values = {name: "1" for name in _words(_COMMON)}
    values.update({
        "BACKTRACE_HEADER": "execinfo.h",
        "BUG_REPORT_URL": "https://github.com/facebook/hermes/issues",
        "LLVM_HOST_TRIPLE": triple,
        "LLVM_DEFAULT_TARGET_TRIPLE": triple,
        "CMAKE_CXX_COMPILER_TARGET": triple,
        "LLVM_VERSION_MAJOR": "8",
        "LLVM_VERSION_MINOR": "0",
        "LLVM_VERSION_PATCH": "0",
        "PACKAGE_NAME": "LLVH",
        "PACKAGE_STRING": "LLVH 8.0.0svn",
        "PACKAGE_VERSION": "8.0.0svn",
        "RETSIGTYPE": "void",
        "LTDL_SHLIB_EXT": ".dylib" if apple else ".so",
        "HERMESVM_LOG_HEAP_SEGMENT_SIZE": "22",
        "HERMESVM_GCKIND": "HADES",
        "HERMESVM_ALLOW_JIT": "0",
        "CMAKE_SIZEOF_VOID_P": "8",
        "HERMESVM_MODEL": "_s22_p8",
    })
    capabilities = (
        "HAVE_DECL_ARC4RANDOM HAVE_CRASHREPORTER_INFO HAVE_MACH_MACH_H HAVE_MALLOC_MALLOC_H HAVE_MALLOC_ZONE_STATISTICS" if apple else "HAVE_LINK_H HAVE_LSEEK64 HAVE_MALLINFO HAVE_MALLOC_H HAVE_POSIX_FALLOCATE HAVE_SCHED_GETAFFINITY HAVE_CPU_COUNT HAVE_SIGALTSTACK"
    )
    values.update({name: "1" for name in _words(capabilities)})
    return values

def _expand_values(text, values):
    for name, value in values.items():
        text = text.replace("${" + name + "}", value).replace("@" + name + "@", value)
    return text

def _configure_impl(ctx):
    values = _values(ctx.attr.platform, ctx.attr.arch)
    directives = {name: "" for name in _words(_PLAIN)}
    directives.update({name: " ${" + name + "}" for name in _words(_VALUE)})
    directives.update({name: ' "${' + name + '}"' for name in _words(_QUOTED)})
    directives.update(_SPECIAL)
    substitutions = {}
    for name, suffix in directives.items():
        enabled = values.get(name, "") not in ["", "0"]
        substitutions["#cmakedefine " + name + suffix + "\n"] = (
            "#define " + name + _expand_values(suffix, values) + "\n" if enabled else "/* #undef " + name + " */\n"
        )
    for name in _words(_BOOLEAN):
        enabled = values.get(name, "") not in ["", "0"]
        substitutions["#cmakedefine01 " + name + "\n"] = "#define " + name + (" 1\n" if enabled else " 0\n")
    for name, value in values.items():
        substitutions["${" + name + "}"] = value
        substitutions["@" + name + "@"] = value
    ctx.actions.expand_template(
        template = ctx.file.src,
        output = ctx.outputs.out,
        substitutions = substitutions,
    )
    return [DefaultInfo(files = depset([ctx.outputs.out]))]

_configure_header = rule(
    implementation = _configure_impl,
    attrs = {
        "src": attr.label(allow_single_file = True, mandatory = True),
        "out": attr.output(mandatory = True),
        "platform": attr.string(values = ["linux", "macos"], mandatory = True),
        "arch": attr.string(values = ["arm64", "x86_64"], mandatory = True),
    },
)

def configure_headers(platform, arch, prefix = "configure", out_prefix = "build/include", **kwargs):
    """Configure the three upstream headers for the selected target."""
    for name, template, output in [
        ("llvm", "external/llvh/include/llvh/Config/llvm-config.h.cmake", "llvh/Config/llvm-config.h"),
        ("llvh", "external/llvh/include/llvh/Config/config.h.cmake", "llvh/Config/config.h"),
        ("vm", "lib/config/libhermesvm-config.h.in", "libhermesvm-config.h"),
    ]:
        _configure_header(
            name = prefix + "_" + name,
            src = Label("//:" + template),
            out = out_prefix + "/" + output,
            platform = platform,
            arch = arch,
            **kwargs
        )
