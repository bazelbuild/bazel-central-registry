"""GRUB 2.14 build data for the i386_xen firmware platform (see common.bzl).

Generated from grub-core/Makefile.core.def and Makefile.gcry.def as gentpl.py
expands them for `i386_xen`, and from configure.ac's target-compiler section.
"""

load(":modules.bzl", "MODULES")

I386_XEN = {
    "cflags_platform": [],
    "config_h": {
        "BSS_START_SYMBOL": "__bss_start",
        "END_SYMBOL": "end",
        "GRUB_PLATFORM": "xen",
        "GRUB_TARGET_CPU": "i386",
        "HAVE_ASM_USCORE": "0",
    },
    "cppflags_gcry_asm": [],
    "cpu_dir": "include/grub/i386",
    "cpu_hdrs": [
        Label("//:include/grub/i386/at_keyboard.h"),
        Label("//:include/grub/i386/bsd.h"),
        Label("//:include/grub/i386/cmos.h"),
        Label("//:include/grub/i386/coreboot/boot.h"),
        Label("//:include/grub/i386/coreboot/console.h"),
        Label("//:include/grub/i386/coreboot/kernel.h"),
        Label("//:include/grub/i386/coreboot/memory.h"),
        Label("//:include/grub/i386/coreboot/serial.h"),
        Label("//:include/grub/i386/coreboot/time.h"),
        Label("//:include/grub/i386/cpuid.h"),
        Label("//:include/grub/i386/efi/kernel.h"),
        Label("//:include/grub/i386/efi/memory.h"),
        Label("//:include/grub/i386/efi/serial.h"),
        Label("//:include/grub/i386/efiemu.h"),
        Label("//:include/grub/i386/floppy.h"),
        Label("//:include/grub/i386/freebsd_linker.h"),
        Label("//:include/grub/i386/freebsd_reboot.h"),
        Label("//:include/grub/i386/gdb.h"),
        Label("//:include/grub/i386/ieee1275/ieee1275.h"),
        Label("//:include/grub/i386/ieee1275/kernel.h"),
        Label("//:include/grub/i386/ieee1275/memory.h"),
        Label("//:include/grub/i386/ieee1275/serial.h"),
        Label("//:include/grub/i386/io.h"),
        Label("//:include/grub/i386/linux.h"),
        Label("//:include/grub/i386/macho.h"),
        Label("//:include/grub/i386/memory.h"),
        Label("//:include/grub/i386/memory_raw.h"),
        Label("//:include/grub/i386/msr.h"),
        Label("//:include/grub/i386/multiboot.h"),
        Label("//:include/grub/i386/multiboot/boot.h"),
        Label("//:include/grub/i386/multiboot/console.h"),
        Label("//:include/grub/i386/multiboot/kernel.h"),
        Label("//:include/grub/i386/multiboot/memory.h"),
        Label("//:include/grub/i386/multiboot/serial.h"),
        Label("//:include/grub/i386/multiboot/time.h"),
        Label("//:include/grub/i386/netbsd_bootinfo.h"),
        Label("//:include/grub/i386/netbsd_reboot.h"),
        Label("//:include/grub/i386/openbsd_bootarg.h"),
        Label("//:include/grub/i386/openbsd_reboot.h"),
        Label("//:include/grub/i386/pc/apm.h"),
        Label("//:include/grub/i386/pc/biosdisk.h"),
        Label("//:include/grub/i386/pc/biosnum.h"),
        Label("//:include/grub/i386/pc/boot.h"),
        Label("//:include/grub/i386/pc/chainloader.h"),
        Label("//:include/grub/i386/pc/console.h"),
        Label("//:include/grub/i386/pc/int.h"),
        Label("//:include/grub/i386/pc/int_types.h"),
        Label("//:include/grub/i386/pc/kernel.h"),
        Label("//:include/grub/i386/pc/memory.h"),
        Label("//:include/grub/i386/pc/pxe.h"),
        Label("//:include/grub/i386/pc/time.h"),
        Label("//:include/grub/i386/pc/vbe.h"),
        Label("//:include/grub/i386/pc/vesa_modes_table.h"),
        Label("//:include/grub/i386/pci.h"),
        Label("//:include/grub/i386/pit.h"),
        Label("//:include/grub/i386/pmtimer.h"),
        Label("//:include/grub/i386/qemu/boot.h"),
        Label("//:include/grub/i386/qemu/console.h"),
        Label("//:include/grub/i386/qemu/kernel.h"),
        Label("//:include/grub/i386/qemu/memory.h"),
        Label("//:include/grub/i386/qemu/serial.h"),
        Label("//:include/grub/i386/qemu/time.h"),
        Label("//:include/grub/i386/reboot.h"),
        Label("//:include/grub/i386/relocator.h"),
        Label("//:include/grub/i386/relocator_private.h"),
        Label("//:include/grub/i386/setjmp.h"),
        Label("//:include/grub/i386/time.h"),
        Label("//:include/grub/i386/tsc.h"),
        Label("//:include/grub/i386/types.h"),
        Label("//:include/grub/i386/xen/hypercall.h"),
        Label("//:include/grub/i386/xen/kernel.h"),
        Label("//:include/grub/i386/xen/memory.h"),
        Label("//:include/grub/i386/xen_pvh/boot.h"),
        Label("//:include/grub/i386/xen_pvh/console.h"),
        Label("//:include/grub/i386/xen_pvh/int.h"),
        Label("//:include/grub/i386/xen_pvh/kernel.h"),
        Label("//:include/grub/i386/xen_pvh/memory.h"),
        Label("//:include/grub/i386/xen_pvh/time.h"),
        Label("//:include/grub/i386/xnu.h"),
    ],
    "data": {
        "gdb_grub": Label("//:grub-core/gdb_grub.in"),
        "gdb_helper.py": Label("//:grub-core/gdb_helper.py.in"),
        "genmod.sh": Label("//:grub-core/genmod.sh.in"),
        "gensyminfo.sh": Label("//:grub-core/gensyminfo.sh.in"),
        "modinfo.sh": Label("//:grub-core/modinfo.sh.in"),
    },
    "efiemu": {
        "efiemu32.o": {
            "cflags": [
                "-m32",
                "-nostdlib",
                "-static",
                "-O2",
            ],
            "include_dirs": [
                "grub-core/efiemu/runtime",
            ],
            "srcs": [
                Label("//:grub-core/efiemu/runtime/efiemu.c"),
            ],
        },
        "efiemu64.o": {
            "cflags": [
                "-m64",
                "-nostdlib",
                "-O2",
                "-mcmodel=large",
                "-mno-red-zone",
            ],
            "include_dirs": [
                "grub-core/efiemu/runtime",
            ],
            "ldflags": [
                "-m64",
                "-Wl,-melf_x86_64",
                "-nostdlib",
                "-static",
                "-Wl,-r",
            ],
            "srcs": [
                Label("//:grub-core/efiemu/runtime/efiemu.c"),
                Label("//:grub-core/efiemu/runtime/efiemu.S"),
            ],
        },
    },
    "gentpl_platform": "i386_xen",
    "images": {},
    "img_base_ldopt": "-Wl,-Ttext",
    "img_cflags": [],
    "img_ldflags": [
        "-Wl,-N",
    ],
    "kernel": {
        "ldflags": [
            "-Wl,-N",
            "-Wl,-Ttext,0",
        ],
        "nodist": [
            "symlist.c",
        ],
        "nostrip": False,
        "srcs": [
            Label("//:grub-core/commands/boot.c"),
            Label("//:grub-core/commands/extcmd.c"),
            Label("//:grub-core/disk/xen/xendisk.c"),
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
            Label("//:grub-core/kern/i386/dl.c"),
            Label("//:grub-core/kern/i386/tsc.c"),
            Label("//:grub-core/kern/i386/xen/hypercall.S"),
            Label("//:grub-core/kern/i386/xen/tsc.c"),
            Label("//:grub-core/kern/list.c"),
            Label("//:grub-core/kern/main.c"),
            Label("//:grub-core/kern/misc.c"),
            Label("//:grub-core/kern/mm.c"),
            Label("//:grub-core/kern/parser.c"),
            Label("//:grub-core/kern/partition.c"),
            Label("//:grub-core/kern/rescue_parser.c"),
            Label("//:grub-core/kern/rescue_reader.c"),
            Label("//:grub-core/kern/term.c"),
            Label("//:grub-core/kern/time.c"),
            Label("//:grub-core/kern/verifiers.c"),
            Label("//:grub-core/kern/xen/cmdline.c"),
            Label("//:grub-core/kern/xen/init.c"),
            Label("//:grub-core/lib/arg.c"),
            Label("//:grub-core/term/terminfo.c"),
            Label("//:grub-core/term/tparm.c"),
            Label("//:grub-core/term/xen/console.c"),
        ],
        "startup": [
            Label("//:grub-core/kern/i386/xen/startup.S"),
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
        Label("//:include/grub/i386/xen/kernel.h"),
        Label("//:include/grub/xen.h"),
        Label("//:include/grub/i386/xen/hypercall.h"),
        Label("//:include/grub/terminfo.h"),
        Label("//:include/grub/extcmd.h"),
        Label("//:include/grub/lib/arg.h"),
        Label("//:include/grub/loader.h"),
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
            "-march=i386",
            "-falign-functions=1",
            "-mno-mmx",
            "-mno-sse",
            "-mno-sse2",
            "-mno-sse3",
            "-mno-3dnow",
        ],
        "cppflags": [
            "-DGRUB_MACHINE_XEN=1",
            "-DGRUB_MACHINE=I386_XEN",
            "-m32",
        ],
        "ldflags": [
            "-m32",
            "-Wl,-melf_i386",
            "-Wl,--build-id=none",
        ],
    },
    "machine_dir": "include/grub/i386/xen",
    "machine_hdrs": [
        Label("//:include/grub/i386/xen/hypercall.h"),
        Label("//:include/grub/i386/xen/kernel.h"),
        Label("//:include/grub/i386/xen/memory.h"),
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
            "archelp",
            "argon2",
            "argon2_test",
            "asn1",
            "asn1_test",
            "backtrace",
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
            "cmp",
            "cmp_test",
            "configfile",
            "cpio",
            "cpio_be",
            "cpuid",
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
            "legacy_password_test",
            "loadenv",
            "loopback",
            "ls",
            "lsmmap",
            "lsxen",
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
                Label("//:grub-core/lib/datetime.c"),
                Label("//:grub-core/lib/xen/datetime.c"),
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
                Label("//:grub-core/lib/xen/halt.c"),
            ],
        },
        "legacycfg": {
            "srcs": [
                Label("//:grub-core/commands/legacycfg.c"),
                Label("//:grub-core/lib/i386/pc/vesa_modes_table.c"),
                Label("//:grub-core/lib/legacy_parse.c"),
            ],
        },
        "linux": {
            "srcs": [
                Label("//:grub-core/lib/cmdline.c"),
                Label("//:grub-core/loader/i386/xen.c"),
                Label("//:grub-core/loader/linux.c"),
            ],
        },
        "reboot": {
            "srcs": [
                Label("//:grub-core/commands/reboot.c"),
                Label("//:grub-core/lib/xen/reboot.c"),
            ],
        },
        "relocator": {
            "srcs": [
                Label("//:grub-core/lib/i386/relocator_asm.S"),
                Label("//:grub-core/lib/i386/relocator_common_c.c"),
                Label("//:grub-core/lib/i386/xen/relocator.S"),
                Label("//:grub-core/lib/relocator.c"),
                Label("//:grub-core/lib/xen/relocator.c"),
            ],
        },
    },
    "name": "i386_xen",
    "nostdinc": True,
    "platform": "xen",
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
                    "-DGRUB_MACHINE_XEN=1",
                    "-DGRUB_MACHINE=I386_XEN",
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
                    "flags": [],
                    "to": {},
                },
            ],
            "code": "#ifndef __clang__\n#error not clang\n#endif\nint main (void) { return 0; }\n",
            "probe": "clang",
        },
        {
            "literal": {
                "cflags": [
                    "-march=i386",
                ],
            },
        },
        {
            "literal": {
                "cflags": [
                    "-mrtd",
                    "-mregparm=3",
                ],
            },
            "when": "!clang",
        },
        {
            "literal": {
                "cflags": [
                    "-falign-functions=1",
                ],
            },
        },
        {
            "candidates": [
                {
                    "flags": [
                        "-falign-loops=1",
                    ],
                    "to": {
                        "cflags": [
                            "-falign-loops=1",
                        ],
                    },
                },
            ],
            "code": "int main (void) { return 0; }\n",
            "probe": "falign_loops",
        },
        {
            "candidates": [
                {
                    "flags": [
                        "-falign-jumps=1",
                    ],
                    "to": {
                        "cflags": [
                            "-falign-jumps=1",
                        ],
                    },
                },
            ],
            "code": "int main (void) { return 0; }\n",
            "probe": "falign_jumps",
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
            "literal": {
                "cflags": [
                    "-mno-mmx",
                    "-mno-sse",
                    "-mno-sse2",
                    "-mno-sse3",
                    "-mno-3dnow",
                ],
            },
        },
        {
            "candidates": [
                {
                    "flags": [
                        "-Wa,-mx86-used-note=no",
                    ],
                    "to": {
                        "ccasflags": [
                            "-Wa,-mx86-used-note=no",
                        ],
                        "cflags": [
                            "-Wa,-mx86-used-note=no",
                        ],
                    },
                },
            ],
            "code": "int main (void) { return 0; }\n",
            "probe": "mx86_used_note",
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
            "literal": {
                "ldflags": [
                    "-Wl,-melf_i386",
                ],
            },
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
                    "BSS_START_SYMBOL": "__bss_start",
                    "END_SYMBOL": "end",
                },
            },
        },
    ],
    "target_ccasflags": [
        "-m32",
        "-g",
        "-Wa,-mx86-used-note=no",
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
        "-march=i386",
        "-mrtd",
        "-mregparm=3",
        "-falign-functions=1",
        "-falign-loops=1",
        "-falign-jumps=1",
        "-freg-struct-return",
        "-mno-mmx",
        "-mno-sse",
        "-mno-sse2",
        "-mno-sse3",
        "-mno-3dnow",
        "-Wa,-mx86-used-note=no",
        "-msoft-float",
        "-fno-omit-frame-pointer",
        "-fno-dwarf2-cfi-asm",
        "-mno-stack-arg-probe",
        "-fno-asynchronous-unwind-tables",
        "-fno-unwind-tables",
        "-fno-ident",
        "-fno-PIE",
        "-fno-pie",
        "-fno-stack-protector",
    ],
    "target_cppflags": [
        "-DGRUB_MACHINE_XEN=1",
        "-DGRUB_MACHINE=I386_XEN",
        "-m32",
    ],
    "target_cpu": "i386",
    "target_ldflags": [
        "-m32",
        "-Wl,-melf_i386",
        "-no-pie",
        "-Wl,--build-id=none",
    ],
}
