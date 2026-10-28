"""GRUB 2.14 build data for the powerpc_ieee1275 firmware platform (see common.bzl).

Generated from grub-core/Makefile.core.def and Makefile.gcry.def as gentpl.py
expands them for `powerpc_ieee1275`, and from configure.ac's target-compiler section.
"""

load(":modules.bzl", "MODULES")

POWERPC_IEEE1275 = {
    "cflags_platform": [
        "-mcpu=powerpc",
    ],
    "config_h": {
        "BSS_START_SYMBOL": "",
        "END_SYMBOL": "",
        "GRUB_PLATFORM": "ieee1275",
        "GRUB_TARGET_CPU": "powerpc",
        "HAVE_ASM_USCORE": "0",
    },
    "cppflags_gcry_asm": [],
    "cpu_dir": "include/grub/powerpc",
    "cpu_hdrs": [
        Label("//:include/grub/powerpc/ieee1275/ieee1275.h"),
        Label("//:include/grub/powerpc/ieee1275/platform_keystore.h"),
        Label("//:include/grub/powerpc/kernel.h"),
        Label("//:include/grub/powerpc/memory.h"),
        Label("//:include/grub/powerpc/relocator.h"),
        Label("//:include/grub/powerpc/setjmp.h"),
        Label("//:include/grub/powerpc/time.h"),
        Label("//:include/grub/powerpc/types.h"),
    ],
    "data": {
        "bootinfo.txt": Label("//:grub-core/boot/powerpc/bootinfo.txt.in"),
        "gdb_grub": Label("//:grub-core/gdb_grub.in"),
        "gdb_helper.py": Label("//:grub-core/gdb_helper.py.in"),
        "genmod.sh": Label("//:grub-core/genmod.sh.in"),
        "gensyminfo.sh": Label("//:grub-core/gensyminfo.sh.in"),
        "grub.chrp": Label("//:grub-core/boot/powerpc/grub.chrp.in"),
        "modinfo.sh": Label("//:grub-core/modinfo.sh.in"),
    },
    "efiemu": None,
    "gentpl_platform": "powerpc_ieee1275",
    "images": {},
    "img_base_ldopt": "-Wl,-Ttext",
    "img_cflags": [],
    "img_ldflags": [
        "-Wl,-N",
    ],
    "kernel": {
        "ldflags": [
            "-Wl,-Ttext,0x200000",
        ],
        "nodist": [
            "symlist.c",
        ],
        "nostrip": False,
        "srcs": [
            Label("//:grub-core/commands/extcmd.c"),
            Label("//:grub-core/disk/ieee1275/ofdisk.c"),
            Label("//:grub-core/kern/buffer.c"),
            Label("//:grub-core/kern/command.c"),
            Label("//:grub-core/kern/compiler-rt.c"),
            Label("//:grub-core/kern/corecmd.c"),
            Label("//:grub-core/kern/device.c"),
            Label("//:grub-core/kern/disk.c"),
            Label("//:grub-core/kern/dl.c"),
            Label("//:grub-core/kern/env.c"),
            Label("//:grub-core/kern/err.c"),
            Label("//:grub-core/kern/file.c"),
            Label("//:grub-core/kern/fs.c"),
            Label("//:grub-core/kern/generic/millisleep.c"),
            Label("//:grub-core/kern/ieee1275/cmain.c"),
            Label("//:grub-core/kern/ieee1275/ieee1275.c"),
            Label("//:grub-core/kern/ieee1275/init.c"),
            Label("//:grub-core/kern/ieee1275/mmap.c"),
            Label("//:grub-core/kern/ieee1275/openfw.c"),
            Label("//:grub-core/kern/list.c"),
            Label("//:grub-core/kern/lockdown.c"),
            Label("//:grub-core/kern/main.c"),
            Label("//:grub-core/kern/misc.c"),
            Label("//:grub-core/kern/mm.c"),
            Label("//:grub-core/kern/parser.c"),
            Label("//:grub-core/kern/partition.c"),
            Label("//:grub-core/kern/powerpc/cache.S"),
            Label("//:grub-core/kern/powerpc/compiler-rt.S"),
            Label("//:grub-core/kern/powerpc/dl.c"),
            Label("//:grub-core/kern/powerpc/ieee1275/ieee1275.c"),
            Label("//:grub-core/kern/powerpc/ieee1275/platform_keystore.c"),
            Label("//:grub-core/kern/rescue_parser.c"),
            Label("//:grub-core/kern/rescue_reader.c"),
            Label("//:grub-core/kern/term.c"),
            Label("//:grub-core/kern/time.c"),
            Label("//:grub-core/kern/verifiers.c"),
            Label("//:grub-core/lib/arg.c"),
            Label("//:grub-core/term/ieee1275/console.c"),
            Label("//:grub-core/term/terminfo.c"),
            Label("//:grub-core/term/tparm.c"),
        ],
        "startup": [
            Label("//:grub-core/kern/powerpc/ieee1275/startup.S"),
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
        Label("//:include/grub/key_protector.h"),
        Label("//:include/grub/stack_protector.h"),
        Label("//:include/grub/term.h"),
        Label("//:include/grub/time.h"),
        Label("//:include/grub/verify.h"),
        Label("//:include/grub/mm_private.h"),
        Label("//:include/grub/net.h"),
        Label("//:include/grub/memory.h"),
        Label("//:include/grub/ieee1275/ieee1275.h"),
        Label("//:include/grub/ieee1275/alloc.h"),
        Label("//:include/grub/terminfo.h"),
        Label("//:include/grub/extcmd.h"),
        Label("//:include/grub/lib/arg.h"),
        Label("//:include/grub/powerpc/ieee1275/ieee1275.h"),
        Label("//:include/grub/powerpc/ieee1275/platform_keystore.h"),
    ],
    "ldflags_oldmagic": "-Wl,-N",
    "ldflags_platform": [],
    "link_addr": {},
    "literal_flags": {
        "ccasflags": [
            "-m32",
            "-g",
        ],
        "cflags": [
            "-std=gnu99",
            "-fno-common",
            "-Os",
            "-m32",
            "-g",
        ],
        "cppflags": [
            "-DGRUB_MACHINE_IEEE1275=1",
            "-DGRUB_MACHINE=POWERPC_IEEE1275",
            "-m32",
        ],
        "ldflags": [
            "-m32",
            "-Wl,--build-id=none",
        ],
    },
    "machine_dir": "include/grub/powerpc/ieee1275",
    "machine_hdrs": [
        Label("//:include/grub/powerpc/ieee1275/ieee1275.h"),
        Label("//:include/grub/powerpc/ieee1275/platform_keystore.h"),
    ],
    "module_format": "elf32",
    "modules": {
        name: MODULES[name]
        for name in [
            "adler32",
            "affs",
            "afs",
            "afsplitter",
            "all_video",
            "appended_signature_test",
            "appendedsig",
            "archelp",
            "argon2",
            "argon2_test",
            "asn1",
            "asn1_test",
            "bfs",
            "bitmap",
            "bitmap_scale",
            "blocklist",
            "blsuki",
            "boottime",
            "bswap_test",
            "btrfs",
            "bufio",
            "cacheinfo",
            "cat",
            "cbfs",
            "cmosdump",
            "cmostest",
            "cmp",
            "cmp_test",
            "configfile",
            "cpio",
            "cpio_be",
            "crc64",
            "crypto_cipher_mode_test",
            "cryptodisk",
            "ctz_test",
            "date",
            "datehook",
            "disk",
            "diskfilter",
            "div",
            "div_test",
            "dm_nv",
            "dsa_sexp_test",
            "echo",
            "elf",
            "erofs",
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
            "gcry_aria",
            "gcry_blake2",
            "gcry_blowfish",
            "gcry_camellia",
            "gcry_cast5",
            "gcry_crc",
            "gcry_des",
            "gcry_dsa",
            "gcry_gost28147",
            "gcry_gostr3411_94",
            "gcry_idea",
            "gcry_kdf",
            "gcry_keccak",
            "gcry_md4",
            "gcry_md5",
            "gcry_rfc2268",
            "gcry_rijndael",
            "gcry_rmd160",
            "gcry_rsa",
            "gcry_salsa20",
            "gcry_seed",
            "gcry_serpent",
            "gcry_sha1",
            "gcry_sm3",
            "gcry_sm4",
            "gcry_stribog",
            "gcry_tiger",
            "gcry_twofish",
            "gcry_whirlpool",
            "geli",
            "gettext",
            "gfxmenu",
            "gfxterm",
            "gfxterm_background",
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
            "key_protector",
            "keystatus",
            "ldm",
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
            "memtools",
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
            "ofnet",
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
            "plainmount",
            "png",
            "priority_queue",
            "probe",
            "procfs",
            "progress",
            "pubkey",
            "raid5rec",
            "raid6rec",
            "read",
            "regexp",
            "reiserfs",
            "romfs",
            "rsa_sexp_test",
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
            "suspend",
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
            "tpm2_key_protector",
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
            "zstdio",
        ]
    } | {
        "boot": {
            "srcs": [
                Label("//:grub-core/commands/boot.c"),
            ],
        },
        "crypto": {
            "srcs": [
                Label("//:grub-core/lib/crypto.c"),
                Label("//:grub-core/lib/hwfeatures-gcry.c"),
            ],
        },
        "datetime": {
            "srcs": [
                Label("//:grub-core/lib/cmos_datetime.c"),
                Label("//:grub-core/lib/datetime.c"),
                Label("//:grub-core/lib/ieee1275/cmos.c"),
                Label("//:grub-core/lib/ieee1275/datetime.c"),
            ],
        },
        "escc": {
            "srcs": [
                Label("//:grub-core/term/ieee1275/escc.c"),
            ],
        },
        "gcry_hwfeatures": {
            "cflags": [
                "-fno-builtin",
            ],
            "cppflags": [
                "-D_GCRYPT_IN_LIBGCRYPT=1",
                "-D_GCRYPT_CONFIG_H_INCLUDED=1",
            ],
            "include_dirs": [
                "grub-core/lib/libgcrypt_wrap",
                "grub-core/lib/posix_wrap",
                "include/grub/gcrypt",
            ],
            "srcs": [
                Label("//:grub-core/lib/libgcrypt-grub/src/hwfeatures.c"),
            ],
        },
        "gcry_sha256": {
            "cflags": [
                "-fno-builtin",
            ],
            "cppflags": [
                "-D_GCRYPT_IN_LIBGCRYPT=1",
                "-D_GCRYPT_CONFIG_H_INCLUDED=1",
                "-DUSE_SHA256",
            ],
            "include_dirs": [
                "grub-core/lib/libgcrypt_wrap",
                "grub-core/lib/posix_wrap",
                "include/grub/gcrypt",
            ],
            "srcs": [
                Label("//:grub-core/lib/libgcrypt-grub/cipher/sha256.c"),
            ],
        },
        "gcry_sha512": {
            "cflags": [
                "-fno-builtin",
            ],
            "cppflags": [
                "-D_GCRYPT_IN_LIBGCRYPT=1",
                "-D_GCRYPT_CONFIG_H_INCLUDED=1",
                "-DUSE_SHA512",
            ],
            "include_dirs": [
                "grub-core/lib/libgcrypt_wrap",
                "grub-core/lib/posix_wrap",
                "include/grub/gcrypt",
            ],
            "srcs": [
                Label("//:grub-core/lib/libgcrypt-grub/cipher/hash-common.c"),
                Label("//:grub-core/lib/libgcrypt-grub/cipher/sha512.c"),
            ],
        },
        "halt": {
            "srcs": [
                Label("//:grub-core/commands/halt.c"),
                Label("//:grub-core/lib/ieee1275/halt.c"),
            ],
        },
        "ieee1275_fb": {
            "srcs": [
                Label("//:grub-core/video/ieee1275.c"),
            ],
        },
        "linux": {
            "srcs": [
                Label("//:grub-core/lib/cmdline.c"),
                Label("//:grub-core/loader/linux.c"),
                Label("//:grub-core/loader/powerpc/ieee1275/linux.c"),
            ],
        },
        "reboot": {
            "srcs": [
                Label("//:grub-core/commands/reboot.c"),
                Label("//:grub-core/lib/ieee1275/reboot.c"),
            ],
        },
        "relocator": {
            "srcs": [
                Label("//:grub-core/lib/ieee1275/relocator.c"),
                Label("//:grub-core/lib/powerpc/relocator.c"),
                Label("//:grub-core/lib/powerpc/relocator_asm.S"),
                Label("//:grub-core/lib/relocator.c"),
            ],
        },
        "serial": {
            "srcs": [
                Label("//:grub-core/term/ieee1275/serial.c"),
                Label("//:grub-core/term/serial.c"),
            ],
        },
        "tpm": {
            "srcs": [
                Label("//:grub-core/commands/ieee1275/ibmvtpm.c"),
                Label("//:grub-core/commands/tpm.c"),
            ],
        },
        "tss2": {
            "include_dirs": [
                "grub-core/lib/tss2",
            ],
            "srcs": [
                Label("//:grub-core/lib/ieee1275/tcg2.c"),
                Label("//:grub-core/lib/tss2/buffer.c"),
                Label("//:grub-core/lib/tss2/tpm2_cmd.c"),
                Label("//:grub-core/lib/tss2/tss2.c"),
                Label("//:grub-core/lib/tss2/tss2_mu.c"),
            ],
        },
    },
    "name": "powerpc_ieee1275",
    "nostdinc": True,
    "platform": "ieee1275",
    "programs": {},
    "steps": [
        {
            "literal": {
                "cflags": [
                    "-std=gnu99",
                    "-fno-common",
                    "-Os",
                ],
                "cppflags": [
                    "-DGRUB_MACHINE_IEEE1275=1",
                    "-DGRUB_MACHINE=POWERPC_IEEE1275",
                ],
            },
        },
        {
            "literal": {
                "ccasflags": [
                    "-m32",
                ],
                "cflags": [
                    "-m32",
                ],
                "cppflags": [
                    "-m32",
                ],
                "ldflags": [
                    "-m32",
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
                        "-fno-omit-frame-pointer",
                    ],
                    "to": {
                        "cflags": [
                            "-fno-omit-frame-pointer",
                        ],
                    },
                },
            ],
            "code": "int main (void) { return 0; }\n",
            "probe": "fno_omit_frame_pointer",
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
                "cflags_platform": [
                    "-mcpu=powerpc",
                ],
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
        "-m32",
        "-g",
        "-mbig-endian",
        "-msoft-float",
        "-fno-PIE",
        "-fno-pie",
    ],
    "target_cflags": [
        "-std=gnu99",
        "-fno-common",
        "-Os",
        "-m32",
        "-g",
        "-mbig-endian",
        "-freg-struct-return",
        "-msoft-float",
        "-fno-omit-frame-pointer",
        "-fno-dwarf2-cfi-asm",
        "-fno-asynchronous-unwind-tables",
        "-fno-unwind-tables",
        "-fno-ident",
        "-fno-PIE",
        "-fno-pie",
        "-fno-stack-protector",
    ],
    "target_cppflags": [
        "-DGRUB_MACHINE_IEEE1275=1",
        "-DGRUB_MACHINE=POWERPC_IEEE1275",
        "-m32",
        "-mbig-endian",
    ],
    "target_cpu": "powerpc",
    "target_ldflags": [
        "-m32",
        "-mbig-endian",
        "-no-pie",
        "-Wl,--build-id=none",
    ],
}
