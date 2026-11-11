"""GRUB 2.06 build data for the arm_efi firmware platform (see common.bzl).

Generated from grub-core/Makefile.core.def and Makefile.gcry.def as gentpl.py
expands them for `arm_efi`, and from configure.ac's target-compiler section.
"""

load(":modules.bzl", "MODULES")

ARM_EFI = {
    "cflags_platform": [],
    "config_h": {
        "BSS_START_SYMBOL": "",
        "END_SYMBOL": "",
        "GRUB_PLATFORM": "efi",
        "GRUB_TARGET_CPU": "arm",
        "HAVE_ASM_USCORE": "0",
    },
    "cppflags_gcry_asm": [],
    "cpu_dir": "include/grub/arm",
    "cpu_hdrs": [
        Label("//:include/grub/arm/coreboot/console.h"),
        Label("//:include/grub/arm/coreboot/kernel.h"),
        Label("//:include/grub/arm/cros_ec.h"),
        Label("//:include/grub/arm/efi/memory.h"),
        Label("//:include/grub/arm/linux.h"),
        Label("//:include/grub/arm/reloc.h"),
        Label("//:include/grub/arm/setjmp.h"),
        Label("//:include/grub/arm/startup.h"),
        Label("//:include/grub/arm/system.h"),
        Label("//:include/grub/arm/time.h"),
        Label("//:include/grub/arm/types.h"),
        Label("//:include/grub/arm/uboot/kernel.h"),
    ],
    "data": {
        "gdb_grub": Label("//:grub-core/gdb_grub.in"),
        "genmod.sh": Label("//:grub-core/genmod.sh.in"),
        "gensyminfo.sh": Label("//:grub-core/gensyminfo.sh.in"),
        "gmodule.pl": Label("//:grub-core/gmodule.pl.in"),
        "modinfo.sh": Label("//:grub-core/modinfo.sh.in"),
    },
    "efiemu": None,
    "gentpl_platform": "arm_efi",
    "images": {},
    "img_base_ldopt": "-Wl,-Ttext",
    "img_cflags": [],
    "img_ldflags": [
        "-Wl,-N",
    ],
    "kernel": {
        "ldflags": [
            "-Wl,-r,-d",
        ],
        "nodist": [
            "symlist.c",
        ],
        "nostrip": False,
        "srcs": [
            Label("//:grub-core/kern/arm/efi/init.c"),
            Label("//:grub-core/kern/efi/fdt.c"),
            Label("//:grub-core/kern/arm/dl.c"),
            Label("//:grub-core/kern/arm/dl_helper.c"),
            Label("//:grub-core/kern/arm/cache_armv6.S"),
            Label("//:grub-core/kern/arm/cache_armv7.S"),
            Label("//:grub-core/kern/arm/cache.c"),
            Label("//:grub-core/kern/arm/compiler-rt.S"),
            Label("//:grub-core/lib/division.c"),
            Label("//:grub-core/disk/efi/efidisk.c"),
            Label("//:grub-core/kern/efi/efi.c"),
            Label("//:grub-core/kern/efi/init.c"),
            Label("//:grub-core/kern/efi/mm.c"),
            Label("//:grub-core/term/efi/console.c"),
            Label("//:grub-core/kern/acpi.c"),
            Label("//:grub-core/kern/efi/acpi.c"),
            Label("//:grub-core/kern/efi/sb.c"),
            Label("//:grub-core/kern/lockdown.c"),
            Label("//:grub-core/kern/compiler-rt.c"),
            Label("//:grub-core/kern/mm.c"),
            Label("//:grub-core/kern/time.c"),
            Label("//:grub-core/kern/generic/millisleep.c"),
            Label("//:grub-core/kern/buffer.c"),
            Label("//:grub-core/kern/command.c"),
            Label("//:grub-core/kern/corecmd.c"),
            Label("//:grub-core/kern/device.c"),
            Label("//:grub-core/kern/disk.c"),
            Label("//:grub-core/kern/dl.c"),
            Label("//:grub-core/kern/env.c"),
            Label("//:grub-core/kern/err.c"),
            Label("//:grub-core/kern/file.c"),
            Label("//:grub-core/kern/fs.c"),
            Label("//:grub-core/kern/list.c"),
            Label("//:grub-core/kern/main.c"),
            Label("//:grub-core/kern/misc.c"),
            Label("//:grub-core/kern/parser.c"),
            Label("//:grub-core/kern/partition.c"),
            Label("//:grub-core/kern/rescue_parser.c"),
            Label("//:grub-core/kern/rescue_reader.c"),
            Label("//:grub-core/kern/term.c"),
            Label("//:grub-core/kern/verifiers.c"),
        ],
        "startup": [
            Label("//:grub-core/kern/arm/efi/startup.S"),
        ],
        "stripflags": [
            "--strip-unneeded",
            "-K",
            "start",
            "-R",
            ".note",
            "-R",
            ".comment",
            "-R",
            ".note.gnu.gold-version",
        ],
    },
    "kernel_headers": [
        Label("//:include/grub/cache.h"),
        Label("//:include/grub/command.h"),
        Label("//:include/grub/device.h"),
        Label("//:include/grub/disk.h"),
        Label("//:include/grub/dl.h"),
        Label("//:include/grub/efi/sb.h"),
        Label("//:include/grub/env.h"),
        Label("//:include/grub/env_private.h"),
        Label("//:include/grub/err.h"),
        Label("//:include/grub/file.h"),
        Label("//:include/grub/fs.h"),
        Label("//:include/grub/i18n.h"),
        Label("//:include/grub/kernel.h"),
        Label("//:include/grub/list.h"),
        Label("//:include/grub/lockdown.h"),
        Label("//:include/grub/misc.h"),
        Label("//:include/grub/compiler-rt.h"),
        Label("//:include/grub/mm.h"),
        Label("//:include/grub/parser.h"),
        Label("//:include/grub/partition.h"),
        Label("//:include/grub/stack_protector.h"),
        Label("//:include/grub/term.h"),
        Label("//:include/grub/time.h"),
        Label("//:include/grub/verify.h"),
        Label("//:include/grub/mm_private.h"),
        Label("//:include/grub/net.h"),
        Label("//:include/grub/memory.h"),
        Label("//:include/grub/efi/efi.h"),
        Label("//:include/grub/efi/disk.h"),
        Label("//:include/grub/arm/system.h"),
        Label("//:include/grub/acpi.h"),
    ],
    "ldflags_oldmagic": "-Wl,-N",
    "ldflags_platform": [
        "-Wl,--wrap=__clear_cache",
    ],
    "link_addr": {},
    "literal_flags": {
        "ccasflags": [
            "-g",
        ],
        "cflags": [
            "-std=gnu99",
            "-Os",
            "-g",
        ],
        "cppflags": [
            "-DGRUB_MACHINE_EFI=1",
            "-DGRUB_MACHINE=ARM_EFI",
        ],
        "ldflags": [
            "-Wl,--build-id=none",
        ],
    },
    "machine_dir": "include/grub/arm/efi",
    "machine_hdrs": [
        Label("//:include/grub/arm/efi/memory.h"),
    ],
    "module_format": "",
    "modules": {
        name: MODULES[name]
        for name in [
            "adler32",
            "affs",
            "afs",
            "afsplitter",
            "all_video",
            "archelp",
            "bfs",
            "bitmap",
            "bitmap_scale",
            "blocklist",
            "boottime",
            "bswap_test",
            "btrfs",
            "bufio",
            "cacheinfo",
            "cat",
            "cbfs",
            "cmdline_cat_test",
            "cmp",
            "cmp_test",
            "configfile",
            "cpio",
            "cpio_be",
            "crc64",
            "crypto",
            "cryptodisk",
            "ctz_test",
            "date",
            "datehook",
            "disk",
            "diskfilter",
            "div_test",
            "dm_nv",
            "echo",
            "efi_gop",
            "efifwsetup",
            "efinet",
            "elf",
            "eval",
            "exfat",
            "exfctest",
            "ext2",
            "extcmd",
            "f2fs",
            "fat",
            "file",
            "font",
            "fshelp",
            "functional_test",
            "gcry_arcfour",
            "gcry_blowfish",
            "gcry_camellia",
            "gcry_cast5",
            "gcry_crc",
            "gcry_des",
            "gcry_dsa",
            "gcry_idea",
            "gcry_md4",
            "gcry_md5",
            "gcry_rfc2268",
            "gcry_rijndael",
            "gcry_rmd160",
            "gcry_rsa",
            "gcry_seed",
            "gcry_serpent",
            "gcry_sha1",
            "gcry_sha256",
            "gcry_sha512",
            "gcry_tiger",
            "gcry_twofish",
            "gcry_whirlpool",
            "geli",
            "gettext",
            "gfxmenu",
            "gfxterm",
            "gfxterm_background",
            "gfxterm_menu",
            "gptsync",
            "gzio",
            "hashsum",
            "hello",
            "help",
            "hexdump",
            "hfs",
            "hfsplus",
            "hfspluscomp",
            "http",
            "iso9660",
            "jfs",
            "jpeg",
            "json",
            "keystatus",
            "ldm",
            "loadenv",
            "loopback",
            "ls",
            "lsacpi",
            "lsefi",
            "lsefimmap",
            "lsefisystab",
            "lsmmap",
            "lssal",
            "luks",
            "luks2",
            "lvm",
            "lzopio",
            "macbless",
            "macho",
            "mdraid09",
            "mdraid09_be",
            "mdraid1x",
            "memdisk",
            "memrw",
            "minicmd",
            "minix",
            "minix2",
            "minix2_be",
            "minix3",
            "minix3_be",
            "minix_be",
            "mpi",
            "msdospart",
            "mul_test",
            "net",
            "newc",
            "nilfs2",
            "normal",
            "ntfs",
            "ntfscomp",
            "odc",
            "offsetio",
            "part_acorn",
            "part_amiga",
            "part_apple",
            "part_bsd",
            "part_dfly",
            "part_dvh",
            "part_gpt",
            "part_msdos",
            "part_plan",
            "part_sun",
            "part_sunpc",
            "parttool",
            "password",
            "password_pbkdf2",
            "pbkdf2",
            "pbkdf2_test",
            "pgp",
            "png",
            "priority_queue",
            "probe",
            "procfs",
            "progress",
            "raid5rec",
            "raid6rec",
            "read",
            "regexp",
            "reiserfs",
            "romfs",
            "scsi",
            "search",
            "search_fs_file",
            "search_fs_uuid",
            "search_label",
            "setjmp",
            "setjmp_test",
            "sfs",
            "shift_test",
            "signature_test",
            "sleep",
            "sleep_test",
            "squash4",
            "strtoull_test",
            "syslinuxcfg",
            "tar",
            "terminal",
            "terminfo",
            "test",
            "test_blockarg",
            "testload",
            "testspeed",
            "tftp",
            "tga",
            "time",
            "tpm",
            "tr",
            "trig",
            "true",
            "udf",
            "ufs1",
            "ufs1_be",
            "ufs2",
            "video",
            "video_colors",
            "video_fb",
            "videoinfo",
            "videotest",
            "videotest_checksum",
            "xfs",
            "xnu_uuid",
            "xnu_uuid_test",
            "xzio",
            "zfs",
            "zfscrypt",
            "zfsinfo",
            "zstd",
        ]
    } | {
        "acpi": {
            "srcs": [
                Label("//:grub-core/commands/acpi.c"),
            ],
        },
        "boot": {
            "srcs": [
                Label("//:grub-core/commands/boot.c"),
            ],
        },
        "chain": {
            "srcs": [
                Label("//:grub-core/loader/efi/chainloader.c"),
            ],
        },
        "datetime": {
            "srcs": [
                Label("//:grub-core/lib/efi/datetime.c"),
                Label("//:grub-core/lib/datetime.c"),
            ],
        },
        "fdt": {
            "srcs": [
                Label("//:grub-core/loader/efi/fdt.c"),
                Label("//:grub-core/lib/fdt.c"),
            ],
        },
        "halt": {
            "srcs": [
                Label("//:grub-core/lib/efi/halt.c"),
                Label("//:grub-core/commands/halt.c"),
            ],
        },
        "linux": {
            "srcs": [
                Label("//:grub-core/loader/arm64/linux.c"),
                Label("//:grub-core/loader/linux.c"),
                Label("//:grub-core/lib/cmdline.c"),
            ],
        },
        "mmap": {
            "srcs": [
                Label("//:grub-core/mmap/efi/mmap.c"),
                Label("//:grub-core/mmap/mmap.c"),
            ],
        },
        "reboot": {
            "srcs": [
                Label("//:grub-core/commands/reboot.c"),
            ],
        },
        "serial": {
            "srcs": [
                Label("//:grub-core/term/efi/serial.c"),
                Label("//:grub-core/term/serial.c"),
            ],
        },
        "smbios": {
            "srcs": [
                Label("//:grub-core/commands/efi/smbios.c"),
                Label("//:grub-core/commands/smbios.c"),
            ],
        },
    },
    "name": "arm_efi",
    "nostdinc": True,
    "platform": "efi",
    "programs": {},
    "steps": [
        {
            "literal": {
                "cflags": [
                    "-std=gnu99",
                    "-Os",
                ],
                "cppflags": [
                    "-DGRUB_MACHINE_EFI=1",
                    "-DGRUB_MACHINE=ARM_EFI",
                ],
            },
        },
        {
            "literal": {
                "ccasflags": [
                    "-g",
                ],
                "cflags": [
                    "-g",
                ],
            },
        },
        {
            "candidates": [
                {
                    "flags": [],
                    "to": {},
                },
            ],
            "code": "#ifndef __clang__\n#error not clang\n#endif\nint main (void) { return 0; }\n",
            "probe": "clang",
        },
        {
            "candidates": [
                {
                    "flags": [
                        "-freg-struct-return",
                    ],
                    "to": {
                        "cflags": [
                            "-freg-struct-return",
                        ],
                    },
                },
            ],
            "code": "int main (void) { return 0; }\n",
            "probe": "freg_struct_return",
        },
        {
            "candidates": [
                {
                    "flags": [
                        "-msoft-float",
                    ],
                    "to": {
                        "ccasflags": [
                            "-msoft-float",
                        ],
                        "cflags": [
                            "-msoft-float",
                        ],
                    },
                },
            ],
            "code": "int main (void) { return 0; }\n",
            "probe": "soft_float",
        },
        {
            "candidates": [
                {
                    "flags": [
                        "-fno-dwarf2-cfi-asm",
                    ],
                    "to": {
                        "cflags": [
                            "-fno-dwarf2-cfi-asm",
                        ],
                    },
                },
            ],
            "code": "int main (void) { return 0; }\n",
            "probe": "fno_dwarf2_cfi_asm",
        },
        {
            "candidates": [
                {
                    "flags": [
                        "-mno-stack-arg-probe",
                    ],
                    "to": {
                        "cflags": [
                            "-mno-stack-arg-probe",
                        ],
                    },
                },
            ],
            "code": "int main (void) { return 0; }\n",
            "probe": "mno_stack_arg_probe",
        },
        {
            "candidates": [
                {
                    "flags": [
                        "-fno-asynchronous-unwind-tables",
                    ],
                    "to": {
                        "cflags": [
                            "-fno-asynchronous-unwind-tables",
                        ],
                    },
                },
            ],
            "code": "int main (void) { return 0; }\n",
            "probe": "fno_asynchronous_unwind_tables",
        },
        {
            "candidates": [
                {
                    "flags": [
                        "-fno-unwind-tables",
                    ],
                    "to": {
                        "cflags": [
                            "-fno-unwind-tables",
                        ],
                    },
                },
            ],
            "code": "int main (void) { return 0; }\n",
            "probe": "fno_unwind_tables",
        },
        {
            "candidates": [
                {
                    "flags": [
                        "-fno-ident",
                    ],
                    "to": {
                        "cflags": [
                            "-fno-ident",
                        ],
                    },
                },
            ],
            "code": "int main (void) { return 0; }\n",
            "probe": "fno_ident",
        },
        {
            "candidates": [
                {
                    "flags": [
                        "-mno-movt",
                    ],
                    "to": {
                        "cppflags": [
                            "-mno-movt",
                        ],
                    },
                },
                {
                    "flags": [
                        "-mllvm",
                        "-arm-use-movt=0",
                    ],
                    "to": {
                        "cppflags": [
                            "-mllvm",
                            "-arm-use-movt=0",
                        ],
                    },
                },
                {
                    "flags": [
                        "-mword-relocations",
                    ],
                    "to": {
                        "cppflags": [
                            "-mword-relocations",
                        ],
                    },
                },
            ],
            "code": "int main (void) { return 0; }\n",
            "probe": "mno_movt",
        },
        {
            "candidates": [
                {
                    "flags": [
                        "-mthumb-interwork",
                    ],
                    "to": {
                        "cflags": [
                            "-mthumb-interwork",
                        ],
                    },
                },
            ],
            "code": "int main (void) { return 0; }\n",
            "probe": "mthumb_interwork",
        },
        {
            "candidates": [
                {
                    "flags": [
                        "-Qn",
                        "-Qunused-arguments",
                    ],
                    "to": {
                        "cflags": [
                            "-Qn",
                            "-Qunused-arguments",
                        ],
                    },
                },
            ],
            "code": "int main (void) { return 0; }\n",
            "probe": "qn",
        },
        {
            "candidates": [
                {
                    "flags": [],
                    "to": {
                        "ccasflags": [
                            "-fno-PIE",
                            "-fno-pie",
                        ],
                        "cflags": [
                            "-fno-PIE",
                            "-fno-pie",
                        ],
                    },
                },
            ],
            "code": "#ifdef __PIE__\n#error PIE by default\n#endif\nint main (void) { return 0; }\n",
            "negate": True,
            "probe": "pie",
        },
        {
            "literal": {
                "ldflags": [
                    "-no-pie",
                ],
            },
            "when": "pie",
        },
        {
            "candidates": [
                {
                    "flags": [],
                    "to": {
                        "cflags": [
                            "-fno-PIC",
                        ],
                    },
                },
            ],
            "code": "#ifdef __PIC__\n#error PIC by default\n#endif\nint main (void) { return 0; }\n",
            "copts": [
                "-fno-PIE",
            ],
            "negate": True,
            "probe": "pic",
        },
        {
            "candidates": [
                {
                    "flags": [
                        "-fstack-protector",
                    ],
                    "to": {
                        "cflags": [
                            "-fno-stack-protector",
                        ],
                    },
                },
            ],
            "code": "char foo (void) { volatile char a[8]; a[3] = 1; return a[3]; }\n",
            "probe": "stack_protector",
        },
        {
            "candidates": [
                {
                    "flags": [
                        "-mno-unaligned-access",
                    ],
                    "to": {
                        "cflags": [
                            "-mno-unaligned-access",
                        ],
                    },
                },
                {
                    "flags": [
                        "-Xclang",
                        "-mstrict-align",
                    ],
                    "to": {
                        "cflags": [
                            "-Xclang",
                            "-mstrict-align",
                        ],
                    },
                },
                {
                    "flags": [
                        "-mstrict-align",
                    ],
                    "to": {
                        "cflags": [
                            "-mstrict-align",
                        ],
                    },
                },
            ],
            "code": "int main (void) { return 0; }\n",
            "probe": "strict_align",
        },
        {
            "literal": {
                "ldflags": [
                    "-Wl,--build-id=none",
                ],
            },
        },
        {
            "literal": {
                "cflags_platform": [],
                "ldflags_platform": [
                    "-Wl,--wrap=__clear_cache",
                ],
            },
        },
        {
            "candidates": [
                {
                    "flags": [],
                    "to": {
                        "subst": {
                            "HAVE_ASM_USCORE": "0",
                        },
                    },
                },
            ],
            "code": "#define GRUB_STR_(x) #x\n#define GRUB_STR(x) GRUB_STR_(x)\nint main (void) { _Static_assert (sizeof (GRUB_STR (__USER_LABEL_PREFIX__)) == 1, \"prefix\"); return 0; }\n",
            "otherwise": {
                "subst": {
                    "HAVE_ASM_USCORE": "1",
                },
            },
            "probe": "asm_uscore",
        },
        {
            "literal": {
                "subst": {
                    "BSS_START_SYMBOL": "",
                    "END_SYMBOL": "",
                },
            },
        },
    ],
    "target_ccasflags": [
        "-g",
        "-msoft-float",
        "-fno-PIE",
        "-fno-pie",
    ],
    "target_cflags": [
        "-std=gnu99",
        "-Os",
        "-g",
        "-freg-struct-return",
        "-msoft-float",
        "-fno-dwarf2-cfi-asm",
        "-fno-asynchronous-unwind-tables",
        "-fno-unwind-tables",
        "-fno-ident",
        "-mthumb-interwork",
        "-fno-PIE",
        "-fno-pie",
        "-fno-stack-protector",
        "-mno-unaligned-access",
    ],
    "target_cppflags": [
        "-DGRUB_MACHINE_EFI=1",
        "-DGRUB_MACHINE=ARM_EFI",
        "-mword-relocations",
    ],
    "target_cpu": "arm",
    "target_ldflags": [
        "-no-pie",
        "-Wl,--build-id=none",
    ],
}
