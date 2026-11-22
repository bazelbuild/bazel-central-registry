#!/usr/bin/env python3
"""Generates the per-platform build data of a binutils module version.

binutils decides what it builds from the target triple, in shell:
`bfd/config.bfd`, `gas/configure.tgt`, `ld/configure.tgt`,
`binutils/configure.tgt`, the vector and architecture tables inside
`bfd/configure.ac` and `opcodes/configure.ac`, the `case "${target}"` of the
top-level `configure.ac` that drops whole programs, and the configure.ac loops
that turn those tables into object lists and -D flags.

The Bazel module has no notion of a triple: the tools are built for the
platform they run on.  This script runs the shell tables for the canonical
triple of every `@platforms` os/cpu pair in PLATFORMS, replays the
configure.ac loops over the results, and writes the resolved answer to
`modules/binutils/<version>/overlay/targets.bzl`, where the BUILD files
`select()` on it.  It also writes `bfd/targmatch.h`, the sed-generated table
`targets.c` includes.

Decisions that live in configure.ac proper rather than in a sourceable table
are transcribed here with the upstream line they came from, and only for the
cpus PLATFORMS can reach; any other cpu is a hard error.  Review those
sections against the new release before trusting the output for a new
version.

Usage:
    python3 modules/binutils/generate_targets.py /path/to/binutils-2.47
The output goes through buildifier when one is on PATH.
"""

from __future__ import annotations

import argparse
import fnmatch
import functools
import json
import re
import shlex
import shutil
import subprocess
from pathlib import Path
from typing import Any

Data = dict[str, Any]


class Ref(str):
    """A Starlark identifier, emitted by starlark() without quotes."""


# The `@platforms` os/cpu pairs the module can be built for, as os -> cpu ->
# the canonical (config.sub) triple config.guess would report there.  The
# table entry `os_cpu` names the BUILD files' config settings.
#
# What is written for each entry: `overlay/targets.bzl` gets the pair's
# constraint values, the triple, whether --enable-64-bit-bfd changes its bfd
# (32-bit hosts only) and which of gas, ld, gprof and the PE tools upstream
# builds for it; `overlay/<package>/targets.bzl` gets the bfd, opcodes, gas,
# ld and binutils results of replaying configure for the triple, keyed the
# same way, identical results shared through `_<PACKAGE>_n` constants.  The
# BUILD files select() on these; a platform with no entry has no matching
# condition.  To add a platform, add a row here and rerun.
#
# binutils is a hosted program and the pair describes where the tools run, so
# the table is the operating systems binutils has host support for, on the
# cpus they run on.  It is deliberately not the whole of config.bfd:
# `@platforms//os:none`, uefi, wasi, emscripten, the Apple embedded OSes, the
# M- and R-profile ARM cpus and wasm are left out because nothing runs
# binutils there.  `arm`, `arm64` and `macos` are @platforms aliases of
# `aarch32`, `aarch64` and `osx`; the canonical names are used, except macos,
# which @platforms documents as the intended name.
#
# TODO: an os/cpu pair carries less than a triple.  Where several triples
# share one pair the entry assumes the usual one:
#   - Linux libc: `-gnu`.  A musl or uClibc host gets the same object lists
#     (only the TARGET strings and tool search directories differ), but it
#     is not the triple configure would report.  Split the Linux entries on
#     `@platforms_contrib//os/linux/libc/{glibc,musl}:available`
#     (https://github.com/bazel-contrib/platforms_contrib/) once a release
#     of that module carries them; 0.2.3 on the BCR does not.
#   - 32-bit ARM float ABI: `aarch32` is `-gnueabi`, `armv7` is `-gnueabihf`.
#   - MIPS64: big-endian n64 (`mips64-*-linux-gnuabi64`); `mips64el` and the
#     n32 ABI are different triples with different default emulations.
#   - `ppc` is 64-bit big-endian powerpc64; `ppc32` is 32-bit powerpc.
#   - x86-64 is the LP64 ABI; x32 (`-gnux32`) is not expressible.
#   - Windows is mingw-w64 (`-w64-mingw32`); Cygwin is not expressible, and
#     MSVC cannot build binutils at all.
#   - NixOS and ChromiumOS are Linux with the same triples; Android is
#     `-linux-android`.
PLATFORMS = {
    # Linux
    "linux": {
        "x86_64": "x86_64-pc-linux-gnu",
        "x86_32": "i686-pc-linux-gnu",
        "i386": "i686-pc-linux-gnu",
        "aarch64": "aarch64-unknown-linux-gnu",
        "aarch32": "arm-unknown-linux-gnueabi",
        "armv7": "armv7-unknown-linux-gnueabihf",
        "ppc": "powerpc64-unknown-linux-gnu",
        "ppc32": "powerpc-unknown-linux-gnu",
        "ppc64le": "powerpc64le-unknown-linux-gnu",
        "s390x": "s390x-ibm-linux-gnu",
        "mips64": "mips64-unknown-linux-gnuabi64",
        "riscv32": "riscv32-unknown-linux-gnu",
        "riscv64": "riscv64-unknown-linux-gnu",
    },
    # Android
    "android": {
        "x86_64": "x86_64-pc-linux-android",
        "x86_32": "i686-pc-linux-android",
        "i386": "i686-pc-linux-android",
        "aarch64": "aarch64-unknown-linux-android",
        "aarch32": "arm-unknown-linux-androideabi",
        "armv7": "armv7-unknown-linux-androideabi",
        "riscv64": "riscv64-unknown-linux-android",
    },
    # NixOS
    "nixos": {
        "x86_64": "x86_64-pc-linux-gnu",
        "x86_32": "i686-pc-linux-gnu",
        "i386": "i686-pc-linux-gnu",
        "aarch64": "aarch64-unknown-linux-gnu",
        "aarch32": "arm-unknown-linux-gnueabi",
        "armv7": "armv7-unknown-linux-gnueabihf",
        "ppc": "powerpc64-unknown-linux-gnu",
        "ppc32": "powerpc-unknown-linux-gnu",
        "ppc64le": "powerpc64le-unknown-linux-gnu",
        "s390x": "s390x-ibm-linux-gnu",
        "mips64": "mips64-unknown-linux-gnuabi64",
        "riscv32": "riscv32-unknown-linux-gnu",
        "riscv64": "riscv64-unknown-linux-gnu",
    },
    # ChromiumOS
    "chromiumos": {
        "x86_64": "x86_64-pc-linux-gnu",
        "x86_32": "i686-pc-linux-gnu",
        "i386": "i686-pc-linux-gnu",
        "aarch64": "aarch64-unknown-linux-gnu",
        "aarch32": "arm-unknown-linux-gnueabi",
        "armv7": "armv7-unknown-linux-gnueabihf",
    },
    # Windows (mingw-w64)
    "windows": {
        "x86_64": "x86_64-w64-mingw32",
        "x86_32": "i686-w64-mingw32",
        "i386": "i686-w64-mingw32",
        "aarch64": "aarch64-w64-mingw32",
    },
    # macOS (bfd and the inspection tools only; configure.ac:1103-1131)
    "macos": {
        "x86_64": "x86_64-apple-darwin",
        "aarch64": "aarch64-apple-darwin",
    },
    # FreeBSD
    "freebsd": {
        "x86_64": "x86_64-pc-freebsd",
        "x86_32": "i686-pc-freebsd",
        "i386": "i686-pc-freebsd",
        "aarch64": "aarch64-unknown-freebsd",
        "aarch32": "arm-unknown-freebsd",
        "armv7": "armv7-unknown-freebsd",
        "ppc": "powerpc64-unknown-freebsd",
        "ppc32": "powerpc-unknown-freebsd",
        "ppc64le": "powerpc64le-unknown-freebsd",
        "mips64": "mips64-unknown-freebsd",
        "riscv64": "riscv64-unknown-freebsd",
    },
    # NetBSD (ld has no aarch64-netbsd emulation; the entry's ld is None)
    "netbsd": {
        "x86_64": "x86_64-pc-netbsd",
        "x86_32": "i686-pc-netbsd",
        "i386": "i686-pc-netbsd",
        "aarch64": "aarch64-unknown-netbsd",
        "aarch32": "arm-unknown-netbsd",
        "armv7": "arm-unknown-netbsd",
        "ppc": "powerpc64-unknown-netbsd",
        "ppc32": "powerpc-unknown-netbsd",
        "mips64": "mips64-unknown-netbsd",
        "riscv64": "riscv64-unknown-netbsd",
    },
    # OpenBSD (ld has no aarch64/arm-openbsd emulation; those entries' ld is None)
    "openbsd": {
        "x86_64": "x86_64-pc-openbsd",
        "x86_32": "i686-pc-openbsd",
        "i386": "i686-pc-openbsd",
        "aarch64": "aarch64-unknown-openbsd",
        "aarch32": "arm-unknown-openbsd",
        "armv7": "arm-unknown-openbsd",
        "ppc": "powerpc64-unknown-openbsd",
        "ppc32": "powerpc-unknown-openbsd",
        "mips64": "mips64-unknown-openbsd",
        "riscv64": "riscv64-unknown-openbsd",
    },
    # Haiku
    "haiku": {
        "x86_64": "x86_64-unknown-haiku",
        "x86_32": "i686-unknown-haiku",
        "i386": "i686-unknown-haiku",
    },
    # VxWorks
    "vxworks": {
        "x86_32": "i686-wrs-vxworks",
        "i386": "i686-wrs-vxworks",
        "aarch32": "arm-wrs-vxworks",
        "armv7": "arm-wrs-vxworks",
        "ppc32": "powerpc-wrs-vxworks",
        "mips64": "mips64-wrs-vxworks",
    },
    # QNX Neutrino
    "qnx": {
        "x86_32": "i686-pc-nto-qnx",
        "i386": "i686-pc-nto-qnx",
        "aarch64": "aarch64-pc-nto-qnx",
        "aarch32": "arm-pc-nto-qnx",
        "armv7": "arm-pc-nto-qnx",
        "ppc32": "powerpc-pc-nto-qnx",
    },
    # Fuchsia
    "fuchsia": {
        "x86_64": "x86_64-unknown-fuchsia",
        "aarch64": "aarch64-unknown-fuchsia",
        "riscv64": "riscv64-unknown-fuchsia",
    },
}

# Hosts whose C pointers are 64 bits wide: bfd/configure.ac:208-210 asks the
# compiler (`AC_CHECK_SIZEOF(void *)`), but the answer has to be known before
# any source is chosen, so it is read off the cpu here.
HOST64_CPUS = {"x86_64", "aarch64", "riscv64", "ppc", "ppc64le", "s390x", "mips64"}

# The gas cpu types the PLATFORMS triples resolve to; the configure.ac arms
# transcribed in configure_gas() cover these and no others.
GAS_CPUS = {"aarch64", "arm", "i386", "mips", "ppc", "riscv", "s390"}


def sh(script: str, cwd: Path) -> tuple[int, dict[str, str], str]:
    """Run SCRIPT under /bin/sh; `print_var NAME...` reports variables back.

    Values are framed so they cannot be confused with the script's own
    output; embedded newlines become spaces.
    """
    prologue = """
print_var() {
  for __n in "$@"; do
    eval "__v=\\${$__n}"
    printf '@@VAR@@%s=%s\\n' "$__n" "$(printf '%s' "$__v" | tr '\\n' ' ')"
  done
}
"""
    proc = subprocess.run(["/bin/sh", "-c", prologue + script], cwd=cwd, capture_output=True, text=True, check=False)
    values: dict[str, str] = {}
    for line in proc.stdout.splitlines():
        if line.startswith("@@VAR@@"):
            name, _, value = line[len("@@VAR@@") :].partition("=")
            values[name] = value
    return proc.returncode, values, proc.stderr


@functools.cache
def shell_fragment(path: Path, first: str, last: str, skip: int = 0) -> str:
    """Lines FIRST..LAST of PATH (LAST searched from FIRST + SKIP), with m4's AC_MSG_ERROR made shell."""
    text = path.read_text().splitlines()
    start = text.index(first)
    end = next(i for i in range(start + skip, len(text)) if text[i] == last)
    return re.sub(r"AC_MSG_ERROR\((.*)\)", r'echo "\1" >&2; exit 1', "\n".join(text[start : end + 1]))


def uniq(items: list[str]) -> list[str]:
    return list(dict.fromkeys(items))


def split_triple(triple: str) -> tuple[str, str, str]:
    """Split a canonical triple into (cpu, vendor, os) as configure does."""
    cpu, _, rest = triple.partition("-")
    vendor, _, os_ = rest.partition("-")
    return cpu, vendor, os_


def match(value: str, *patterns: str) -> bool:
    """Shell `case` matching of VALUE against PATTERNS."""
    return any(fnmatch.fnmatchcase(value, p) for p in patterns)


def shell_token(value: str) -> str:
    """VALUE as one Bourne shell token, for a `local_defines` entry.

    Bazel runs "Make" variable substitution and Bourne shell tokenization over
    `defines`/`local_defines`, so a bare `TARGET="x86_64-pc-linux-gnu"` reaches
    the compiler without its quotes and `A=b c` becomes two tokens.
    Double-quoting the whole value and escaping the quotes inside keeps it
    one token, like the `-DTARGET='"$(target_alias)"'` of the Makefiles.
    """
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def cstring(value: str) -> str:
    """A C string literal of VALUE, as a `local_defines` entry value."""
    return shell_token('"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"')


# ---------------------------------------------------------------------------
# bfd


@functools.cache
def vector_files(srcdir: Path, vec: str) -> tuple[list[str], int]:
    """(object files, target size) of one vector, from the table at bfd/configure.ac:369-688.

    The fragment is run with `selvecs` set to that one vector, so the `.lo`
    names it accumulates in `tb` are exactly that vector's contribution.
    """
    fragment = shell_fragment(srcdir / "bfd" / "configure.ac", "# Target backend .o files.", "done", skip=21)
    code, values, err = sh(f"selvecs={vec}\ndefvec=\ntarget64=false\n{fragment}\nprint_var tb target_size\n", srcdir)
    if code != 0:
        raise SystemExit(f"vector table: {vec}: {err.strip()}")
    return [f[: -len(".lo")] + ".c" for f in uniq(values["tb"].split())], int(values["target_size"])


def bfd_core(host: str) -> tuple[list[str], str, str, str]:
    """(core files, TRAD_HEADER, CORE_HEADER, CORE_HEADER when 64-bit) of bfd/configure.ac:810-998.

    Only the arms a PLATFORMS triple reaches are transcribed; an unlisted
    host gets the empty default exactly as the upstream `case` would.
    """
    if match(host, "i[3-7]86-*-linux-*"):
        return ["trad-core.c"], '"hosts/i386linux.h"', "", '"hosts/x86-64linux.h"'
    if match(host, "i[3-7]86-*-netbsd*", "i[3-7]86-*-openbsd*"):
        return ["netbsd-core.c"], "", "", ""
    if match(host, "i[3-7]86-*-freebsd*"):
        return [], '"hosts/i386bsd.h"', "", ""
    if match(host, "s390*-*-*"):
        return ["trad-core.c"], "", "", ""
    if match(host, "x86_64-*-linux*"):
        return [], "", '"hosts/x86-64linux.h"', ""
    if match(host, "x86_64-*-netbsd*", "x86_64-*-openbsd*", "arm*-*-netbsd*", "arm-*-openbsd*", "powerpc-*-*bsd*"):
        return ["netbsd-core.c"], "", "", ""
    return [], "", "", ""


@functools.cache
def configure_bfd(
    srcdir: Path, triple: str, host64: bool, enable_64_bit_bfd: bool
) -> tuple[Data, tuple[str, ...], bool]:
    """bfd/config.bfd and bfd/configure.ac:319-803 for a native build of TRIPLE.

    Returns the bfd data, the selected architectures (for opcodes) and
    whether symbols get a leading underscore (for binutils).  `srcs` is
    @bfd_backends@ @bfd_machines@ @COREFILE@ @bfd64_libs@ (Makefile.am:674)
    without `plugin.c`: --enable-plugins is a flag, and the BUILD file adds
    it.  DEFAULT_LD_Z_SEPARATE_CODE is likewise only reported as a default.
    """
    code, values, err = sh(
        f"""
targ={triple}
host64={"true" if host64 else "false"}
want64={"true" if enable_64_bit_bfd else "false"}
enable_obsolete=no
. ./bfd/config.bfd || exit 1
print_var targ_defvec targ_selvecs targ_archs targ_cflags targ_underscore want64
""",
        srcdir,
    )
    if code != 0:
        raise SystemExit(f"config.bfd: {triple}: {err.strip()}")
    want64 = enable_64_bit_bfd or values["want64"] == "true"
    defvec = values["targ_defvec"]
    selvecs = uniq([defvec] + values["targ_selvecs"].split())
    selarchs = uniq(values["targ_archs"].split())

    tb: list[str] = []
    target64 = False
    default_target_size = 32
    for vec in selvecs:
        files, size = vector_files(srcdir, vec)
        tb += files
        target64 = target64 or size == 64
        if vec == defvec:
            default_target_size = size
    tb = uniq(tb)

    # `ta=`echo $selarchs | sed -e s/bfd_/cpu-/g -e s/_arch/.lo/g -e s/mn10200/m10200/ -e s/mn10300/m10300/``
    ta = uniq(
        [
            "cpu-" + a[len("bfd_") : -len("_arch")].replace("mn10200", "m10200").replace("mn10300", "m10300") + ".c"
            for a in selarchs
        ]
    )

    obj_maybe = {
        "elf.c": "OBJ_MAYBE_ELF",
        "elf-attrs.c": "OBJ_MAYBE_ELF_ATTRIBUTES",
        "elf-sframe.c": "OBJ_MAYBE_ELF_SFRAME",
        "elf-solaris2.c": "OBJ_MAYBE_ELF_SOLARIS2",
        "elf-vxworks.c": "OBJ_MAYBE_ELF_VXWORKS",
    }
    defines = [flag[len("-D") :] for flag in values["targ_cflags"].split()] + [
        obj_maybe[f] for f in tb if f in obj_maybe
    ]
    defines += ["HAVE_" + vec for vec in selvecs]

    wordsize = 64 if (host64 or target64 or want64) else 32
    tdefaults = ["DEFAULT_VECTOR=" + defvec]
    if selvecs:
        tdefaults.append("SELECT_VECS=" + ",".join("&" + v for v in selvecs))
    if selarchs:
        tdefaults.append("SELECT_ARCHITECTURES=" + ",".join("&" + a for a in selarchs))

    # Native, so the core file support of the host applies.
    core_files, trad_header, core_header, core_header_want64 = bfd_core(triple)
    defines += [{"netbsd-core.c": "NETBSD_CORE", "trad-core.c": "TRAD_CORE"}[f] for f in core_files]
    core_header = core_header or (core_header_want64 if want64 else "")
    if core_header:
        defines.append("CORE_HEADER=" + shell_token(core_header))
    if trad_header:
        defines.append("TRAD_HEADER=" + shell_token(trad_header))

    data = {
        "srcs": tb + ta + core_files + (["archive64.c"] if wordsize == 64 else []),
        "defines": defines,
        "tdefaults": tdefaults,
        "wordsize": wordsize,
        "default_target_size": default_target_size,
        # bfd/configure.ac:119-131: -z separate-code defaults on for Linux/x86.
        "defaults": {"separate_code": match(triple, "i[3-7]86-*-linux-*", "x86_64-*-linux-*")},
    }
    return data, tuple(selarchs), values["targ_underscore"] == "yes"


# ---------------------------------------------------------------------------
# opcodes


@functools.cache
def configure_opcodes(srcdir: Path, selarchs: tuple[str, ...], mips_elf: bool) -> Data:
    """opcodes/configure.ac:236-396 for the configured architectures SELARCHS."""
    fragment = shell_fragment(srcdir / "opcodes" / "configure.ac", "    for arch in $selarchs", "    done")
    code, values, err = sh(
        f"""
selarchs="{" ".join(selarchs)}"
ta=
archdefs=
using_cgen=no
{fragment}
if test $using_cgen = yes ; then
    ta="$ta cgen-opc.lo cgen-asm.lo cgen-dis.lo cgen-bitset.lo"
fi
print_var ta archdefs
""",
        srcdir,
    )
    if code != 0:
        raise SystemExit(f"architecture table: {err.strip()}")
    defines = [d[len("-D") :] for d in uniq(values["archdefs"].split())]
    # opcodes/Makefile.am:1035: mips-dis.c learns whether bfd carries the
    # MIPS ELF backend from bfd's object list.
    if mips_elf:
        defines.append("HAVE_BFD_MIPS_ELF_GET_ABIFLAGS=1")
    return {"machines": [f[: -len(".lo")] + ".c" for f in uniq(values["ta"].split())], "defines": defines}


# ---------------------------------------------------------------------------
# gas


@functools.cache
def configure_gas(srcdir: Path, triple: str) -> Data | None:
    """gas/configure.tgt and the loop body of gas/configure.ac:188-633 for TRIPLE.

    configure.tgt exits non-zero for targets gas does not support, which
    configure turns into a hard error; here it becomes `None`.  The
    `--with-*` and yes/no options are flags handled by the BUILD file; only
    their target-dependent defaults are reported, under `defaults`.
    """
    code, values, _ = sh(
        f"""
targ={triple}
ac_default_compressed_debug_sections=unset
. ./gas/configure.tgt > /dev/null || exit 1
print_var cpu_type fmt em arch endian ac_default_compressed_debug_sections
""",
        srcdir,
    )
    if code != 0 or not values["fmt"]:
        return None
    cpu_type, fmt, em = values["cpu_type"], values["fmt"], values["em"]
    if cpu_type not in GAS_CPUS:
        raise SystemExit(f"{triple}: the gas/configure.ac arms for cpu type {cpu_type} are not transcribed")
    target_cpu, target_vendor, target_os = split_triple(triple)
    generic_target = f"{cpu_type}-{target_vendor}-{target_os}"

    defines: dict[str, str] = {}
    srcs = [f"config/tc-{cpu_type}.c", f"config/obj-{fmt}.c", "config/atof-ieee.c"]
    if values["endian"] in ("big", "little"):
        defines["TARGET_BYTES_BIG_ENDIAN"] = "1" if values["endian"] == "big" else "0"
    if cpu_type == "mips":
        defines.update(gas_mips(triple))
    # gas/configure.ac:386-388: every cpu here but i386 has ELF object attributes.
    if cpu_type != "i386":
        srcs.append("config/obj-elf-attr.c")
    # gas/configure.ac:391-525.
    if cpu_type == "mips":
        srcs += ["itbl-parse.c", "itbl-lex-wrapper.c", "itbl-ops.c"]
    if cpu_type in ("aarch64", "i386", "s390", "riscv"):
        defines["DEFAULT_ARCH"] = cstring(values["arch"])
    if fmt == "coff" and cpu_type == "i386":
        defines["I386COFF"] = "1"
    # gas/configure.ac:579-585 and :607-660: MIPS is the one multi-emulation
    # assembler here; its emulations all use ELF and the one e-mipself.c.
    emulations: list[str] = []
    if cpu_type == "mips":
        emulations = (
            ["mipsbelf", "mipslelf", "mipself"] if values["endian"] == "big" else ["mipslelf", "mipsbelf", "mipself"]
        )
        srcs.append("config/e-mipself.c")
        defines["USE_EMULATIONS"] = "1"
    defines["EMULATIONS"] = shell_token(" ".join("&" + e + "," for e in emulations))
    defines["DEFAULT_EMULATION"] = cstring(emulations[0] if emulations else "")
    # gas/configure.ac:760-764.  A native build, so no CROSS_COMPILE.
    defines["TARGET_ALIAS"] = cstring(triple)
    defines["TARGET_CANONICAL"] = cstring(triple)
    defines["TARGET_CPU"] = cstring(target_cpu)
    defines["TARGET_VENDOR"] = cstring(target_vendor)
    defines["TARGET_OS"] = cstring(target_os)

    return {
        "srcs": uniq(srcs),
        "defines": [f"{k}={v}" for k, v in defines.items()],
        # The indirection headers (gas/configure.ac:1047-1057) are built from these.
        "cpu_type": cpu_type,
        "obj_format": fmt,
        "em": em,
        # gas/configure.ac:486-511: the --with-arch family applies to RISC-V only.
        "riscv": cpu_type == "riscv",
        "defaults": {
            # gas/configure.ac:247-252.
            "x86_used_note": match(generic_target, "i386-*-linux-*", "x86_64-*-linux-*"),
            # gas/configure.tgt:470-477.
            "compress_debug": values["ac_default_compressed_debug_sections"] == "yes",
        },
    }


def gas_mips(triple: str) -> dict[str, str]:
    """gas/configure.ac:280-377, the MIPS assembler defaults, for the `mips64` cpu."""
    if split_triple(triple)[0] != "mips64":
        raise SystemExit(f"{triple}: the MIPS assembler defaults are only transcribed for the mips64 cpu")
    if match(triple, "mips64*-openbsd*", "mips64*-linux-gnuabi64"):
        abi = "N64_ABI"
    elif match(triple, "mips64*-linux*", "mips64*-freebsd*"):
        abi = "N32_ABI"
    else:
        abi = "NO_ABI"
    return {
        "MIPS_CPU_STRING_DEFAULT": cstring("from-abi"),
        "USE_EF_MIPS_ABI_O32": "1",
        "MIPS_DEFAULT_64BIT": "1",
        "MIPS_DEFAULT_ABI": abi,
    }


# ---------------------------------------------------------------------------
# ld


@functools.cache
def configure_ld(srcdir: Path, triple: str, have_64_bit_bfd: bool) -> Data | None:
    """ld/configure.tgt and the loop of ld/configure.ac:423-560 for a native TRIPLE.

    The `ac_default_*` variables are seeded the way ld/configure.ac seeds
    them before sourcing, so the values read back are the target's defaults
    with no --enable option given; the BUILD file applies the flags on top.
    """
    code, values, _ = sh(
        f"""
targ={triple}
target={triple}
targ_alias={triple}
ac_default_ld_warn_rwx_segments=unset
ac_default_ld_warn_execstack=2
ac_default_ld_z_relro=unset
ac_default_ld_z_separate_code=unset
ac_default_ld_textrel_check=unset
. ./ld/configure.tgt > /dev/null 2>&1 || exit 1
print_var targ_emul targ_extra_emuls targ_extra_libpath targ_extra_ofiles targ64_extra_emuls targ64_extra_libpath NATIVE_LIB_DIRS ac_default_ld_warn_rwx_segments ac_default_ld_warn_execstack ac_default_ld_z_relro ac_default_ld_z_separate_code ac_default_ld_textrel_check
set | sed -n 's/^\\(tdir_[A-Za-z0-9_]*\\)=.*/\\1/p' | while read -r n; do print_var "$n"; done
""",
        srcdir,
    )
    if code != 0 or not values.get("targ_emul"):
        return None
    emul = values["targ_emul"]
    extra_emuls = values["targ_extra_emuls"].split()
    extra_libpath = values["targ_extra_libpath"].split()
    if have_64_bit_bfd:
        extra_emuls += values["targ64_extra_emuls"].split()
        extra_libpath += values["targ64_extra_libpath"].split()
    emulations = uniq([emul] + extra_libpath + extra_emuls)
    tdirs = {k[len("tdir_") :]: v.strip("'") for k, v in values.items() if k.startswith("tdir_")}
    for e in emulations:
        if not (srcdir / "ld" / "emulparams" / f"{e}.sh").is_file():
            raise SystemExit(f"ld: no emulparams for {e}")

    options = ld_list_options(srcdir, triple, emulations)
    return {
        "emulations": emulations,
        "libpath": uniq([emul] + extra_libpath),
        "extra_srcs": [f[: -len(".o")] + ".c" for f in values["targ_extra_ofiles"].split()],
        # tdir_* of the emulations whose tool directory is not the platform's own.
        "tdirs": {e: tdirs[e] for e in emulations if tdirs.get(e, triple) != triple},
        "native_lib_dirs": values["NATIVE_LIB_DIRS"].split(),
        "defines": [
            # ld/Makefile.am:42-45.
            "ELF_LIST_OPTIONS=" + ("true" if options["elf"] else "false"),
            "ELF_SHLIB_LIST_OPTIONS=" + ("true" if options["shlib"] else "false"),
            "ELF_PLT_UNWIND_LIST_OPTIONS=" + ("true" if options["plt_unwind"] else "false"),
            "ELF_SFRAME_LIST_OPTIONS=" + ("true" if options["sframe"] else "false"),
            # ld/Makefile.am:313-316.
            "DEFAULT_EMULATION=" + cstring(emul),
            "TARGET=" + cstring(triple),
        ],
        "defaults": {
            "warn_rwx_segments": values["ac_default_ld_warn_rwx_segments"] != "0",
            "warn_execstack": values["ac_default_ld_warn_execstack"],
            "z_relro": values["ac_default_ld_z_relro"] == "1",
            "z_separate_code": values["ac_default_ld_z_separate_code"] == "1",
            "textrel_check": values["ac_default_ld_textrel_check"],
            # ld/configure.ac:300-310.
            "hash_style": "both"
            if match(triple, "*-*-gnu*", "*-*-linux*") and not match(triple, "mips*-*-*")
            else "sysv",
        },
    }


def ld_list_options(srcdir: Path, triple: str, emulations: list[str]) -> dict[str, bool]:
    """The elf_*_list_options of ld/configure.ac:466-492.

    configure walks the emulations in order; the first ELF one (by name, or
    by TEMPLATE_NAME=elf in its emulparams file) turns `elf_list_options`
    on, and from then on every emulparams file is sourced, in the configure
    shell where `target` is set, with the variables it sets persisting.
    """
    options = {"elf": False, "shlib": False, "plt_unwind": False, "sframe": False}
    for emul in emulations:
        params = srcdir / "ld" / "emulparams" / f"{emul}.sh"
        if "elf" in emul or "TEMPLATE_NAME=elf" in params.read_text():
            options["elf"] = True
        if not options["elf"]:
            continue
        code, values, err = sh(
            f"""
srcdir=./ld
target={triple}
host={triple}
EMULATION_NAME={emul}
source_sh() {{ . "$1"; }}
. ./ld/emulparams/{emul}.sh
print_var GENERATE_SHLIB_SCRIPT PLT_UNWIND SFRAME_INFO
""",
            srcdir,
        )
        if code != 0:
            raise SystemExit(f"ld: emulparams/{emul}.sh: {err.strip()}")
        options["shlib"] = options["shlib"] or values["GENERATE_SHLIB_SCRIPT"] == "yes"
        options["plt_unwind"] = options["plt_unwind"] or values["PLT_UNWIND"] == "yes"
        options["sframe"] = options["sframe"] or values["SFRAME_INFO"] == "yes"
    return options


# ---------------------------------------------------------------------------
# binutils


@functools.cache
def configure_binutils(srcdir: Path, triple: str, underscore: bool) -> Data:
    """binutils/configure.tgt and binutils/configure.ac:259-468 for TRIPLE.

    Of the PE tool arms only mingw is reachable (WinCE, Interix and Cygwin
    are not PLATFORMS triples), and of the objdump private vectors only PE
    and Mach-O (not AVR or AIX).  A non-empty `dlltool_defs` means the PE
    tools (dlltool, windres, windmc, dllwrap) are built.
    """
    code, values, err = sh(f"targ={triple}\n. ./binutils/configure.tgt\nprint_var targ_emul targ_emul_vector\n", srcdir)
    if code != 0:
        raise SystemExit(f"binutils/configure.tgt: {triple}: {err}")
    dlltool_defs: list[str] = []
    if match(triple, "aarch64-*-mingw*"):
        dlltool_defs = ["DLLTOOL_AARCH64", "DLLTOOL_DEFAULT_AARCH64"]
    elif match(triple, "i[3-7]86-*-mingw32*"):
        dlltool_defs = ["DLLTOOL_I386", "DLLTOOL_DEFAULT_I386"]
    elif match(triple, "x86_64-*-mingw*"):
        dlltool_defs = ["DLLTOOL_MX86_64", "DLLTOOL_DEFAULT_MX86_64"]
    od_vectors: list[str] = []
    if match(triple, "*-*-pe*", "*-*-cygwin*", "*-*-mingw*", "*-*-interix*"):
        od_vectors.append("objdump_private_desc_pe")
    if match(triple, "*-*-darwin*"):
        od_vectors.append("objdump_private_desc_mach_o")
    od_files = {"objdump_private_desc_pe": "od-pe.c", "objdump_private_desc_mach_o": "od-macho.c"}
    return {
        "emul_srcs": ["emul_" + values["targ_emul"] + ".c"],
        "od_srcs": [od_files[v] for v in od_vectors],
        "defines": [
            "bin_dummy_emulation=" + values["targ_emul_vector"],
            "TARGET=" + cstring(triple),
            "TARGET_PREPENDS_UNDERSCORE=" + ("1" if underscore else "0"),
        ],
        # binutils/Makefile.am passes it as -DOBJDUMP_PRIVATE_VECTORS="$(...)";
        # the quotes make it one shell token and are gone by the time cc sees it.
        "objdump_defs": ["OBJDUMP_PRIVATE_VECTORS=" + shell_token("".join(" &" + v + "," for v in od_vectors))],
        "dlltool_defs": dlltool_defs,
    }


# ---------------------------------------------------------------------------
# The top-level configure.ac


@functools.cache
def configdirs(srcdir: Path, triple: str) -> dict[str, bool]:
    """Which programs the top level keeps for TRIPLE.

    Runs the `case "${target}"` whose first arm is `*-*-chorusos` (top-level
    configure.ac:1103-1402 in 2.47), with the m4 quadrigraphs turned back
    into shell brackets.
    """
    text = (srcdir / "configure.ac").read_text().splitlines()
    arm = next(i for i, line in enumerate(text) if line == "  *-*-chorusos)" and text[i - 1] == 'case "${target}" in')
    fragment = "\n".join(text[arm - 1 : text.index("esac", arm) + 1]).replace("[[", "[").replace("]]", "]")
    code, values, err = sh(
        f"target={triple}\nnoconfigdirs=\nwith_newlib=\nwith_avrlibc=\n{fragment}\nprint_var noconfigdirs\n", srcdir
    )
    if code != 0:
        raise SystemExit(f"top-level configure.ac: {triple}: {err}")
    dropped = values["noconfigdirs"].split()
    return {name: name not in dropped for name in ("gas", "gprof", "ld")}


# ---------------------------------------------------------------------------
# Output


def starlark(value: Any, indent: int = 0) -> str:
    """Render VALUE as Starlark source, one entry per line, dict keys sorted."""
    pad = "    " * indent
    inner = "    " * (indent + 1)
    if isinstance(value, bool):
        return "True" if value else "False"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, Ref):
        return str(value)
    if isinstance(value, str):
        return '"' + value.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n") + '"'
    if value is None:
        return "None"
    if isinstance(value, list):
        if not value:
            return "[]"
        return "[\n" + "".join(f"{inner}{starlark(v, indent + 1)},\n" for v in value) + pad + "]"
    if isinstance(value, dict):
        if not value:
            return "{}"
        items = "".join(f"{inner}{starlark(k)}: {starlark(v, indent + 1)},\n" for k, v in sorted(value.items()))
        return "{\n" + items + pad + "}"
    raise TypeError(type(value))


HEADER = '''\
"""The platforms binutils {version} is built for; see PLATFORMS in generate_targets.py.

GENERATED by modules/binutils/generate_targets.py; do not edit.
"""

visibility(["//..."])

'''

COMPONENT_HEADER = '''\
"""The {package} configuration of binutils {version}, per platform of //:targets.bzl.

GENERATED by modules/binutils/generate_targets.py; do not edit.  Results
identical between platforms are shared, named after the first platform using them.
"""

visibility(["//..."])

'''

# Package -> components written to its targets.bzl, each as the upper-cased
# Starlark table; `_64` is the --enable-64-bit-bfd twin.
FILES = {
    "bfd": ["bfd", "bfd_64"],
    "opcodes": ["opcodes"],
    "gas": ["gas"],
    "ld": ["ld", "ld_64"],
    "binutils": ["binutils"],
}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("srcdir", type=Path, help="unpacked binutils release tree")
    srcdir: Path = parser.parse_args().srcdir.resolve()

    version = re.search(r"\[BFD_VERSION\], \[([^]]+)\]", (srcdir / "bfd" / "version.m4").read_text())
    if not version:
        raise SystemExit("cannot read bfd/version.m4")
    overlay = Path(__file__).resolve().parent / version.group(1) / "overlay"

    # The configure_* functions are cached: platforms sharing a triple
    # (Linux, NixOS, ChromiumOS) resolve to the same shell runs.
    canonical: dict[str, str] = {}
    platforms: dict[str, Data] = {}
    for os_, cpus in PLATFORMS.items():
        for cpu, triple in cpus.items():
            if triple not in canonical:
                canonical[triple] = subprocess.run(
                    ["/bin/sh", "config.sub", triple], cwd=srcdir, capture_output=True, text=True, check=True
                ).stdout.strip()
            if canonical[triple] != triple:
                raise SystemExit(f"{triple} is not canonical; config.sub says {canonical[triple]}")
            host64 = cpu in HOST64_CPUS
            dirs = configdirs(srcdir, triple)
            bfd, selarchs, underscore = configure_bfd(srcdir, triple, host64, enable_64_bit_bfd=False)
            bfd_64 = configure_bfd(srcdir, triple, host64, enable_64_bit_bfd=True)[0]
            platforms[f"{os_}_{cpu}"] = {
                "constraints": [f"@platforms//os:{os_}", f"@platforms//cpu:{cpu}"],
                "triple": triple,
                "bfd": bfd,
                "bfd_64": bfd_64,
                "opcodes": configure_opcodes(srcdir, selarchs, "elfxx-mips.c" in bfd["srcs"]),
                "gas": configure_gas(srcdir, triple) if dirs["gas"] else None,
                "ld": configure_ld(srcdir, triple, bfd["wordsize"] == 64) if dirs["ld"] else None,
                "ld_64": configure_ld(srcdir, triple, bfd_64["wordsize"] == 64) if dirs["ld"] else None,
                "binutils": configure_binutils(srcdir, triple, underscore),
                "gprof": dirs["gprof"],
            }

    written: list[Path] = []

    def write(path: Path, body: str) -> None:
        path.write_text(body)
        written.append(path)

    table = {
        key: {
            "constraints": entry["constraints"],
            "triple": entry["triple"],
            "bfd64_differs": entry["bfd"] != entry["bfd_64"],
            "gas": entry["gas"] is not None,
            "ld": entry["ld"] is not None,
            "gprof": entry["gprof"],
            "pe_tools": bool(entry["binutils"]["dlltool_defs"]),
        }
        for key, entry in platforms.items()
    }
    write(overlay / "targets.bzl", HEADER.format(version=version.group(1)) + "PLATFORMS = " + starlark(table) + "\n")

    # One data file per package.  Identical results are written once and
    # referenced, under the name of the first table entry that uses them:
    # platforms that share a triple, and the `_64` twin where
    # --enable-64-bit-bfd changes nothing.  On the way, check that every
    # define is one shell token, since Bazel tokenizes `local_defines`.
    for package, components in FILES.items():
        shared: dict[str, Ref] = {}
        constants = ""
        rendered: dict[str, dict[str, Ref | None]] = {c.upper(): {} for c in components}
        for component in components:
            name = component.upper()
            for key, entry in platforms.items():
                value = entry[component]
                if value is None:
                    rendered[name][key] = None
                    continue
                for field in ("defines", "objdump_defs", "dlltool_defs"):
                    for define in value.get(field, []):
                        if len(shlex.split(define)) != 1:
                            raise SystemExit(
                                f"{key}: {component}.{field} entry {define!r} is more than one shell token"
                            )
                ident = json.dumps(value, sort_keys=True)
                if ident not in shared:
                    shared[ident] = Ref(f"_{name}_{key.upper()}")
                    constants += f"{shared[ident]} = " + starlark(value) + "\n\n"
                rendered[name][key] = shared[ident]
        body = COMPONENT_HEADER.format(package=package, version=version.group(1)) + constants
        body += "".join(f"{name} = " + starlark(table) + "\n\n" for name, table in rendered.items())
        write(overlay / package / "targets.bzl", body)

    # targmatch.h (bfd/Makefile.am:717-720): `sed -f targmatch.sed < config.bfd`,
    # a pure function of two tarball files, so it is produced here rather
    # than by a shell action at build time.
    sed = subprocess.run(
        ["sed", "-f", "bfd/targmatch.sed", "bfd/config.bfd"], cwd=srcdir, capture_output=True, text=True, check=True
    )
    (overlay / "bfd" / "targmatch.h").write_text(
        "/* GENERATED by modules/binutils/generate_targets.py: the output of\n"
        "   `sed -f targmatch.sed < config.bfd` (bfd/Makefile.am:717-720).  */\n" + sed.stdout
    )
    buildifier = shutil.which("buildifier")
    if buildifier:
        subprocess.run([buildifier, *map(str, written)], check=True)
    print(f"wrote {overlay}/targets.bzl ({len(platforms)} platforms) and the packages' targets.bzl files")


if __name__ == "__main__":
    main()
