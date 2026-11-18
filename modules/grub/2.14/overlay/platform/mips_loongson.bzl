"""GRUB 2.14 build data for the mips_loongson firmware platform (see common.bzl).

Generated from grub-core/Makefile.core.def and Makefile.gcry.def as gentpl.py
expands them for `mips_loongson`, and from configure.ac's target-compiler section.
"""

load(":modules.bzl", "MODULES")

MIPS_LOONGSON = {
    "cflags_platform": [
        "-DGRUB_HAS_PCI",
    ],
    "config_h": {
        "BSS_START_SYMBOL": "",
        "END_SYMBOL": "",
        "GRUB_PLATFORM": "loongson",
        "GRUB_TARGET_CPU": "mipsel",
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
        "gdb_helper.py": Label("//:grub-core/gdb_helper.py.in"),
        "genmod.sh": Label("//:grub-core/genmod.sh.in"),
        "gensyminfo.sh": Label("//:grub-core/gensyminfo.sh.in"),
        "modinfo.sh": Label("//:grub-core/modinfo.sh.in"),
    },
    "efiemu": None,
    "gentpl_platform": "mips_loongson",
    "images": {
        "fwstart": {
            "ldflags": [
                "-Wl,-N,-S,-Ttext,0xbfc00000,-Bstatic",
            ],
            "objcopyflags": [
                "-O",
                "binary",
            ],
            "srcs": [
                Label("//:grub-core/boot/mips/loongson/fwstart.S"),
            ],
        },
        "fwstart_fuloong2f": {
            "ldflags": [
                "-Wl,-N,-S,-Ttext,0xbfc00000,-Bstatic",
            ],
            "objcopyflags": [
                "-O",
                "binary",
            ],
            "srcs": [
                Label("//:grub-core/boot/mips/loongson/fuloong2f.S"),
            ],
        },
        "none_decompress": {
            "cppflags": [
                "-DGRUB_EMBED_DECOMPRESSOR=1",
            ],
            "ldflags": [
                "-Wl,-Ttext,0x80100000",
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
                "-Wl,-Ttext,0x80100000",
            ],
            "objcopyflags": [
                "-O",
                "binary",
            ],
            "srcs": [
                Label("//:grub-core/boot/mips/startup_raw.S"),
                Label("//:grub-core/boot/decompressor/minilib.c"),
                Label("//:grub-core/boot/decompressor/xz.c"),
                Label("//:grub-core/kern/compiler-rt.c"),
                Label("//:grub-core/lib/xzembed/xz_dec_bcj.c"),
                Label("//:grub-core/lib/xzembed/xz_dec_lzma2.c"),
                Label("//:grub-core/lib/xzembed/xz_dec_stream.c"),
            ],
        },
    },
    "img_base_ldopt": "-Wl,-Ttext",
    "img_cflags": [],
    "img_ldflags": [
        "-Wl,-N",
    ],
    "kernel": {
        "ldflags": [
            "-Wl,-Ttext,0x80200000",
        ],
        "nodist": [
            "symlist.c",
        ],
        "nostrip": False,
        "srcs": [
            Label("//:grub-core/bus/bonito.c"),
            Label("//:grub-core/bus/cs5536.c"),
            Label("//:grub-core/bus/pci.c"),
            Label("//:grub-core/commands/boot.c"),
            Label("//:grub-core/commands/extcmd.c"),
            Label("//:grub-core/commands/keylayouts.c"),
            Label("//:grub-core/font/font.c"),
            Label("//:grub-core/font/font_cmd.c"),
            Label("//:grub-core/io/bufio.c"),
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
            Label("//:grub-core/kern/generic/rtc_get_time_ms.c"),
            Label("//:grub-core/kern/list.c"),
            Label("//:grub-core/kern/main.c"),
            Label("//:grub-core/kern/mips/cache.S"),
            Label("//:grub-core/kern/mips/dl.c"),
            Label("//:grub-core/kern/mips/init.c"),
            Label("//:grub-core/kern/mips/loongson/init.c"),
            Label("//:grub-core/kern/misc.c"),
            Label("//:grub-core/kern/mm.c"),
            Label("//:grub-core/kern/parser.c"),
            Label("//:grub-core/kern/partition.c"),
            Label("//:grub-core/kern/rescue_parser.c"),
            Label("//:grub-core/kern/rescue_reader.c"),
            Label("//:grub-core/kern/term.c"),
            Label("//:grub-core/kern/time.c"),
            Label("//:grub-core/kern/verifiers.c"),
            Label("//:grub-core/lib/arg.c"),
            Label("//:grub-core/term/at_keyboard.c"),
            Label("//:grub-core/term/gfxterm.c"),
            Label("//:grub-core/term/ns8250.c"),
            Label("//:grub-core/term/ps2.c"),
            Label("//:grub-core/term/serial.c"),
            Label("//:grub-core/term/terminfo.c"),
            Label("//:grub-core/term/tparm.c"),
            Label("//:grub-core/video/fb/fbblit.c"),
            Label("//:grub-core/video/fb/fbfill.c"),
            Label("//:grub-core/video/fb/fbutil.c"),
            Label("//:grub-core/video/fb/video_fb.c"),
            Label("//:grub-core/video/radeon_fuloong2e.c"),
            Label("//:grub-core/video/radeon_yeeloong3a.c"),
            Label("//:grub-core/video/sis315pro.c"),
            Label("//:grub-core/video/sm712.c"),
            Label("//:grub-core/video/video.c"),
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
        Label("//:include/grub/key_protector.h"),
        Label("//:include/grub/stack_protector.h"),
        Label("//:include/grub/term.h"),
        Label("//:include/grub/time.h"),
        Label("//:include/grub/verify.h"),
        Label("//:include/grub/mm_private.h"),
        Label("//:include/grub/net.h"),
        Label("//:include/grub/memory.h"),
        Label("//:include/grub/mips/kernel.h"),
        Label("//:include/grub/keyboard_layouts.h"),
        Label("//:include/grub/mips/loongson/kernel.h"),
        Label("//:include/grub/mips/loongson/time.h"),
        Label("//:include/grub/video.h"),
        Label("//:include/grub/video_fb.h"),
        Label("//:include/grub/gfxterm.h"),
        Label("//:include/grub/font.h"),
        Label("//:include/grub/bufio.h"),
        Label("//:include/grub/pci.h"),
        Label("//:include/grub/cs5536.h"),
        Label("//:include/grub/mips/loongson/pci.h"),
        Label("//:include/grub/serial.h"),
        Label("//:include/grub/loader.h"),
        Label("//:include/grub/terminfo.h"),
        Label("//:include/grub/extcmd.h"),
        Label("//:include/grub/lib/arg.h"),
    ],
    "ldflags_oldmagic": "-Wl,-N",
    "ldflags_platform": [],
    "link_addr": {
        "TARGET_DECOMPRESSOR_LINK_ADDR": "0x80100000",
    },
    "literal_flags": {
        "ccasflags": [
            "-g",
        ],
        "cflags": [
            "-std=gnu99",
            "-fno-common",
            "-Os",
            "-g",
        ],
        "cppflags": [
            "-DGRUB_CPU_MIPSEL=1",
            "-DGRUB_MACHINE_MIPS_LOONGSON=1",
            "-DGRUB_MACHINE=MIPS_LOONGSON",
        ],
        "ldflags": [
            "-Wl,--build-id=none",
        ],
    },
    "machine_dir": "include/grub/mips/loongson",
    "machine_hdrs": [
        Label("//:include/grub/mips/loongson/at_keyboard.h"),
        Label("//:include/grub/mips/loongson/cmos.h"),
        Label("//:include/grub/mips/loongson/ec.h"),
        Label("//:include/grub/mips/loongson/kernel.h"),
        Label("//:include/grub/mips/loongson/memory.h"),
        Label("//:include/grub/mips/loongson/pci.h"),
        Label("//:include/grub/mips/loongson/serial.h"),
        Label("//:include/grub/mips/loongson/time.h"),
    ],
    "module_format": "",
    "modules": {
        name: MODULES[name]
        for name in [
            "adler32",
            "affs",
            "afs",
            "afsplitter",
            "ahci",
            "all_video",
            "archelp",
            "argon2",
            "argon2_test",
            "asn1",
            "asn1_test",
            "ata",
            "bfs",
            "bitmap",
            "bitmap_scale",
            "blocklist",
            "boottime",
            "bswap_test",
            "btrfs",
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
            "gfxterm_background",
            "gptsync",
            "gzio",
            "hashsum",
            "hdparm",
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
            "lspci",
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
            "multiboot2",
            "nativedisk",
            "net",
            "newc",
            "nilfs2",
            "normal",
            "ntfs",
            "ntfscomp",
            "odc",
            "offsetio",
            "ohci",
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
            "pata",
            "pbkdf2",
            "pbkdf2_test",
            "pcidump",
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
            "setpci",
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
            "uhci",
            "usb",
            "usb_keyboard",
            "usbms",
            "usbserial_common",
            "usbserial_ftdi",
            "usbserial_pl2303",
            "usbserial_usbdebug",
            "usbtest",
            "video_colors",
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
            ],
        },
        "ehci": {
            "srcs": [
                Label("//:grub-core/bus/usb/ehci-pci.c"),
                Label("//:grub-core/bus/usb/ehci.c"),
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
            ],
        },
        "linux": {
            "srcs": [
                Label("//:grub-core/lib/cmdline.c"),
                Label("//:grub-core/loader/linux.c"),
                Label("//:grub-core/loader/mips/linux.c"),
            ],
        },
        "lsspd": {
            "srcs": [
                Label("//:grub-core/commands/mips/loongson/lsspd.c"),
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
                Label("//:grub-core/commands/reboot.c"),
                Label("//:grub-core/lib/mips/loongson/reboot.c"),
            ],
        },
        "relocator": {
            "srcs": [
                Label("//:grub-core/lib/mips/relocator.c"),
                Label("//:grub-core/lib/mips/relocator_asm.S"),
                Label("//:grub-core/lib/relocator.c"),
            ],
        },
    },
    "name": "mips_loongson",
    "nostdinc": True,
    "platform": "loongson",
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
                    "-DGRUB_CPU_MIPSEL=1",
                    "-DGRUB_MACHINE_MIPS_LOONGSON=1",
                    "-DGRUB_MACHINE=MIPS_LOONGSON",
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
                        "-EL",
                    ],
                    "to": {
                        "ccasflags": [
                            "-EL",
                        ],
                        "cflags": [
                            "-EL",
                        ],
                        "cppflags": [
                            "-EL",
                        ],
                        "ldflags": [
                            "-EL",
                        ],
                    },
                },
            ],
            "code": "int main (void) { return 0; }\n",
            "probe": "little_endian",
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
                        "-mno-gpopt",
                    ],
                    "to": {
                        "cflags": [
                            "-mno-gpopt",
                        ],
                    },
                },
            ],
            "code": "int main (void) { return 0; }\n",
            "probe": "mno_gpopt",
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
                "cflags_platform": [
                    "-DGRUB_HAS_PCI",
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
        "-g",
        "-EL",
        "-mabi=32",
        "-msoft-float",
        "-fno-PIE",
        "-fno-pie",
    ],
    "target_cflags": [
        "-std=gnu99",
        "-fno-common",
        "-Os",
        "-g",
        "-EL",
        "-mabi=32",
        "-mflush-func=grub_red_herring",
        "-mno-gpopt",
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
        "-DGRUB_CPU_MIPSEL=1",
        "-DGRUB_MACHINE_MIPS_LOONGSON=1",
        "-DGRUB_MACHINE=MIPS_LOONGSON",
        "-EL",
    ],
    "target_cpu": "mipsel",
    "target_ldflags": [
        "-EL",
        "-no-pie",
        "-Wl,--build-id=none",
    ],
}
