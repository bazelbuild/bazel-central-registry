#!/usr/bin/env python3
"""Generates the per-platform build data of a GRUB module version.

Usage:
    python3 modules/grub/generate_platform_data.py /path/to/grub-2.14

Reads the extracted release and writes, into modules/grub/<version>/overlay/platform/:

    <platform>.bzl   one dict per firmware platform (I386_PC = {...})
    modules.bzl      the module entries that are the same on every platform
    platforms.bzl    the platform list, gentpl's groups and the PLATFORM_DATA index

platform/BUILD.bazel, platform.bzl and common.bzl are maintained by hand.

How to read this file.  It is four stages, in the order they appear below:

1. UPSTREAM'S PARSER.  gentpl.py, the script GRUB itself uses to turn
   grub-core/Makefile.core.def into Makefile rules, is loaded from the tarball
   and asked which kernel, module and image entries a platform enables and with
   which sources and flags.  Nothing here re-implements the def file format.

2. TARGET FLAGS.  configure.ac's target-compiler section, transcribed step by
   step: each step is either a literal flag configure always adds or a probe
   (candidate flags tried until one compiles).  The BUILD file runs the probes
   as rules_cc_autoconf checks; apply_steps() records what GCC answers, for the
   static target_* lists.  This is the one stage to re-check against
   configure.ac when a new release changes its compiler probes.

3. DEF ENTRIES.  Each enabled entry with its $(...) Makefile variables
   expanded and its sources as repository paths, plus KERNEL_HEADER_FILES from
   grub-core/Makefile.am.

4. OUTPUT.  The dicts as Starlark, through buildifier, with source paths as
   Label()s and the module entries shared by every platform factored out into
   modules.bzl.

Stages 1, 3 and 4 follow a release automatically; the output for a new
release is byte-for-byte reproducible by re-running this script.
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
from pathlib import Path
from typing import Any

Entry = dict[str, Any]
# {"cflags": [...], "ccasflags": [...], "cppflags": [...], "ldflags": [...], "subst": {...}}
Flags = dict[str, Any]

# =============================================================================
# 1. UPSTREAM'S PARSER
# =============================================================================

# gentpl.py's platform names are <cpu>_<platform>; these are the cpus, longest
# first so that `x86_64_efi` is not split at `x86`.
CPUS = ["x86_64", "loongarch64", "riscv32", "riscv64", "sparc64", "powerpc", "arm64", "i386", "mips", "ia64", "arm"]

# gentpl's mips platforms stand for both endiannesses; configure's $target_cpu
# tells them apart.  loongson is mipsel only; arc and qemu_mips get a `mipsel_`
# variant that shares the gentpl tables.
MIPSEL_VARIANTS = {"mips_arc": "mipsel_arc", "mips_qemu_mips": "mipsel_qemu_mips"}


class Gentpl:
    """gentpl.py's definitions parser and platform helpers, loaded from the source tree."""

    def __init__(self, src: Path) -> None:
        # gentpl.py is a script; everything above its option parser is the library part.
        text = (src / "gentpl.py").read_text().split("parser = OptionParser")[0]
        namespace: dict[str, Any] = {}
        exec(compile(text, "gentpl.py", "exec"), namespace)  # noqa: S102
        self.ns = namespace
        self.defs = namespace["defparser"]
        self.defs.read_definitions(str(src / "grub-core" / "Makefile.core.def"))
        self.defs.read_definitions(str(src / "grub-core" / "Makefile.gcry.def"))
        self.platforms: list[str] = list(namespace["GRUB_PLATFORMS"])
        self.groups: dict[str, list[str]] = {k: list(v) for k, v in namespace["GROUPS"].items()}

    def values(self, defn: Any, platform: str, kind: str) -> str:
        """`platform_<kind>(defn, platform)`: the def's value of a field for the platform."""
        result: str = self.ns["platform_" + kind](defn, platform)
        return result.strip()

    def tagged(self, defn: Any, platform: str, tag: str) -> bool:
        return bool(self.ns["platform_tagged"](defn, platform, tag))

    def enabled(self, defn: Any, platform: str) -> bool:
        return self.tagged(defn, platform, "enable") if "enable" in defn else True


def split(name: str) -> tuple[str | None, str]:
    """A platform name into (cpu, platform); `mipsel_*` is the mips cpu."""
    if name == "emu":
        return None, "emu"
    for c in CPUS + ["mipsel"]:
        if name.startswith(c + "_"):
            return ("mips" if c == "mipsel" else c), name[len(c) + 1 :]
    raise SystemExit(name)


def target_cpu(name: str) -> str | None:
    """configure's $target_cpu for the platform."""
    cpu, _ = split(name)
    return "mipsel" if name.startswith("mipsel_") or name == "mips_loongson" else cpu


# =============================================================================
# 2. TARGET FLAGS (configure.ac's target-compiler section)
# =============================================================================
#
# A platform's flags are a list of *steps*.  A step is either
#
#   {"literal": {"cflags": [...], "cppflags": [...], ...}}          flags configure adds outright
#   {"probe": name, "code": program, "candidates": [{"flags", "to"}]} flags it adds when a compile passes
#
# A probe tries its candidates in order and the first whose program compiles
# contributes its `to` flags, as configure's `for cand in ...` loops do.
# `negate` makes a failing compile the hit (the `#error` style probes),
# `otherwise` is what a probe contributes when every candidate misses, and
# `when` makes a step depend on an earlier probe's hit (`pie`) or miss
# (`!clang`).  The `gcc` index on a probe is not emitted: it says which
# candidate GCC and GNU ld take, and only feeds the static target_* lists.
#
# Line numbers below refer to GRUB 2.14's configure.ac.

# The GRUB_MACHINE_* define of each platform (configure.ac, `case "$platform"`).
MACHINE = {
    "coreboot": "COREBOOT",
    "multiboot": "MULTIBOOT",
    "efi": "EFI",
    "xen": "XEN",
    "xen_pvh": "XEN_PVH",
    "ieee1275": "IEEE1275",
    "uboot": "UBOOT",
    "qemu": "QEMU",
    "pc": "PCBIOS",
    "emu": "EMU",
    "loongson": "MIPS_LOONGSON",
    "qemu_mips": "MIPS_QEMU_MIPS",
    "arc": "ARC",
}

# The programs configure's probes compile (acinclude.m4, configure.ac).
TRIVIAL = "int main (void) { return 0; }\n"
CLANG_CODE = "#ifndef __clang__\n#error not clang\n#endif\n" + TRIVIAL
PIE_CODE = "#ifdef __PIE__\n#error PIE by default\n#endif\n" + TRIVIAL
PIC_CODE = "#ifdef __PIC__\n#error PIC by default\n#endif\n" + TRIVIAL
SSP_CODE = "char foo (void) { volatile char a[8]; a[3] = 1; return a[3]; }\n"  # configure's, made -Wall -Werror clean
USCORE_CODE = (
    "#define GRUB_STR_(x) #x\n#define GRUB_STR(x) GRUB_STR_(x)\n"
    'int main (void) { _Static_assert (sizeof (GRUB_STR (__USER_LABEL_PREFIX__)) == 1, "prefix"); return 0; }\n'
)
MIPS_O32_CODE = (
    "#if !defined(_ABIO32) || !defined(_MIPS_SIM) || (_MIPS_SIM != _ABIO32)\n#error not o32 ABI\n#endif\n" + TRIVIAL
)


def every(flag: str) -> Flags:
    """A flag configure adds to all four of CFLAGS, CPPFLAGS, CCASFLAGS and LDFLAGS."""
    return {"cflags": [flag], "cppflags": [flag], "ccasflags": [flag], "ldflags": [flag]}


def literal(when: str | None = None, **to: Any) -> Entry:
    step: Entry = {"literal": to}
    if when:
        step["when"] = when
    return step


def probe(
    name: str,
    candidates: list[tuple[list[str], Flags]],
    gcc: int | None = 0,
    code: str = TRIVIAL,
    negate: bool = False,
    when: str | None = None,
    copts: list[str] | None = None,
    otherwise: Flags | None = None,
) -> Entry:
    """A configure probe: the first candidate whose flags compile contributes its `to` flags.

    `gcc` is the index of the candidate GCC and GNU ld take, None if none does;
    it only feeds the static lists.  `negate` makes a failing compile the hit
    (the `#error` style probes).
    """
    step: Entry = {
        "probe": name,
        "code": code,
        "candidates": [{"flags": flags, "to": to} for flags, to in candidates],
        "gcc": gcc,
    }
    if negate:
        step["negate"] = True
    if when:
        step["when"] = when
    if copts:
        step["copts"] = copts
    if otherwise:
        step["otherwise"] = otherwise
    return step


def cflag_probe(name: str, flag: str, gcc: int | None = 0) -> Entry:
    """The common `AC_CACHE_CHECK([whether <flag> works], ...)` that adds <flag> to TARGET_CFLAGS."""
    return probe(name, [([flag], {"cflags": [flag]})], gcc=gcc)


# --- the steps, in configure.ac's order -------------------------------------


def _base_flags(name: str, cpu: str | None, plat: str, tcpu: str | None, new: bool) -> list[Entry]:
    """TARGET_CFLAGS/TARGET_CPPFLAGS as configure starts them (configure.ac:101, :586-604).

    `-std=gnu99 -Os` (2.14 adds `-fno-common`), the GRUB_CPU_* and
    GRUB_MACHINE* defines, `-m32`/`-m64` where the cpu needs saying, and `-g`.
    """
    emu = plat == "emu"
    cpp = []
    if tcpu == "mipsel":
        cpp.append("-DGRUB_CPU_MIPSEL=1")
    if tcpu == "mips":
        cpp.append("-DGRUB_CPU_MIPS=1")
    cpp.append(f"-DGRUB_MACHINE_{MACHINE[plat]}=1")
    if not emu and tcpu:
        cpp.append("-DGRUB_MACHINE=" + ("mips" if tcpu == "mipsel" else tcpu).upper() + "_" + plat.upper())
    steps = [literal(cflags=["-std=gnu99"] + (["-fno-common"] if new else []) + ["-Os"], cppflags=cpp)]
    if (cpu in ("i386", "powerpc") and not emu) or (cpu in ("x86_64", "sparc64") and not emu) or name == "sparc64_emu":
        m = "-m32" if cpu in ("i386", "powerpc") else "-m64"
        steps.append(literal(cflags=[m], ccasflags=[m], cppflags=[m], ldflags=[m]))
    steps.append(literal(cflags=["-g"], ccasflags=["-g"]))
    return steps


def _endianness_and_abi(tcpu: str | None, mips: bool) -> list[Entry]:
    """Big-endian powerpc and mips (configure.ac:646), little-endian mips, and the mips o32 ABI (:721)."""
    steps = []
    if tcpu in ("powerpc", "mips"):
        steps.append(
            probe(
                "big_endian",
                [(["-EB"], every("-EB")), (["-mbig-endian"], every("-mbig-endian"))],
                gcc=1 if tcpu == "powerpc" else 0,
            )
        )
    if tcpu == "mipsel":
        steps.append(probe("little_endian", [(["-EL"], every("-EL"))]))
    if mips:
        steps.append(
            probe(
                "mips_o32_abi",
                [([], {}), (["-mabi=32"], {"cflags": ["-mabi=32"], "ccasflags": ["-mabi=32"]})],
                gcc=1,
                code=MIPS_O32_CODE,
            )
        )
    return steps


def _compiler_identity() -> list[Entry]:
    """Whether the target compiler is clang (configure.ac:637); later steps key on the answer."""
    return [probe("clang", [([], {})], gcc=None, code=CLANG_CODE)]


def _i386_tuning(cpu: str | None, plat: str, emu: bool, new: bool) -> list[Entry]:
    """i386's `-march=i386`, the GCC-only `-mrtd -mregparm=3` (configure.ac:791) and the alignment probes (:825-843)."""
    steps = []
    if cpu == "i386" and not emu:
        steps.append(literal(cflags=["-march=i386"]))
        if plat != "efi":
            steps.append(literal(when="!clang", cflags=["-mrtd", "-mregparm=3"]))
    if cpu == "i386":
        if new:
            steps.append(literal(cflags=["-falign-functions=1"]))
            steps.append(cflag_probe("falign_loops", "-falign-loops=1"))
            steps.append(cflag_probe("falign_jumps", "-falign-jumps=1"))
        else:
            # 2.06 probes one spelling and adds all three at once.
            falign = ["-falign-jumps=1", "-falign-loops=1", "-falign-functions=1"]
            malign = ["-malign-jumps=1", "-malign-loops=1", "-malign-functions=1"]
            steps.append(
                probe("falign", [(["-falign-loops=1"], {"cflags": falign}), (["-malign-loops=1"], {"cflags": malign})])
            )
    return steps


def _mips_tuning(mips: bool, new: bool) -> list[Entry]:
    """mips' `-mflush-func=grub_red_herring` (configure.ac:796) and, in 2.14, `-mno-gpopt` (:807)."""
    steps = []
    if mips:
        steps.append(cflag_probe("mflush_func", "-mflush-func=grub_red_herring"))
        if new:
            steps.append(cflag_probe("mno_gpopt", "-mno-gpopt"))
    return steps


def _calling_convention(x86: bool, emu: bool) -> list[Entry]:
    """`-freg-struct-return` (configure.ac:847) and no vector units on x86 (:861)."""
    steps = [cflag_probe("freg_struct_return", "-freg-struct-return")]
    if x86 and not emu:
        steps.append(literal(cflags=["-mno-mmx", "-mno-sse", "-mno-sse2", "-mno-sse3", "-mno-3dnow"]))
    return steps


def _assembler_and_relocations(cpu: str | None, x86: bool, new: bool) -> list[Entry]:
    """2.14's assembler notes and relocation modes: x86 (configure.ac:865), loongarch64 (:880, :912), riscv (:919)."""
    steps = []
    if new and x86:
        steps.append(
            probe(
                "mx86_used_note",
                [
                    (
                        ["-Wa,-mx86-used-note=no"],
                        {"cflags": ["-Wa,-mx86-used-note=no"], "ccasflags": ["-Wa,-mx86-used-note=no"]},
                    )
                ],
            )
        )
    if new and cpu == "loongarch64":
        relocs = ["-mno-explicit-relocs", "-fno-plt"]
        steps.append(probe("mno_explicit_relocs", [(relocs, {"cflags": relocs, "ccasflags": relocs})]))
    if new and cpu in ("loongarch64", "riscv32", "riscv64"):
        steps.append(
            probe(
                "mno_relax",
                [
                    (["-mno-relax"], {"cflags": ["-mno-relax"], "ccasflags": ["-mno-relax"]}),
                    (["-Wa,-mno-relax"], {"cflags": ["-Wa,-mno-relax"], "ccasflags": ["-Wa,-mno-relax"]}),
                ],
            )
        )
    if new and cpu == "loongarch64":
        steps.append(literal(cflags=["-Wa,-mla-global-with-abs"], ccasflags=["-Wa,-mla-global-with-abs"]))
    return steps


def _soft_float(cpu: str | None, emu: bool, new: bool) -> list[Entry]:
    """No floating point in the kernel (configure.ac:949-983): what that is called differs per cpu.

    sparc64 also reserves the application registers (:1014) and links without
    relaxation (:1037, a link probe upstream that GNU ld and lld both take).
    """
    steps = []
    if not emu:
        if cpu == "arm64":
            cands = [["-mgeneral-regs-only"]]
        elif cpu == "riscv32":
            cands = ([["-march=rv32imac_zicsr_zifencei", "-mabi=ilp32"]] if new else []) + [
                ["-march=rv32imac", "-mabi=ilp32"]
            ]
        elif cpu == "riscv64":
            cands = ([["-march=rv64imac_zicsr_zifencei", "-mabi=lp64"]] if new else []) + [
                ["-march=rv64imac", "-mabi=lp64"]
            ]
        elif cpu == "ia64":
            cands = [["-mno-inline-float-divide", "-mno-inline-sqrt"]]
        else:
            cands = [["-msoft-float"]]
        steps.append(probe("soft_float", [(c, {"cflags": c, "ccasflags": c}) for c in cands]))
    if cpu == "sparc64":
        steps.append(
            probe(
                "mno_app_regs",
                [
                    (
                        ["-mllvm", "-sparc-reserve-app-registers"],
                        {"cppflags": ["-mllvm", "-sparc-reserve-app-registers"]},
                    ),
                    (["-mno-app-regs"], {"cflags": ["-mno-app-regs"]}),
                ],
                gcc=1,
            )
        )
        steps.append(literal(ldflags=["-mno-relax"]))
    return steps


def _frames_and_unwinding(x86: bool, new: bool) -> list[Entry]:
    """Frame pointers (configure.ac:1062), no CFI and unwind tables, no `.ident` (:1077-1148)."""
    steps = []
    if new:
        steps.append(cflag_probe("fno_omit_frame_pointer", "-fno-omit-frame-pointer"))
    steps.append(cflag_probe("fno_dwarf2_cfi_asm", "-fno-dwarf2-cfi-asm"))
    steps.append(cflag_probe("mno_stack_arg_probe", "-mno-stack-arg-probe", gcc=0 if x86 else None))
    for flag in ["-fno-asynchronous-unwind-tables", "-fno-unwind-tables", "-fno-ident"]:
        steps.append(cflag_probe(flag.strip("-").replace("-", "_"), flag))
    return steps


def _link_format(name: str, cpu: str | None, x86: bool, emu: bool) -> list[Entry]:
    """The x86 ELF emulation (a link probe upstream; the BSD and Haiku spellings
    are the alternatives it tries after `-melf_<cpu>`) and x86_64-efi's
    `-mno-red-zone` (configure.ac:1548)."""
    steps = []
    if x86 and not emu:
        steps.append(literal(ldflags=[f"-Wl,-melf_{cpu}"]))
    if name == "x86_64_efi":
        steps.append(cflag_probe("mno_red_zone", "-mno-red-zone"))
    return steps


def _arm_relocations(cpu: str | None) -> list[Entry]:
    """arm's movt-free relocations (configure.ac:1564) and `-mthumb-interwork` (:1581)."""
    steps = []
    if cpu == "arm":
        movt = [["-mno-movt"], ["-mllvm", "-arm-use-movt=0"], ["-mword-relocations"]]
        steps.append(probe("mno_movt", [(c, {"cppflags": c}) for c in movt], gcc=2))
        steps.append(cflag_probe("mthumb_interwork", "-mthumb-interwork"))
    return steps


def _position_independence(cpu: str | None) -> list[Entry]:
    """clang's `-Qn`, then grub_CHECK_PIE and grub_CHECK_PIC: undo a PIE/PIC default.

    `-no-pie` is a link probe upstream; every PIE-defaulting driver takes it.
    clang on mips and arm64 wants PIC back (configure.ac, `-fPIC`).
    """
    return [
        probe("qn", [(["-Qn", "-Qunused-arguments"], {"cflags": ["-Qn", "-Qunused-arguments"]})], gcc=None),
        probe(
            "pie",
            [([], {"cflags": ["-fno-PIE", "-fno-pie"], "ccasflags": ["-fno-PIE", "-fno-pie"]})],
            code=PIE_CODE,
            negate=True,
        ),
        literal(when="pie", ldflags=["-no-pie"]),
        probe("pic", [([], {"cflags": ["-fno-PIC"]})], gcc=None, code=PIC_CODE, negate=True, copts=["-fno-PIE"]),
    ] + ([literal(when="clang", cflags=["-fPIC"])] if cpu in ("mips", "arm64") else [])


def _code_model(cpu: str | None) -> list[Entry]:
    """`-mcmodel=large` on x86_64; sparc64 and riscv64 fall back to `-mcmodel=medany`."""
    if cpu == "x86_64":
        return [cflag_probe("mcmodel", "-mcmodel=large")]
    if cpu in ("sparc64", "riscv64"):
        return [
            probe(
                "mcmodel",
                [(["-mcmodel=large"], {"cflags": ["-mcmodel=large"]})],
                gcc=None,
                otherwise={"cflags": ["-mcmodel=medany"]},
            )
        ]
    return []


def _hardening_off(cpu: str | None) -> list[Entry]:
    """grub_CHECK_STACK_PROTECTOR (off in the kernel), arm's strict alignment, and no build-id (a link probe upstream)."""
    steps = [probe("stack_protector", [(["-fstack-protector"], {"cflags": ["-fno-stack-protector"]})], code=SSP_CODE)]
    if cpu == "arm":
        align = [["-mno-unaligned-access"], ["-Xclang", "-mstrict-align"], ["-mstrict-align"]]
        steps.append(probe("strict_align", [(c, {"cflags": c}) for c in align]))
    steps.append(literal(ldflags=["-Wl,--build-id=none"]))
    return steps


def _makefile_common_flags(name: str, cpu: str | None, emu: bool, new: bool, pci: list[str]) -> list[Entry]:
    """CFLAGS_PLATFORM and LDFLAGS_PLATFORM (conf/Makefile.common), not TARGET_* but per platform all the same."""
    cflags_platform, ldflags_platform = [], []
    if name == "sparc64_ieee1275":
        ldflags_platform.append("-Wl,-melf64_sparc")
    if cpu == "arm" and not emu:
        ldflags_platform.append("-Wl,--wrap=__clear_cache")
    if cpu == "arm64":
        cflags_platform.append("-mcmodel=large")
    if name == "powerpc_ieee1275":
        cflags_platform.append("-mcpu=powerpc")
    if new and name in pci:
        cflags_platform.append("-DGRUB_HAS_PCI")
    return [literal(cflags_platform=cflags_platform, ldflags_platform=ldflags_platform)]


def _config_h_symbols(cpu: str | None, emu: bool) -> list[Entry]:
    """The kernel arm of config.h: grub_ASM_USCORE and, on i386, the BSS start and end symbols.

    grub_CHECK_BSS_START_SYMBOL and grub_CHECK_END_SYMBOL are link probes
    upstream; GNU ld and lld define both for ELF.
    """
    steps = []
    if emu:
        steps.append(literal(subst={"HAVE_ASM_USCORE": "0"}))
    else:
        steps.append(
            probe(
                "asm_uscore",
                [([], {"subst": {"HAVE_ASM_USCORE": "0"}})],
                code=USCORE_CODE,
                otherwise={"subst": {"HAVE_ASM_USCORE": "1"}},
            )
        )
    if cpu == "i386" and not emu:
        steps.append(literal(subst={"BSS_START_SYMBOL": "__bss_start", "END_SYMBOL": "end"}))
    else:
        steps.append(literal(subst={"BSS_START_SYMBOL": "", "END_SYMBOL": ""}))
    return steps


def flag_steps(name: str, new: bool, pci: list[str]) -> list[Entry]:
    """configure.ac's target-compiler section for one platform, in its order.

    The order is the order of the response files the BUILD file writes, so the
    helpers are called in configure's sequence.  configure's link probes are
    literals here: what they test (the ELF emulation name, `-no-pie`,
    `--build-id=none`, the `__bss_start` and `end` symbols) holds for every ELF
    linker, and a link check under Bazel gets the toolchain's own
    `-lstdc++ -lm`, which a `-m32` probe cannot satisfy on a host without
    32-bit libraries.  `new` is "2.12 or later"; see main().
    """
    cpu, plat = split(name)
    tcpu = target_cpu(name)
    emu = plat == "emu"
    x86 = cpu in ("i386", "x86_64")
    mips = cpu == "mips"
    return (
        _base_flags(name, cpu, plat, tcpu, new)
        + _endianness_and_abi(tcpu, mips)
        + _compiler_identity()
        + _i386_tuning(cpu, plat, emu, new)
        + _mips_tuning(mips, new)
        + _calling_convention(x86, emu)
        + _assembler_and_relocations(cpu, x86, new)
        + _soft_float(cpu, emu, new)
        + _frames_and_unwinding(x86, new)
        + _link_format(name, cpu, x86, emu)
        + _arm_relocations(cpu)
        + _position_independence(cpu)
        + _code_model(cpu)
        + _hardening_off(cpu)
        + _makefile_common_flags(name, cpu, emu, new, pci)
        + _config_h_symbols(cpu, emu)
    )


# --- what the steps amount to ------------------------------------------------


def apply_steps(steps: list[Entry]) -> Flags:
    """The flags GCC and GNU ld end up with: literals plus each probe's expected candidate."""
    out: Flags = {
        "cflags": [],
        "ccasflags": [],
        "cppflags": [],
        "ldflags": [],
        "cflags_platform": [],
        "ldflags_platform": [],
        "subst": {},
    }

    def add(to: Flags) -> None:
        for k, v in to.items():
            if k == "subst":
                out["subst"].update(v)
            else:
                out[k] += v

    for step in steps:
        if "literal" in step:
            if step.get("when") != "clang":
                add(step["literal"])
        elif step["gcc"] is not None:
            add(step["candidates"][step["gcc"]]["to"])
        elif "otherwise" in step:
            add(step["otherwise"])
    return out


def steps_of(steps: list[Entry]) -> list[Entry]:
    """The steps as the BUILD file consumes them, in order, without the GCC expectation."""
    return [{k: v for k, v in s.items() if k != "gcc"} for s in steps]


def literal_flags(steps: list[Entry]) -> Flags:
    """The unconditional flags, which the response-file templates carry verbatim."""
    out: Flags = {"cflags": [], "ccasflags": [], "cppflags": [], "ldflags": []}
    for step in steps:
        if "literal" in step and "when" not in step:
            for k in out:
                out[k] += step["literal"].get(k, [])
    return out


# CPPFLAGS_GCRY_ASM: what configure's assembler probes find with GNU as.
GCRY_ASM_X86_64_EFI = [
    "-D__x86_64",
    "-DHAVE_CPU_ARCH_X86",
    "-D__PIC__=1",
    "-DHAVE_COMPATIBLE_GCC_AMD64_PLATFORM_AS",
    "-DHAVE_INTEL_SYNTAX_PLATFORM_AS",
    "-DHAVE_GCC_INLINE_ASM_SSSE3",
    "-DHAVE_GCC_INLINE_ASM_SHAEXT",
    "-DENABLE_SHAEXT_SUPPORT",
    "-DHAVE_GCC_INLINE_ASM_SSE41",
    "-DHAVE_GCC_INLINE_ASM_AVX",
    "-DHAVE_GCC_INLINE_ASM_AVX2",
    "-DHAVE_GCC_INLINE_ASM_AVX512",
    "-DHAVE_GCC_INLINE_ASM_BMI2",
]

# The efiemu runtime objects (configure.ac:1495-1509, grub-core/Makefile.am), where COND_ENABLE_EFIEMU holds.
EFIEMU = {
    "efiemu32.o": {
        "srcs": ["grub-core/efiemu/runtime/efiemu.c"],
        "include_dirs": ["grub-core/efiemu/runtime"],
        "cflags": ["-m32", "-nostdlib", "-static", "-O2"],
    },
    "efiemu64.o": {
        "srcs": ["grub-core/efiemu/runtime/efiemu.c", "grub-core/efiemu/runtime/efiemu.S"],
        "include_dirs": ["grub-core/efiemu/runtime"],
        "cflags": ["-m64", "-nostdlib", "-O2", "-mcmodel=large", "-mno-red-zone"],
        "ldflags": ["-m64", "-Wl,-melf_x86_64", "-nostdlib", "-static", "-Wl,-r"],
    },
}


def target_flags(name: str, new: bool, pci: list[str]) -> Entry:
    """Everything configure and conf/Makefile.common decide per platform."""
    cpu, plat = split(name)
    tcpu = target_cpu(name)
    emu = plat == "emu"
    steps = flag_steps(name, new, pci)
    got = apply_steps(steps)
    fmt = ""
    if "-m32" in got["cflags"]:
        fmt = "elf32"
    if "-m64" in got["cflags"]:
        fmt = "elf64"
    link_addr: dict[str, str] = {}
    if name == "mips_arc":
        link_addr = {"TARGET_LINK_ADDR": "0x88200000", "TARGET_DECOMPRESSOR_LINK_ADDR": "0x88100000"}
    if name == "mipsel_arc":
        link_addr = {"TARGET_LINK_ADDR": "0x80700000", "TARGET_DECOMPRESSOR_LINK_ADDR": "0x80600000"}
    if name in ("mips_qemu_mips", "mipsel_qemu_mips", "mips_loongson"):
        link_addr = {"TARGET_DECOMPRESSOR_LINK_ADDR": "0x80100000"}
    if name == "i386_qemu":
        link_addr["GRUB_BOOT_MACHINE_LINK_ADDR"] = "0xffe00"
    cpudir = "mips" if tcpu == "mipsel" else tcpu
    return {
        "target_cpu": tcpu,
        "platform": plat,
        "cpu_dir": None if emu else f"include/grub/{cpudir}",
        "machine_dir": None if emu else f"include/grub/{cpudir}/{plat}",
        "config_h": {"GRUB_TARGET_CPU": tcpu or "", "GRUB_PLATFORM": plat} | got["subst"],
        "target_cflags": got["cflags"],
        "target_cppflags": got["cppflags"],
        "target_ccasflags": got["ccasflags"],
        "target_ldflags": got["ldflags"],
        "literal_flags": literal_flags(steps),
        "steps": steps_of(steps),
        "nostdinc": not emu,
        "cflags_platform": got["cflags_platform"],
        "ldflags_platform": got["ldflags_platform"],
        "ldflags_oldmagic": "-Wl,-N",
        "img_ldflags": ["-Wl,-N"],
        "img_base_ldopt": "-Wl,-Ttext",
        "img_cflags": [],
        "module_format": fmt,
        "cppflags_gcry_asm": GCRY_ASM_X86_64_EFI if new and name == "x86_64_efi" else [],
        "link_addr": link_addr,
        "efiemu": EFIEMU if cpu == "i386" and plat not in ("efi", "emu") else None,
    }


# =============================================================================
# 3. DEF ENTRIES (Makefile.core.def and Makefile.gcry.def, per platform)
# =============================================================================


def expand(flags_of: Entry, text: str, new: bool) -> tuple[list[str], list[str]]:
    """Expand the $(...) of a def flag string into (flags, include_dirs).

    The variables are conf/Makefile.common's: the flag classes become the
    flags or include directories they stand for, warning options are dropped
    (the BUILD file compiles with `-w`), and the per-platform values come
    from `flags_of`.
    """
    flags: list[str] = []
    dirs: list[str] = []
    subst = {
        "$(TARGET_IMG_LDFLAGS)": " ".join(flags_of["img_ldflags"]),
        "$(TARGET_IMG_BASE_LDOPT)": flags_of["img_base_ldopt"],
        "$(TARGET_LINK_ADDR)": flags_of["link_addr"].get("TARGET_LINK_ADDR", ""),
        "$(TARGET_DECOMPRESSOR_LINK_ADDR)": flags_of["link_addr"].get("TARGET_DECOMPRESSOR_LINK_ADDR", ""),
        "$(GRUB_BOOT_MACHINE_LINK_ADDR)": flags_of["link_addr"].get("GRUB_BOOT_MACHINE_LINK_ADDR", ""),
        "$(CPPFLAGS_GCRY_ASM)": " ".join(flags_of["cppflags_gcry_asm"]),
    }
    for tok in text.split():
        if tok in ("$(CFLAGS_POSIX)", "$(CFLAGS_GCRY)"):
            flags.append("-fno-builtin")  # CFLAGS_GCRY = warnings + $(CFLAGS_POSIX)
        elif tok == "$(CFLAGS_GNULIB)":
            pass  # warnings only
        elif tok == "$(CPPFLAGS_POSIX)":
            dirs.append("grub-core/lib/posix_wrap")
        elif tok == "$(CPPFLAGS_GNULIB)":
            dirs.append("grub-core/lib/gnulib")
        elif tok == "$(CPPFLAGS_GCRY)":
            dirs += ["grub-core/lib/libgcrypt_wrap", "grub-core/lib/posix_wrap", "include/grub/gcrypt"]
            flags.append("-D_GCRYPT_IN_LIBGCRYPT=1")
            if new:
                flags.append("-D_GCRYPT_CONFIG_H_INCLUDED=1")
        elif tok == "$(SDL2_CFLAGS)":
            flags.append(tok)  # pkg-config output; emu only
        elif tok.startswith("-I$(srcdir)/"):
            dirs.append("grub-core/" + tok[len("-I$(srcdir)/") :].rstrip("/"))
        elif tok.startswith("-W") and not tok.startswith(("-Wl,", "-Wa,")):
            continue
        else:
            for k, v in subst.items():
                tok = tok.replace(k, v)
            if "$(" in tok:
                raise SystemExit(f"unexpanded {tok} in {text}")
            flags += tok.split()  # a variable may expand to several flags
    return flags, dirs


def kernel_headers(makefile_am: str, gentpl_name: str, flags_of: Entry, new: bool, pci: list[str]) -> list[str]:
    """KERNEL_HEADER_FILES of grub-core/Makefile.am for the platform, the automake conditionals evaluated."""
    cpu, plat = split(gentpl_name)
    true = {"COND_" + gentpl_name, "COND_emu" if plat == "emu" else "", "COND_" + (cpu or "")}
    if new and gentpl_name in pci:
        true.add("COND_HAVE_PCI")
    if flags_of["efiemu"]:
        true.add("COND_ENABLE_EFIEMU")
    hdrs: list[str] = []
    stack = [True]
    builddir = {
        "$(top_builddir)/include/grub/machine/": flags_of["machine_dir"],
        "$(top_builddir)/include/grub/cpu/": flags_of["cpu_dir"],
        "$(top_builddir)/": "",
    }
    for raw in makefile_am.splitlines():
        line = raw.strip()
        if line.startswith("if "):
            cond = line[3:].strip()
            stack.append(stack[-1] and ((cond.lstrip("!") in true) != cond.startswith("!")))
        elif line == "else":
            prev = stack.pop()
            stack.append(stack[-1] and not prev)
        elif line == "endif":
            stack.pop()
        elif line.startswith("KERNEL_HEADER_FILES +=") and stack[-1]:
            h = line.split("+=", 1)[1].strip().replace("$(top_srcdir)/", "")
            for prefix, directory in builddir.items():
                if h.startswith(prefix):
                    h = (directory + "/" if directory else "") + h[len(prefix) :]
                    break
            if h not in hdrs:
                hdrs.append(h)
    return hdrs


def entry(g: Gentpl, gentpl_name: str, flags_of: Entry, defn: Any, kind: str, new: bool) -> Entry:
    """One kernel/module/image/program def as the platform sees it."""
    srcs = g.values(defn, gentpl_name, "sources").split()
    e: Entry = {
        "srcs": ["grub-core/" + s for s in srcs if not s.endswith(".h")],
        "extra_inputs": ["grub-core/" + s for s in srcs if s.endswith(".h")],
        "nodist": g.values(defn, gentpl_name, "nodist_sources").split(),
        "depends": list(defn.find_all("depends")),
    }
    for field in ["cflags", "cppflags", "ldflags", "ccasflags"]:
        e[field], dirs = expand(flags_of, g.values(defn, gentpl_name, field), new)
        if field == "cppflags":
            e["include_dirs"] = dirs
        elif dirs:
            raise SystemExit(f"include directories in {field} of {gentpl_name}")
    if kind == "kernel":
        e["startup"] = ["grub-core/" + s for s in g.values(defn, gentpl_name, "startup").split()]
        e["stripflags"] = g.values(defn, gentpl_name, "stripflags").split()
        e["nostrip"] = g.tagged(defn, gentpl_name, "nostrip")
    if kind == "image":
        e["objcopyflags"] = g.values(defn, gentpl_name, "objcopyflags").split()
    if kind == "program":
        e["ldadd"] = g.values(defn, gentpl_name, "ldadd")
    cond = g.ns["platform_specific_values"](defn, gentpl_name, "_condition", "condition").split()
    if cond:
        e["condition"] = cond[0]
    return {k: v for k, v in e.items() if v not in ([], "", None)}


def headers_under(src: Path, directory: str | None) -> list[str]:
    """The headers below `directory`, repository-relative."""
    if not directory or not (src / directory).is_dir():
        return []
    return sorted(str(p.relative_to(src)) for p in (src / directory).rglob("*.h"))


def platform_data(g: Gentpl, src: Path, makefile_am: str, name: str, gentpl_name: str, new: bool) -> Entry:
    """Everything the module publishes for one platform (the fields common.bzl documents)."""
    pci = g.groups["pci"]
    flags_of = target_flags(name, new, pci)
    d: Entry = {"name": name, "gentpl_platform": gentpl_name, **flags_of}
    d["kernel_headers"] = kernel_headers(makefile_am, gentpl_name, flags_of, new, pci)
    d["cpu_hdrs"] = headers_under(src, flags_of["cpu_dir"])
    d["machine_hdrs"] = headers_under(src, flags_of["machine_dir"])
    for kind, key in [("kernel", "kernel"), ("module", "modules"), ("image", "images"), ("program", "programs")]:
        tab: dict[str, Entry] = {}
        for defn in g.defs.definitions.find_all(kind):
            if not g.enabled(defn, gentpl_name):
                continue
            e = entry(g, gentpl_name, flags_of, defn, kind, new)
            if e.get("srcs") or e.get("startup") or e.get("nodist") or kind == "kernel":
                tab[defn["name"]] = e
        d[key] = tab.get("kernel") if kind == "kernel" else dict(sorted(tab.items()))
    if gentpl_name == "i386_qemu" and d["kernel"]:
        # kern/vga_init.c includes ascii.h, which build-grub-gen-asciih makes
        # from unifont (grub-core/Makefile.am, COND_HAVE_FONT_SOURCE).
        d["kernel"]["nodist"] = d["kernel"].get("nodist", []) + ["ascii.h"]
    d["data"] = {
        defn["name"]: "grub-core/" + g.values(defn, gentpl_name, "sources").split()[0]
        for defn in g.defs.definitions.find_all("transform_data")
        if g.enabled(defn, gentpl_name) and g.values(defn, gentpl_name, "sources")
    }
    return d


# =============================================================================
# 4. OUTPUT (Starlark through buildifier)
# =============================================================================

# Fields whose string values are repository paths, emitted as Label()s.
LABEL_FIELDS = {"srcs", "startup", "extra_inputs", "kernel_headers", "cpu_hdrs", "machine_hdrs", "data"}

PLATFORM_HEADER = '''"""GRUB {ver} build data for the {name} firmware platform (see common.bzl).

Generated from grub-core/Makefile.core.def and Makefile.gcry.def as gentpl.py
expands them for `{gentpl}`, and from configure.ac's target-compiler section.
"""

'''

MODULES_HEADER = '''"""The GRUB {ver} boot modules whose def entry is the same on every platform that
builds them (see common.bzl).  The `<platform>.bzl` tables refer to these by
name and spell out only the entries that differ on that platform.
"""

'''

INDEX_HEADER = '''"""The firmware platforms GRUB {ver}'s gentpl.py knows (plus the little-endian
mips variants), the groups Makefile.core.def tags sources with, and the
per-platform data by name.
"""

'''


def emit(v: Any, indent: int = 0, label: bool = False) -> str:
    """A value as Starlark source; strings in label fields become Label()s."""
    pad = " " * indent
    if isinstance(v, dict):
        if not v:
            return "{}"
        items = [f'{pad}    "{k}": {emit(v[k], indent + 4, label or k in LABEL_FIELDS)},' for k in sorted(v)]
        return "{\n" + "\n".join(items) + "\n" + pad + "}"
    if isinstance(v, list):
        if not v:
            return "[]"
        return "[\n" + "\n".join(f"{pad}    {emit(x, indent + 4, label)}," for x in v) + "\n" + pad + "]"
    if v is None:
        return "None"
    if isinstance(v, bool):
        return "True" if v else "False"
    if isinstance(v, str):
        if label and v:
            return f'Label("//:{v}")'
        escaped = v.replace("\\", "\\\\").replace('"', '\\"').replace("\n", "\\n")
        return f'"{escaped}"'
    raise SystemExit(repr(v))


def write_starlark(path: Path, text: str, buildifier: str | None) -> None:
    """Writes `text` to `path`, formatted and lint-fixed by buildifier when available."""
    if buildifier:
        result = subprocess.run(
            [buildifier, "-type=bzl", "-lint=fix", "-warnings=all", f"-path={path.name}"],
            input=text,
            capture_output=True,
            text=True,
            check=True,
        )
        text = result.stdout
    path.write_text(text)


def shared_modules(datas: list[tuple[str, str, Entry]]) -> dict[str, Entry]:
    """The module entries that are the same on every platform that builds the module (modules.bzl)."""
    seen: dict[str, dict[str, Entry]] = {}
    for _, _, data in datas:
        for mod, module_entry in data["modules"].items():
            seen.setdefault(mod, {})[emit(module_entry)] = module_entry
    return {
        mod: next(iter(entries.values()))
        for mod, entries in seen.items()
        if len(entries) == 1 and sum(mod in data["modules"] for _, _, data in datas) > 1
    }


def platform_source(ver: str, name: str, gentpl_name: str, data: Entry, shared: dict[str, Entry]) -> str:
    """One `<platform>.bzl`: the dict, with the shared module entries referred to by name."""
    common = [mod for mod in data["modules"] if mod in shared]
    own = {mod: module_entry for mod, module_entry in data["modules"].items() if mod not in shared}
    parts = []
    if common:
        parts.append("{\n        name: MODULES[name]\n        for name in " + emit(common, 8) + "\n    }")
    if own or not common:
        parts.append(emit(own, 4))
    body = emit(dict(data, modules="@@MODULES@@")).replace('"@@MODULES@@"', " | ".join(parts))
    header = PLATFORM_HEADER.format(ver=ver, name=name, gentpl=gentpl_name)
    if common:
        header += 'load(":modules.bzl", "MODULES")\n\n'
    return header + f"{name.upper()} = {body}\n"


def index_source(ver: str, g: Gentpl, names: list[tuple[str, str]]) -> str:
    """platforms.bzl: the loads, PLATFORMS in gentpl's order, GROUPS and PLATFORM_DATA."""
    all_names = sorted(n for n, _ in names)
    text = INDEX_HEADER.format(ver=ver)
    text += "\n".join(f'load(":{n}.bzl", "{n.upper()}")' for n in all_names) + "\n\n"
    text += f"PLATFORMS = {emit([n for n, _ in names])}\n\nGROUPS = {emit(g.groups)}\n\n"
    text += "PLATFORM_DATA = {\n" + "\n".join(f'    "{n}": {n.upper()},' for n in all_names) + "\n}\n"
    return text


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("source_dir", type=Path, help="Path to the extracted GRUB source tree")
    args = parser.parse_args()
    src = args.source_dir.resolve()

    match = re.search(r"AC_INIT\(\[GRUB\],\[([^\]]+)\]", (src / "configure.ac").read_text())
    if not match:
        raise SystemExit("cannot read the version from configure.ac")
    ver = match.group(1)
    # The flag logic changed between 2.06 and 2.12 (configure.ac diff), which
    # the TARGET FLAGS stage keys on as `new`; a newer release needs that stage
    # reviewed against its configure.ac, not just regenerated.
    new = tuple(int(x) for x in ver.split(".")[:2]) >= (2, 12)

    out = Path(__file__).resolve().parent / ver / "overlay" / "platform"
    out.mkdir(parents=True, exist_ok=True)
    buildifier = shutil.which("buildifier")
    if not buildifier:
        print("warning: buildifier not found on PATH; writing unformatted output")

    g = Gentpl(src)
    makefile_am = (src / "grub-core" / "Makefile.am").read_text()
    names: list[tuple[str, str]] = []  # (platform, gentpl's name for its tables)
    for p in g.platforms:
        names.append((p, p))
        if p in MIPSEL_VARIANTS:
            names.append((MIPSEL_VARIANTS[p], p))
    datas = [(name, gentpl_name, platform_data(g, src, makefile_am, name, gentpl_name, new)) for name, gentpl_name in names]

    shared = shared_modules(datas)
    write_starlark(out / "modules.bzl", MODULES_HEADER.format(ver=ver) + f"MODULES = {emit(dict(sorted(shared.items())))}\n", buildifier)
    for name, gentpl_name, data in datas:
        write_starlark(out / f"{name}.bzl", platform_source(ver, name, gentpl_name, data, shared), buildifier)
    write_starlark(out / "platforms.bzl", index_source(ver, g, names), buildifier)
    print(f"wrote {out}: {len(names)} platforms")


if __name__ == "__main__":
    main()
