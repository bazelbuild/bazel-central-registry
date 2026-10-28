"""GRUB 2.06 build data for the emu firmware platform (see common.bzl).

Generated from grub-core/Makefile.core.def and Makefile.gcry.def as gentpl.py
expands them for `emu`, and from configure.ac's target-compiler section.
"""

load(":modules.bzl", "MODULES")

EMU = {
    "cflags_platform": [],
    "config_h": {
        "BSS_START_SYMBOL": "",
        "END_SYMBOL": "",
        "GRUB_PLATFORM": "emu",
        "GRUB_TARGET_CPU": "",
        "HAVE_ASM_USCORE": "0",
    },
    "cppflags_gcry_asm": [],
    "cpu_dir": None,
    "cpu_hdrs": [],
    "data": {
        "gdb_grub": Label("//:grub-core/gdb_grub.in"),
        "genmod.sh": Label("//:grub-core/genmod.sh.in"),
        "gensyminfo.sh": Label("//:grub-core/gensyminfo.sh.in"),
        "gmodule.pl": Label("//:grub-core/gmodule.pl.in"),
        "modinfo.sh": Label("//:grub-core/modinfo.sh.in"),
    },
    "efiemu": None,
    "gentpl_platform": "emu",
    "images": {},
    "img_base_ldopt": "-Wl,-Ttext",
    "img_cflags": [],
    "img_ldflags": [
        "-Wl,-N",
    ],
    "kernel": {
        "include_dirs": [
            "grub-core/lib/gnulib",
        ],
        "ldflags": [
            "-Wl,-r,-d",
        ],
        "nostrip": True,
        "srcs": [
            Label("//:grub-core/disk/host.c"),
            Label("//:grub-core/kern/emu/cache_s.S"),
            Label("//:grub-core/kern/emu/hostdisk.c"),
            Label("//:grub-core/osdep/unix/hostdisk.c"),
            Label("//:grub-core/osdep/exec.c"),
            Label("//:grub-core/osdep/devmapper/hostdisk.c"),
            Label("//:grub-core/osdep/hostdisk.c"),
            Label("//:grub-core/kern/emu/hostfs.c"),
            Label("//:grub-core/kern/emu/main.c"),
            Label("//:grub-core/kern/emu/argp_common.c"),
            Label("//:grub-core/kern/emu/misc.c"),
            Label("//:grub-core/kern/emu/mm.c"),
            Label("//:grub-core/kern/emu/time.c"),
            Label("//:grub-core/kern/emu/cache.c"),
            Label("//:grub-core/osdep/emuconsole.c"),
            Label("//:grub-core/osdep/dl.c"),
            Label("//:grub-core/osdep/sleep.c"),
            Label("//:grub-core/osdep/init.c"),
            Label("//:grub-core/osdep/emunet.c"),
            Label("//:grub-core/osdep/cputime.c"),
            Label("//:grub-core/term/terminfo.c"),
            Label("//:grub-core/term/tparm.c"),
            Label("//:grub-core/commands/extcmd.c"),
            Label("//:grub-core/lib/arg.c"),
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
        Label("//:include/grub/compiler-rt-emu.h"),
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
        Label("//:include/grub/datetime.h"),
        Label("//:include/grub/emu/misc.h"),
        Label("//:include/grub/emu/net.h"),
        Label("//:include/grub/emu/hostdisk.h"),
        Label("//:include/grub/emu/hostfile.h"),
        Label("//:include/grub/extcmd.h"),
    ],
    "ldflags_oldmagic": "-Wl,-N",
    "ldflags_platform": [],
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
            "-DGRUB_MACHINE_EMU=1",
        ],
        "ldflags": [
            "-Wl,--build-id=none",
        ],
    },
    "machine_dir": None,
    "machine_hdrs": [],
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
            "legacy_password_test",
            "loadenv",
            "loopback",
            "ls",
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
                Label("//:grub-core/lib/datetime.c"),
            ],
        },
        "emunet": {
            "srcs": [
                Label("//:grub-core/net/drivers/emu/emunet.c"),
            ],
        },
        "emupci": {
            "condition": "COND_GRUB_EMU_PCI",
            "srcs": [
                Label("//:grub-core/bus/emu/pci.c"),
                Label("//:grub-core/commands/lspci.c"),
            ],
        },
        "halt": {
            "srcs": [
                Label("//:grub-core/lib/emu/halt.c"),
                Label("//:grub-core/commands/halt.c"),
            ],
        },
        "legacycfg": {
            "srcs": [
                Label("//:grub-core/lib/i386/pc/vesa_modes_table.c"),
                Label("//:grub-core/commands/legacycfg.c"),
                Label("//:grub-core/lib/legacy_parse.c"),
            ],
        },
        "reboot": {
            "srcs": [
                Label("//:grub-core/commands/reboot.c"),
            ],
        },
        "sdl": {
            "condition": "COND_GRUB_EMU_SDL",
            "srcs": [
                Label("//:grub-core/video/emu/sdl.c"),
            ],
        },
    },
    "name": "emu",
    "nostdinc": False,
    "platform": "emu",
    "programs": {
        "grub-emu": {
            "ldadd": "kernel.exec$(EXEEXT) $(MODULE_FILES) lib/gnulib/libgnu.a $(LIBINTL) $(LIBUTIL) $(LIBSDL) $(LIBUSB) $(LIBPCIACCESS) $(LIBDEVMAPPER) $(LIBZFS) $(LIBNVPAIR) $(LIBGEOM)",
            "nodist": [
                "grub_emu_init.c",
            ],
            "srcs": [
                Label("//:grub-core/kern/emu/full.c"),
            ],
        },
        "grub-emu-lite": {
            "ldadd": "kernel.exec$(EXEEXT) lib/gnulib/libgnu.a $(LIBINTL) $(LIBUTIL) $(LIBSDL) $(LIBUSB) $(LIBPCIACCESS) $(LIBDEVMAPPER) $(LIBZFS) $(LIBNVPAIR) $(LIBGEOM)",
            "nodist": [
                "symlist.c",
            ],
            "srcs": [
                Label("//:grub-core/kern/emu/lite.c"),
            ],
        },
    },
    "steps": [
        {
            "literal": {
                "cflags": [
                    "-std=gnu99",
                    "-Os",
                ],
                "cppflags": [
                    "-DGRUB_MACHINE_EMU=1",
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
            "literal": {
                "subst": {
                    "HAVE_ASM_USCORE": "0",
                },
            },
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
        "-fno-PIE",
        "-fno-pie",
    ],
    "target_cflags": [
        "-std=gnu99",
        "-Os",
        "-g",
        "-freg-struct-return",
        "-fno-dwarf2-cfi-asm",
        "-fno-asynchronous-unwind-tables",
        "-fno-unwind-tables",
        "-fno-ident",
        "-fno-PIE",
        "-fno-pie",
        "-fno-stack-protector",
    ],
    "target_cppflags": [
        "-DGRUB_MACHINE_EMU=1",
    ],
    "target_cpu": None,
    "target_ldflags": [
        "-no-pie",
        "-Wl,--build-id=none",
    ],
}
