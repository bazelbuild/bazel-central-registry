"""GRUB 2.06 build data for the mips_arc firmware platform (see common.bzl).

Generated from grub-core/Makefile.core.def and Makefile.gcry.def as gentpl.py
expands them for `mips_arc`, and from configure.ac's target-compiler section.
"""

load(":modules.bzl", "MODULES")

MIPS_ARC = {
    "cflags_platform": [],
    "config_h": {
        "BSS_START_SYMBOL": "",
        "END_SYMBOL": "",
        "GRUB_PLATFORM": "arc",
        "GRUB_TARGET_CPU": "mips",
        "HAVE_ASM_USCORE": "0",
    },
    "cppflags_gcry_asm": [],
    "cpu_dir": "include/grub/mips",
    "cpu_hdrs": [
        Label("//:include/grub/mips/arc/kernel.h"),
        Label("//:include/grub/mips/arc/memory.h"),
        Label("//:include/grub/mips/arc/time.h"),
        Label("//:include/grub/mips/asm.h"),
        Label("//:include/grub/mips/at_keyboard.h"),
        Label("//:include/grub/mips/cmos.h"),
        Label("//:include/grub/mips/io.h"),
        Label("//:include/grub/mips/kernel.h"),
        Label("//:include/grub/mips/loongson.h"),
        Label("//:include/grub/mips/loongson/at_keyboard.h"),
        Label("//:include/grub/mips/loongson/cmos.h"),
        Label("//:include/grub/mips/loongson/ec.h"),
        Label("//:include/grub/mips/loongson/kernel.h"),
        Label("//:include/grub/mips/loongson/memory.h"),
        Label("//:include/grub/mips/loongson/pci.h"),
        Label("//:include/grub/mips/loongson/serial.h"),
        Label("//:include/grub/mips/loongson/time.h"),
        Label("//:include/grub/mips/memory.h"),
        Label("//:include/grub/mips/mips.h"),
        Label("//:include/grub/mips/multiboot.h"),
        Label("//:include/grub/mips/pci.h"),
        Label("//:include/grub/mips/qemu_mips/at_keyboard.h"),
        Label("//:include/grub/mips/qemu_mips/cmos.h"),
        Label("//:include/grub/mips/qemu_mips/console.h"),
        Label("//:include/grub/mips/qemu_mips/kernel.h"),
        Label("//:include/grub/mips/qemu_mips/loader.h"),
        Label("//:include/grub/mips/qemu_mips/memory.h"),
        Label("//:include/grub/mips/qemu_mips/serial.h"),
        Label("//:include/grub/mips/qemu_mips/time.h"),
        Label("//:include/grub/mips/relocator.h"),
        Label("//:include/grub/mips/setjmp.h"),
        Label("//:include/grub/mips/time.h"),
        Label("//:include/grub/mips/types.h"),
    ],
    "data": {
        "gdb_grub": Label("//:grub-core/gdb_grub.in"),
        "genmod.sh": Label("//:grub-core/genmod.sh.in"),
        "gensyminfo.sh": Label("//:grub-core/gensyminfo.sh.in"),
        "gmodule.pl": Label("//:grub-core/gmodule.pl.in"),
        "modinfo.sh": Label("//:grub-core/modinfo.sh.in"),
    },
    "efiemu": None,
    "gentpl_platform": "mips_arc",
    "images": {
        "none_decompress": {
            "cppflags": [
                "-DGRUB_EMBED_DECOMPRESSOR=1",
            ],
            "ldflags": [
                "-Wl,-Ttext,0x88100000",
            ],
            "objcopyflags": [
                "-O",
                "binary",
            ],
            "srcs": [
                Label("//:grub-core/boot/mips/startup_raw.S"),
                Label("//:grub-core/boot/decompressor/none.c"),
            ],
        },
        "xz_decompress": {
            "cppflags": [
                "-DGRUB_EMBED_DECOMPRESSOR=1",
            ],
            "include_dirs": [
                "grub-core/lib/posix_wrap",
                "grub-core/lib/xzembed",
            ],
            "ldflags": [
                "-Wl,-Ttext,0x88100000",
            ],
            "objcopyflags": [
                "-O",
                "binary",
            ],
            "srcs": [
                Label("//:grub-core/boot/mips/startup_raw.S"),
                Label("//:grub-core/boot/decompressor/minilib.c"),
                Label("//:grub-core/boot/decompressor/xz.c"),
                Label("//:grub-core/lib/xzembed/xz_dec_bcj.c"),
                Label("//:grub-core/lib/xzembed/xz_dec_lzma2.c"),
                Label("//:grub-core/lib/xzembed/xz_dec_stream.c"),
                Label("//:grub-core/kern/compiler-rt.c"),
            ],
        },
    },
    "img_base_ldopt": "-Wl,-Ttext",
    "img_cflags": [],
    "img_ldflags": [
        "-Wl,-N",
    ],
    "kernel": {
        "cppflags": [
            "-DGRUB_DECOMPRESSOR_LINK_ADDR=0x88100000",
        ],
        "ldflags": [
            "-Wl,-Ttext,0x88200000",
        ],
        "nodist": [
            "symlist.c",
        ],
        "nostrip": False,
        "srcs": [
            Label("//:grub-core/kern/mips/arc/init.c"),
            Label("//:grub-core/term/arc/console.c"),
            Label("//:grub-core/disk/arc/arcdisk.c"),
            Label("//:grub-core/kern/generic/rtc_get_time_ms.c"),
            Label("//:grub-core/kern/mips/cache.S"),
            Label("//:grub-core/kern/mips/dl.c"),
            Label("//:grub-core/kern/mips/init.c"),
            Label("//:grub-core/term/terminfo.c"),
            Label("//:grub-core/term/tparm.c"),
            Label("//:grub-core/commands/extcmd.c"),
            Label("//:grub-core/lib/arg.c"),
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
            Label("//:grub-core/kern/mips/startup.S"),
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
        Label("//:include/grub/mips/kernel.h"),
        Label("//:include/grub/extcmd.h"),
        Label("//:include/grub/arc/arc.h"),
        Label("//:include/grub/terminfo.h"),
    ],
    "ldflags_oldmagic": "-Wl,-N",
    "ldflags_platform": [],
    "link_addr": {
        "TARGET_DECOMPRESSOR_LINK_ADDR": "0x88100000",
        "TARGET_LINK_ADDR": "0x88200000",
    },
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
            "-DGRUB_CPU_MIPS=1",
            "-DGRUB_MACHINE_ARC=1",
            "-DGRUB_MACHINE=MIPS_ARC",
        ],
        "ldflags": [
            "-Wl,--build-id=none",
        ],
    },
    "machine_dir": "include/grub/mips/arc",
    "machine_hdrs": [
        Label("//:include/grub/mips/arc/kernel.h"),
        Label("//:include/grub/mips/arc/memory.h"),
        Label("//:include/grub/mips/arc/time.h"),
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
            "div",
            "div_test",
            "dm_nv",
            "echo",
            "elf",
            "eval",
            "exfat",
            "exfctest",
            "ext2",
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
            "lsdev",
            "lsmmap",
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
            "multiboot2",
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
            "test",
            "test_blockarg",
            "testload",
            "testspeed",
            "tftp",
            "tga",
            "time",
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
        "boot": {
            "srcs": [
                Label("//:grub-core/commands/boot.c"),
            ],
        },
        "datetime": {
            "srcs": [
                Label("//:grub-core/lib/arc/datetime.c"),
                Label("//:grub-core/lib/datetime.c"),
            ],
        },
        "halt": {
            "srcs": [
                Label("//:grub-core/commands/halt.c"),
            ],
        },
        "linux": {
            "srcs": [
                Label("//:grub-core/loader/mips/linux.c"),
                Label("//:grub-core/loader/linux.c"),
                Label("//:grub-core/lib/cmdline.c"),
            ],
        },
        "mmap": {
            "srcs": [
                Label("//:grub-core/mmap/mips/uppermem.c"),
                Label("//:grub-core/mmap/mmap.c"),
            ],
        },
        "reboot": {
            "srcs": [
                Label("//:grub-core/lib/mips/arc/reboot.c"),
                Label("//:grub-core/commands/reboot.c"),
            ],
        },
        "relocator": {
            "srcs": [
                Label("//:grub-core/lib/mips/relocator_asm.S"),
                Label("//:grub-core/lib/mips/relocator.c"),
                Label("//:grub-core/lib/relocator.c"),
            ],
        },
        "serial": {
            "srcs": [
                Label("//:grub-core/term/arc/serial.c"),
                Label("//:grub-core/term/serial.c"),
            ],
        },
    },
    "name": "mips_arc",
    "nostdinc": True,
    "platform": "arc",
    "programs": {},
    "steps": [
        {
            "literal": {
                "cflags": [
                    "-std=gnu99",
                    "-Os",
                ],
                "cppflags": [
                    "-DGRUB_CPU_MIPS=1",
                    "-DGRUB_MACHINE_ARC=1",
                    "-DGRUB_MACHINE=MIPS_ARC",
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
                    "flags": [
                        "-EB",
                    ],
                    "to": {
                        "ccasflags": [
                            "-EB",
                        ],
                        "cflags": [
                            "-EB",
                        ],
                        "cppflags": [
                            "-EB",
                        ],
                        "ldflags": [
                            "-EB",
                        ],
                    },
                },
                {
                    "flags": [
                        "-mbig-endian",
                    ],
                    "to": {
                        "ccasflags": [
                            "-mbig-endian",
                        ],
                        "cflags": [
                            "-mbig-endian",
                        ],
                        "cppflags": [
                            "-mbig-endian",
                        ],
                        "ldflags": [
                            "-mbig-endian",
                        ],
                    },
                },
            ],
            "code": "int main (void) { return 0; }\n",
            "probe": "big_endian",
        },
        {
            "candidates": [
                {
                    "flags": [],
                    "to": {},
                },
                {
                    "flags": [
                        "-mabi=32",
                    ],
                    "to": {
                        "ccasflags": [
                            "-mabi=32",
                        ],
                        "cflags": [
                            "-mabi=32",
                        ],
                    },
                },
            ],
            "code": "#if !defined(_ABIO32) || !defined(_MIPS_SIM) || (_MIPS_SIM != _ABIO32)\n#error not o32 ABI\n#endif\nint main (void) { return 0; }\n",
            "probe": "mips_o32_abi",
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
                        "-mflush-func=grub_red_herring",
                    ],
                    "to": {
                        "cflags": [
                            "-mflush-func=grub_red_herring",
                        ],
                    },
                },
            ],
            "code": "int main (void) { return 0; }\n",
            "probe": "mflush_func",
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
            "literal": {
                "cflags": [
                    "-fPIC",
                ],
            },
            "when": "clang",
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
            "literal": {
                "ldflags": [
                    "-Wl,--build-id=none",
                ],
            },
        },
        {
            "literal": {
                "cflags_platform": [],
                "ldflags_platform": [],
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
        "-EB",
        "-mabi=32",
        "-msoft-float",
        "-fno-PIE",
        "-fno-pie",
    ],
    "target_cflags": [
        "-std=gnu99",
        "-Os",
        "-g",
        "-EB",
        "-mabi=32",
        "-mflush-func=grub_red_herring",
        "-freg-struct-return",
        "-msoft-float",
        "-fno-dwarf2-cfi-asm",
        "-fno-asynchronous-unwind-tables",
        "-fno-unwind-tables",
        "-fno-ident",
        "-fno-PIE",
        "-fno-pie",
        "-fno-stack-protector",
    ],
    "target_cppflags": [
        "-DGRUB_CPU_MIPS=1",
        "-DGRUB_MACHINE_ARC=1",
        "-DGRUB_MACHINE=MIPS_ARC",
        "-EB",
    ],
    "target_cpu": "mips",
    "target_ldflags": [
        "-EB",
        "-no-pie",
        "-Wl,--build-id=none",
    ],
}
