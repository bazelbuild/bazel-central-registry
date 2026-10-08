"""Build data every GRUB 2.14 firmware platform shares, and the shape of the
per-platform dicts in `<platform>.bzl` (`I386_PC`, `ARM64_EFI`, ...; indexed
by name in platforms.bzl's PLATFORM_DATA).

Which platform a build is for is the consumer's to decide: the firmware is
not a `@platforms` constraint, and CPU alone does not tell i386's BIOS,
coreboot, multiboot, Open Firmware and Xen ports apart.

Per-platform fields:

- `gentpl_platform`: gentpl.py's name for the tables (`mipsel_arc` shares
  `mips_arc`'s); `target_cpu`, `platform`: configure's `$target_cpu` and
  `$platform`; `cpu_dir`, `machine_dir`, `cpu_hdrs`, `machine_hdrs`: what
  `include/grub/cpu` and `include/grub/machine` are linked to
  (AC_CONFIG_LINKS) and the headers under them.
- `config_h`: the substitutions of the kernel arm of config.h.in besides the
  package names, as GCC and GNU ld answer them; `//platform:<platform>_config_h`
  is the header with the toolchain's own answers.
- `target_cflags`, `target_cppflags` (the GRUB_MACHINE defines included),
  `target_ccasflags`, `target_ldflags`: TARGET_* as configure derives them
  for GCC and GNU ld, warning options left out.  `literal_flags` are the
  unconditional part and `steps` the probes configure makes for the rest,
  in order (candidate flags, the program compiled or linked, what each hit
  contributes); `//platform:<platform>/<kind>.rsp` are the lists the
  configured toolchain actually gets, as response files.  `nostdinc` says the
  compile also takes `-nostdinc -isystem $(cc -print-file-name=include)`.
- `cflags_platform`, `ldflags_platform`, `ldflags_oldmagic`, `img_*`,
  `module_format`, `cppflags_gcry_asm`, `link_addr`: the per-platform
  Makefile variables of conf/Makefile.common and configure.ac.
- `kernel`, `modules`, `images`, `programs`: the def entries enabled for the
  platform, flags expanded (`include_dirs` are repository-relative), sources
  as labels, generated sources by name under
  `nodist` (see COMMON["nodist"] and COMMON["recipes"]), the automake
  `condition` by name.  `//platform:<platform>/kernel`, `.../mod/<module>`
  and `.../image/<image>` compile them (an `_asm` library beside for `.S`
  sources); `//platform:<platform>_objects` names them all.
  A module whose entry is the same on every platform that builds it is
  written once, in modules.bzl (`MODULES`), and the platform table refers
  to it by name; the `modules` dict is complete either way.
- `kernel_headers`: KERNEL_HEADER_FILES (grub-core/Makefile.am).
- `data`: the `transform_data` templates installed with the platform.
- `efiemu`: the efiemu32.o/efiemu64.o recipe where COND_ENABLE_EFIEMU holds.

COMMON: CPPFLAGS_DEFAULT and the CFLAGS/LDFLAGS classes of
conf/Makefile.common, the list-marker macros, the strip lists of the kernel,
image and genmod.sh rules, and where the generated sources (`nodist`) come
from: labels for the ones this module builds, recipes for the ones a rule
set makes.  An entry whose `nodist` names a header only a rule set makes
(lzma_decompress's rs_decoder.h, the i386_qemu kernel's ascii.h from
unifont) gets no compile target here.
"""

COMMON = {
    "cflags_image": [
        "-fno-builtin",
    ],
    "cflags_kernel": [
        "-ffreestanding",
    ],
    "cflags_module": [
        "-ffreestanding",
    ],
    "cppflags_default_defines": [
        "HAVE_CONFIG_H",
        "_FILE_OFFSET_BITS=64",
    ],
    "cppflags_kernel": [
        "-DGRUB_KERNEL=1",
    ],
    "cppflags_marker": [
        "-Dgrub_fs_register=FS_LIST_MARKER",
        "-Dgrub_video_register=VIDEO_LIST_MARKER",
        "-Dgrub_partition_map_register=PARTMAP_LIST_MARKER",
        "-Dgrub_parttool_register=PARTTOOL_LIST_MARKER",
        "-Dgrub_term_register_input(...)=INPUT_TERMINAL_LIST_MARKER(__VA_ARGS__)",
        "-Dgrub_term_register_output(...)=OUTPUT_TERMINAL_LIST_MARKER(__VA_ARGS__)",
        "-Dgrub_register_command(...)=COMMAND_LIST_MARKER(__VA_ARGS__)",
        "-Dgrub_register_command_lockdown(...)=COMMAND_LOCKDOWN_LIST_MARKER(__VA_ARGS__)",
        "-Dgrub_register_extcmd(...)=EXTCOMMAND_LIST_MARKER(__VA_ARGS__)",
        "-Dgrub_register_extcmd_lockdown(...)=EXTCOMMAND_LOCKDOWN_LIST_MARKER(__VA_ARGS__)",
        "-Dgrub_register_command_p1(...)=P1COMMAND_LIST_MARKER(__VA_ARGS__)",
        "-Dgrub_fdtbus_register(...)=FDT_DRIVER_LIST_MARKER(__VA_ARGS__)",
    ],
    "genmod_keep_symbols": [
        "grub_mod_init",
        "grub_mod_fini",
        "_grub_mod_init",
        "_grub_mod_fini",
    ],
    "genmod_strip_sections": [
        ".note.GNU-stack",
        ".note.gnu.gold-version",
        ".note.gnu.property",
        ".gnu.build.attributes",
        ".llvm*",
        ".rel.gnu.build.attributes",
        ".rela.gnu.build.attributes",
        ".eh_frame",
        ".rela.eh_frame",
        ".rel.eh_frame",
        ".note",
        ".comment",
        ".ARM.exidx",
    ],
    "image_strip_sections": [
        ".note",
        ".comment",
        ".note.gnu.build-id",
        ".MIPS.abiflags",
        ".reginfo",
        ".rel.dyn",
        ".note.gnu.gold-version",
        ".note.gnu.property",
        ".ARM.exidx",
        ".interp",
    ],
    "include_dirs": [
        "grub-core",
        "include",
        "grub-core/lib/libgcrypt-grub/src",
    ],
    "ldflags_image": [
        "-nostdlib",
        "-Wl,-S",
    ],
    "ldflags_kernel": [
        "-nostdlib",
        "-Wl,--defsym=malloc=grub_malloc",
        "-Wl,--defsym=free=grub_free",
    ],
    "ldflags_module": [
        "-nostdlib",
        "-Wl,-r",
    ],
    "lists": [
        "command",
        "fdt",
        "fs",
        "partmap",
        "parttool",
        "terminal",
        "video",
    ],
    "nodist": {
        "grub_script.tab.c": "grub_script.tab.c",
        "grub_script.tab.h": "grub_script.tab.h",
        "grub_script.yy.c": "grub_script.yy.c",
        "grub_script.yy.h": "grub_script.yy.h",
        "trigtables.c": "gen/trigtables.c",
    },
    "recipes": {
        "ascii.h": {
            "inputs": ["<unifont.pcf.gz>"],
            "tool": "build-grub-gen-asciih",
        },
        "grub_emu_init.c": {
            "inputs": [
                "<module files>",
            ],
            "script": "grub-core/genemuinit.sh",
        },
        "kernel_syms.lst": {
            "cppflags": [
                "-DGRUB_SYMBOL_GENERATOR=1",
            ],
            "inputs": [
                "<kernel_headers>",
                "config.h",
            ],
        },
        "rs_decoder.h": {
            "cflags": [
                "-Os",
                "-S",
                "-DSTANDALONE",
                "-g0",
                "-mregparm=3",
                "-ffreestanding",
            ],
            "srcs": [
                Label("//:grub-core/lib/reed_solomon.c"),
            ],
        },
        "symlist.c": {
            "cppflags": [
                "-DGRUB_SYMBOL_GENERATOR=1",
            ],
            "inputs": [
                "config.h",
                "<kernel_headers>",
            ],
            "script": "grub-core/gensymlist.sh",
        },
    },
    "stripflags_kernel": [
        "-R",
        ".rel.dyn",
        "-R",
        ".reginfo",
        "-R",
        ".note",
        "-R",
        ".comment",
        "-R",
        ".drectve",
        "-R",
        ".note.gnu.gold-version",
        "-R",
        ".MIPS.abiflags",
        "-R",
        ".ARM.exidx",
    ],
    "tools": {
        "build-grub-module-verifier": Label("//:build-grub-module-verifier"),
        "config.h.in": Label("//:config.h.in"),
        "crypto.lst": Label("//:grub-core/lib/libgcrypt-grub/cipher/crypto.lst"),
        "genemuinit.sh": Label("//:grub-core/genemuinit.sh"),
        "genemuinitheader.sh": Label("//:grub-core/genemuinitheader.sh"),
        "genmod.sh": Label("//:grub-core/genmod.sh.in"),
        "genmoddep.awk": Label("//:grub-core/genmoddep.awk"),
        "gensyminfo.sh": Label("//:grub-core/gensyminfo.sh.in"),
        "gensymlist.sh": Label("//:grub-core/gensymlist.sh"),
    },
}
