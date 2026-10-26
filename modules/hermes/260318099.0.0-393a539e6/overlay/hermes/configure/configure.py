"""Expand Hermes' configuration headers for Bazel's selected target platform."""

import argparse
from pathlib import Path
import re


def configuration(platform: str, arch: str) -> dict[str, str]:
    # These are target ABI capabilities, never probes of the machine running Python.
    apple = platform == "macos"
    triple_arch = "aarch64" if arch == "arm64" else "x86_64"
    triple = triple_arch + ("-apple-darwin" if apple else "-unknown-linux-gnu")
    values = {
        name: "1"
        for name in (
            "LLVM_ENABLE_THREADS LLVM_HAS_ATOMICS LLVM_ON_UNIX "
            "HAVE_BACKTRACE HAVE_DECL_FE_ALL_EXCEPT HAVE_DECL_FE_INEXACT "
            "HAVE_DLFCN_H HAVE_DLOPEN HAVE_DLADDR HAVE_ERRNO_H HAVE_FCNTL_H "
            "HAVE_FENV_H HAVE_FUTIMENS HAVE_FUTIMES HAVE_GETPAGESIZE "
            "HAVE_GETRLIMIT HAVE_GETRUSAGE HAVE_ISATTY HAVE_LIBPTHREAD "
            "HAVE_PTHREAD_GETNAME_NP HAVE_PTHREAD_SETNAME_NP HAVE_POSIX_SPAWN "
            "HAVE_PREAD HAVE_PTHREAD_GETSPECIFIC HAVE_PTHREAD_H "
            "HAVE_PTHREAD_MUTEX_LOCK HAVE_PTHREAD_RWLOCK_INIT HAVE_REALPATH "
            "HAVE_SBRK HAVE_SETENV HAVE_SETRLIMIT HAVE_SIGNAL_H HAVE_STRERROR "
            "HAVE_STRERROR_R HAVE_SYSCONF HAVE_SYS_IOCTL_H HAVE_SYS_MMAN_H "
            "HAVE_SYS_PARAM_H HAVE_SYS_RESOURCE_H HAVE_SYS_STAT_H "
            "HAVE_SYS_TIME_H HAVE_SYS_TYPES_H HAVE_TERMIOS_H HAVE_UNISTD_H "
            "HAVE__UNWIND_BACKTRACE"
        ).split()
    }
    values.update(
        {
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
        }
    )
    platform_capabilities = (
        "HAVE_DECL_ARC4RANDOM HAVE_CRASHREPORTER_INFO HAVE_MACH_MACH_H "
        "HAVE_MALLOC_MALLOC_H HAVE_MALLOC_ZONE_STATISTICS"
        if apple
        else "HAVE_LINK_H HAVE_LSEEK64 HAVE_MALLINFO HAVE_MALLOC_H "
        "HAVE_POSIX_FALLOCATE HAVE_SCHED_GETAFFINITY HAVE_CPU_COUNT "
        "HAVE_SIGALTSTACK"
    )
    values.update({name: "1" for name in platform_capabilities.split()})
    return values


def expand(template: str, values: dict[str, str]) -> str:
    lines = []
    for line in template.splitlines(keepends=True):
        directive = re.match(r"#cmakedefine(01)?\s+(\w+)(.*)", line)
        if directive:
            boolean, name, suffix = directive.groups()
            enabled = values.get(name, "") not in ("", "0")
            if boolean:
                line = f"#define {name} {int(enabled)}\n"
            elif enabled:
                line = f"#define {name}{suffix}\n"
            else:
                line = f"/* #undef {name} */\n"

        def replace(match: re.Match[str]) -> str:
            name = match.group(1) or match.group(2)
            if name not in values:
                raise ValueError(f"Unconfigured Hermes template variable: {name}")
            return values[name]

        lines.append(re.sub(r"\$\{(\w+)\}|@(\w+)@", replace, line))
    return "".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--platform", choices=("macos", "linux"), required=True)
    parser.add_argument("--arch", choices=("arm64", "x86_64"), required=True)
    parser.add_argument("--template", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    contents = expand(args.template.read_text(), configuration(args.platform, args.arch))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(contents)


if __name__ == "__main__":
    main()
