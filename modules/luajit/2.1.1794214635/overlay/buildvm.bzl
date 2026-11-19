"""Build LuaJIT's VM generator for the host with an explicit output target."""

load("@bazel_skylib//rules:run_binary.bzl", "run_binary")
load("@rules_cc//cc:cc_binary.bzl", "cc_binary")

def buildvm(name, target = None, gc64 = True):
    """Define the DynASM header and its execution-platform generator.

    Args:
        name: Generator target name.
        target: Linux output architecture, or None for the native platform.
        gc64: Fixed x86_64 reference format, selected before the exec transition.
    """
    defines = []
    if target == "x64":
        sources = ["src/vm_x64.dasc" if gc64 else "src/vm_x86.dasc"]
        flags = ["-D", "ENDIAN_LE", "-D", "P64", "-D", "JIT", "-D", "FFI", "-D", "FPU", "-D", "HFABI"]
        headers = ["dynasm/dasm_x86.h"]
        defines = ["LUAJIT_TARGET=LUAJIT_ARCH_X64", "LUAJIT_OS=LUAJIT_OS_LINUX"]
    elif target == "arm64":
        sources = ["src/vm_arm64.dasc"]
        flags = ["-D", "ENDIAN_LE", "-D", "P64", "-D", "JIT", "-D", "FFI", "-D", "DUALNUM", "-D", "FPU", "-D", "HFABI", "-D", "VER=80"]
        headers = ["dynasm/dasm_arm64.h"]
        defines = ["LUAJIT_TARGET=LUAJIT_ARCH_ARM64", "LUAJIT_OS=LUAJIT_OS_LINUX"]
    elif target == None:
        sources = select({
            "@platforms//cpu:x86_64": ["src/vm_x64.dasc" if gc64 else "src/vm_x86.dasc"],
            "@platforms//cpu:arm64": ["src/vm_arm64.dasc"],
            "@platforms//cpu:armv7": ["src/vm_arm.dasc"],
            "@platforms//cpu:mips64": ["src/vm_mips64.dasc"],
            "@platforms//cpu:ppc": ["src/vm_ppc.dasc"],
            "//conditions:default": ["src/vm_x86.dasc"],
        })

        # DynASM flags follow lj_arch.h and the upstream Makefile. The
        # native x64 non-GC64 configuration uses vm_x86.dasc (LJ_FR2=0).
        flags = select({
            ":macos_arm64": ["-D", "ENDIAN_LE", "-D", "P64", "-D", "JIT", "-D", "FFI", "-D", "DUALNUM", "-D", "FPU", "-D", "HFABI", "-D", "NO_UNWIND", "-D", "VER=80"],
            "@platforms//cpu:arm64": ["-D", "ENDIAN_LE", "-D", "P64", "-D", "JIT", "-D", "FFI", "-D", "DUALNUM", "-D", "FPU", "-D", "HFABI", "-D", "VER=80"],
            "@platforms//cpu:armv7": ["-D", "ENDIAN_LE", "-D", "JIT", "-D", "FFI", "-D", "DUALNUM", "-D", "FPU", "-D", "HFABI", "-D", "VER=70"],
            "@platforms//cpu:mips64": ["-D", "ENDIAN_LE", "-D", "P64", "-D", "JIT", "-D", "FFI", "-D", "FPU", "-D", "HFABI", "-D", "VER=20"],
            "@platforms//cpu:ppc": ["-D", "ENDIAN_BE", "-D", "JIT", "-D", "FFI", "-D", "DUALNUM", "-D", "FPU", "-D", "HFABI"],
            "@platforms//cpu:x86_64": ["-D", "ENDIAN_LE", "-D", "P64", "-D", "JIT", "-D", "FFI", "-D", "FPU", "-D", "HFABI"],
            "//conditions:default": ["-D", "ENDIAN_LE", "-D", "JIT", "-D", "FFI", "-D", "FPU", "-D", "HFABI"],
        }) + select({
            "@platforms//os:windows": ["-D", "WIN"],
            "//conditions:default": [],
        })
        headers = select({
            "@platforms//cpu:arm64": ["dynasm/dasm_arm64.h"],
            "@platforms//cpu:armv7": ["dynasm/dasm_arm.h"],
            "@platforms//cpu:mips64": ["dynasm/dasm_mips.h"],
            "@platforms//cpu:ppc": ["dynasm/dasm_ppc.h"],
            "//conditions:default": ["dynasm/dasm_x86.h"],
        })
    else:
        fail("unsupported VM target: " + target)

    # Upstream requires GC64 on macOS/x64. Do not make the unused alternate
    # native generator break wildcard builds on that platform.
    compatible = []
    if target == None and not gc64:
        compatible = select({
            ":macos_x86_64": ["@platforms//:incompatible"],
            "//conditions:default": [],
        })
    directory = "generated/" + name
    native.filegroup(name = name + "_dasc", srcs = sources)
    run_binary(
        name = name + "_arch_h",
        srcs = [name + "_dasc", "src/lj_arch.h", "src/lua.h", "src/luaconf.h"] + native.glob(["dynasm/*.lua"]),
        outs = [directory + "/buildvm_arch.h"],
        args = ["$(execpath dynasm/dynasm.lua)"] + flags + [
            "-o",
            "$(execpath " + directory + "/buildvm_arch.h)",
            "$(execpath :" + name + "_dasc)",
        ],
        target_compatible_with = compatible,
        tool = ":minilua",
    )
    cc_binary(
        name = name,
        srcs = [
            "dynasm/dasm_proto.h",
            "src/host/buildvm.c",
            "src/host/buildvm.h",
            "src/host/buildvm_asm.c",
            "src/host/buildvm_fold.c",
            "src/host/buildvm_lib.c",
            "src/host/buildvm_libbc.h",
            "src/host/buildvm_peobj.c",
            name + "_arch_h",
            ":luajit_h",
        ] + native.glob(["src/*.h"]) + headers,
        copts = ["-fomit-frame-pointer", "-w"],
        includes = ["dynasm", "src", "src/host", directory],
        target_compatible_with = compatible,
        local_defines = defines + ["LUAJIT_ENABLE_GC64" if gc64 else "LUAJIT_DISABLE_GC64"] + select({
            ":macos_arm64": ["LUAJIT_ENABLE_JIT"],
            "//conditions:default": [],
        }),
    )
