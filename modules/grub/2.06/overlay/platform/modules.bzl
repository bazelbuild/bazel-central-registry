"""The GRUB 2.06 boot modules whose def entry is the same on every platform that
builds them (see common.bzl).  The `<platform>.bzl` tables refer to these by
name and spell out only the entries that differ on that platform.
"""

MODULES = {
    "adler32": {
        "srcs": [
            Label("//:grub-core/lib/adler32.c"),
        ],
    },
    "affs": {
        "srcs": [
            Label("//:grub-core/fs/affs.c"),
        ],
    },
    "afs": {
        "srcs": [
            Label("//:grub-core/fs/afs.c"),
        ],
    },
    "afsplitter": {
        "srcs": [
            Label("//:grub-core/disk/AFSplitter.c"),
        ],
    },
    "ahci": {
        "srcs": [
            Label("//:grub-core/disk/ahci.c"),
        ],
    },
    "all_video": {
        "srcs": [
            Label("//:grub-core/lib/fake_module.c"),
        ],
    },
    "aout": {
        "srcs": [
            Label("//:grub-core/loader/aout.c"),
        ],
    },
    "appleldr": {
        "srcs": [
            Label("//:grub-core/loader/efi/appleloader.c"),
        ],
    },
    "archelp": {
        "srcs": [
            Label("//:grub-core/fs/archelp.c"),
        ],
    },
    "at_keyboard": {
        "srcs": [
            Label("//:grub-core/term/at_keyboard.c"),
            Label("//:grub-core/term/ps2.c"),
        ],
    },
    "ata": {
        "srcs": [
            Label("//:grub-core/disk/ata.c"),
        ],
    },
    "backtrace": {
        "srcs": [
            Label("//:grub-core/lib/i386/backtrace.c"),
            Label("//:grub-core/lib/backtrace.c"),
        ],
    },
    "bfs": {
        "srcs": [
            Label("//:grub-core/fs/bfs.c"),
        ],
    },
    "bitmap": {
        "srcs": [
            Label("//:grub-core/video/bitmap.c"),
        ],
    },
    "bitmap_scale": {
        "srcs": [
            Label("//:grub-core/video/bitmap_scale.c"),
        ],
    },
    "blocklist": {
        "srcs": [
            Label("//:grub-core/commands/blocklist.c"),
        ],
    },
    "boottime": {
        "condition": "COND_ENABLE_BOOT_TIME_STATS",
        "srcs": [
            Label("//:grub-core/commands/boottime.c"),
        ],
    },
    "bsd": {
        "srcs": [
            Label("//:grub-core/loader/i386/bsd.c"),
            Label("//:grub-core/loader/i386/bsd32.c"),
            Label("//:grub-core/loader/i386/bsd64.c"),
        ],
    },
    "bswap_test": {
        "srcs": [
            Label("//:grub-core/tests/bswap_test.c"),
        ],
    },
    "btrfs": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-DMINILZO_HAVE_CONFIG_H",
        ],
        "include_dirs": [
            "grub-core/lib/posix_wrap",
            "grub-core/lib/minilzo",
            "grub-core/lib/zstd",
        ],
        "srcs": [
            Label("//:grub-core/fs/btrfs.c"),
            Label("//:grub-core/lib/crc.c"),
        ],
    },
    "bufio": {
        "srcs": [
            Label("//:grub-core/io/bufio.c"),
        ],
    },
    "cacheinfo": {
        "condition": "COND_ENABLE_CACHE_STATS",
        "srcs": [
            Label("//:grub-core/commands/cacheinfo.c"),
        ],
    },
    "cat": {
        "srcs": [
            Label("//:grub-core/commands/cat.c"),
        ],
    },
    "cbfs": {
        "srcs": [
            Label("//:grub-core/fs/cbfs.c"),
        ],
    },
    "cbls": {
        "srcs": [
            Label("//:grub-core/commands/i386/coreboot/cbls.c"),
        ],
    },
    "cbmemc": {
        "srcs": [
            Label("//:grub-core/term/i386/coreboot/cbmemc.c"),
        ],
    },
    "cbtable": {
        "srcs": [
            Label("//:grub-core/kern/i386/coreboot/cbtable.c"),
            Label("//:grub-core/kern/coreboot/cbtable.c"),
        ],
    },
    "cbtime": {
        "srcs": [
            Label("//:grub-core/commands/i386/coreboot/cb_timestamps.c"),
        ],
    },
    "cmdline_cat_test": {
        "srcs": [
            Label("//:grub-core/tests/cmdline_cat_test.c"),
        ],
    },
    "cmosdump": {
        "srcs": [
            Label("//:grub-core/commands/i386/cmosdump.c"),
        ],
    },
    "cmostest": {
        "srcs": [
            Label("//:grub-core/commands/i386/cmostest.c"),
        ],
    },
    "cmp": {
        "srcs": [
            Label("//:grub-core/commands/cmp.c"),
        ],
    },
    "cmp_test": {
        "srcs": [
            Label("//:grub-core/tests/cmp_test.c"),
        ],
    },
    "configfile": {
        "srcs": [
            Label("//:grub-core/commands/configfile.c"),
        ],
    },
    "cpio": {
        "srcs": [
            Label("//:grub-core/fs/cpio.c"),
        ],
    },
    "cpio_be": {
        "srcs": [
            Label("//:grub-core/fs/cpio_be.c"),
        ],
    },
    "cpuid": {
        "srcs": [
            Label("//:grub-core/commands/i386/cpuid.c"),
        ],
    },
    "crc64": {
        "srcs": [
            Label("//:grub-core/lib/crc64.c"),
        ],
    },
    "crypto": {
        "srcs": [
            Label("//:grub-core/lib/crypto.c"),
        ],
    },
    "cryptodisk": {
        "srcs": [
            Label("//:grub-core/disk/cryptodisk.c"),
        ],
    },
    "cs5536": {
        "srcs": [
            Label("//:grub-core/bus/cs5536.c"),
        ],
    },
    "ctz_test": {
        "srcs": [
            Label("//:grub-core/tests/ctz_test.c"),
        ],
    },
    "date": {
        "srcs": [
            Label("//:grub-core/commands/date.c"),
        ],
    },
    "datehook": {
        "srcs": [
            Label("//:grub-core/hook/datehook.c"),
        ],
    },
    "disk": {
        "srcs": [
            Label("//:grub-core/lib/disk.c"),
        ],
    },
    "diskfilter": {
        "srcs": [
            Label("//:grub-core/disk/diskfilter.c"),
        ],
    },
    "div": {
        "srcs": [
            Label("//:grub-core/lib/division.c"),
        ],
    },
    "div_test": {
        "srcs": [
            Label("//:grub-core/tests/div_test.c"),
        ],
    },
    "dm_nv": {
        "srcs": [
            Label("//:grub-core/disk/dmraid_nvidia.c"),
        ],
    },
    "echo": {
        "srcs": [
            Label("//:grub-core/commands/echo.c"),
        ],
    },
    "efi_gop": {
        "srcs": [
            Label("//:grub-core/video/efi_gop.c"),
        ],
    },
    "efi_uga": {
        "srcs": [
            Label("//:grub-core/video/efi_uga.c"),
        ],
    },
    "efifwsetup": {
        "srcs": [
            Label("//:grub-core/commands/efi/efifwsetup.c"),
        ],
    },
    "efinet": {
        "srcs": [
            Label("//:grub-core/net/drivers/efi/efinet.c"),
        ],
    },
    "elf": {
        "srcs": [
            Label("//:grub-core/kern/elf.c"),
        ],
    },
    "eval": {
        "srcs": [
            Label("//:grub-core/commands/eval.c"),
        ],
    },
    "exfat": {
        "srcs": [
            Label("//:grub-core/fs/exfat.c"),
        ],
    },
    "exfctest": {
        "srcs": [
            Label("//:grub-core/tests/example_functional_test.c"),
        ],
    },
    "ext2": {
        "srcs": [
            Label("//:grub-core/fs/ext2.c"),
        ],
    },
    "extcmd": {
        "srcs": [
            Label("//:grub-core/commands/extcmd.c"),
            Label("//:grub-core/lib/arg.c"),
        ],
    },
    "f2fs": {
        "srcs": [
            Label("//:grub-core/fs/f2fs.c"),
        ],
    },
    "fat": {
        "srcs": [
            Label("//:grub-core/fs/fat.c"),
        ],
    },
    "file": {
        "srcs": [
            Label("//:grub-core/commands/file.c"),
            Label("//:grub-core/commands/file32.c"),
            Label("//:grub-core/commands/file64.c"),
            Label("//:grub-core/loader/i386/xen_file.c"),
            Label("//:grub-core/loader/i386/xen_file32.c"),
            Label("//:grub-core/loader/i386/xen_file64.c"),
        ],
    },
    "fixvideo": {
        "srcs": [
            Label("//:grub-core/commands/efi/fixvideo.c"),
        ],
    },
    "font": {
        "srcs": [
            Label("//:grub-core/font/font.c"),
            Label("//:grub-core/font/font_cmd.c"),
        ],
    },
    "fshelp": {
        "srcs": [
            Label("//:grub-core/fs/fshelp.c"),
        ],
    },
    "functional_test": {
        "extra_inputs": [
            Label("//:grub-core/tests/checksums.h"),
        ],
        "srcs": [
            Label("//:grub-core/tests/lib/functional_test.c"),
            Label("//:grub-core/tests/lib/test.c"),
            Label("//:grub-core/tests/video_checksum.c"),
            Label("//:grub-core/tests/fake_input.c"),
            Label("//:grub-core/video/capture.c"),
        ],
    },
    "gcry_arcfour": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/arcfour.c"),
        ],
    },
    "gcry_blowfish": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/blowfish.c"),
        ],
    },
    "gcry_camellia": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/camellia-glue.c"),
            Label("//:grub-core/lib/libgcrypt-grub/cipher/camellia.c"),
        ],
    },
    "gcry_cast5": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/cast5.c"),
        ],
    },
    "gcry_crc": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/crc.c"),
        ],
    },
    "gcry_des": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/des.c"),
        ],
    },
    "gcry_dsa": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/dsa.c"),
        ],
    },
    "gcry_idea": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/idea.c"),
        ],
    },
    "gcry_md4": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/md4.c"),
        ],
    },
    "gcry_md5": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/md5.c"),
        ],
    },
    "gcry_rfc2268": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/rfc2268.c"),
        ],
    },
    "gcry_rijndael": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/rijndael.c"),
        ],
    },
    "gcry_rmd160": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/rmd160.c"),
        ],
    },
    "gcry_rsa": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/rsa.c"),
        ],
    },
    "gcry_seed": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/seed.c"),
        ],
    },
    "gcry_serpent": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/serpent.c"),
        ],
    },
    "gcry_sha1": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/sha1.c"),
        ],
    },
    "gcry_sha256": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
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
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/sha512.c"),
        ],
    },
    "gcry_tiger": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/tiger.c"),
        ],
    },
    "gcry_twofish": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/twofish.c"),
        ],
    },
    "gcry_whirlpool": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/cipher/whirlpool.c"),
        ],
    },
    "gdb": {
        "srcs": [
            Label("//:grub-core/gdb/i386/idt.c"),
            Label("//:grub-core/gdb/i386/machdep.S"),
            Label("//:grub-core/gdb/i386/signal.c"),
            Label("//:grub-core/gdb/cstub.c"),
            Label("//:grub-core/gdb/gdb.c"),
        ],
    },
    "geli": {
        "srcs": [
            Label("//:grub-core/disk/geli.c"),
        ],
    },
    "gettext": {
        "srcs": [
            Label("//:grub-core/gettext/gettext.c"),
        ],
    },
    "gfxmenu": {
        "srcs": [
            Label("//:grub-core/gfxmenu/gfxmenu.c"),
            Label("//:grub-core/gfxmenu/view.c"),
            Label("//:grub-core/gfxmenu/font.c"),
            Label("//:grub-core/gfxmenu/icon_manager.c"),
            Label("//:grub-core/gfxmenu/theme_loader.c"),
            Label("//:grub-core/gfxmenu/widget-box.c"),
            Label("//:grub-core/gfxmenu/gui_canvas.c"),
            Label("//:grub-core/gfxmenu/gui_circular_progress.c"),
            Label("//:grub-core/gfxmenu/gui_box.c"),
            Label("//:grub-core/gfxmenu/gui_label.c"),
            Label("//:grub-core/gfxmenu/gui_list.c"),
            Label("//:grub-core/gfxmenu/gui_image.c"),
            Label("//:grub-core/gfxmenu/gui_progress_bar.c"),
            Label("//:grub-core/gfxmenu/gui_util.c"),
            Label("//:grub-core/gfxmenu/gui_string_util.c"),
        ],
    },
    "gfxterm": {
        "srcs": [
            Label("//:grub-core/term/gfxterm.c"),
        ],
    },
    "gfxterm_background": {
        "srcs": [
            Label("//:grub-core/term/gfxterm_background.c"),
        ],
    },
    "gfxterm_menu": {
        "srcs": [
            Label("//:grub-core/tests/gfxterm_menu.c"),
        ],
    },
    "gptsync": {
        "srcs": [
            Label("//:grub-core/commands/gptsync.c"),
        ],
    },
    "gzio": {
        "srcs": [
            Label("//:grub-core/io/gzio.c"),
        ],
    },
    "hashsum": {
        "srcs": [
            Label("//:grub-core/commands/hashsum.c"),
        ],
    },
    "hdparm": {
        "srcs": [
            Label("//:grub-core/commands/hdparm.c"),
        ],
    },
    "hello": {
        "srcs": [
            Label("//:grub-core/hello/hello.c"),
        ],
    },
    "help": {
        "srcs": [
            Label("//:grub-core/commands/help.c"),
        ],
    },
    "hexdump": {
        "srcs": [
            Label("//:grub-core/commands/hexdump.c"),
            Label("//:grub-core/lib/hexdump.c"),
        ],
    },
    "hfs": {
        "srcs": [
            Label("//:grub-core/fs/hfs.c"),
        ],
    },
    "hfsplus": {
        "srcs": [
            Label("//:grub-core/fs/hfsplus.c"),
        ],
    },
    "hfspluscomp": {
        "srcs": [
            Label("//:grub-core/fs/hfspluscomp.c"),
        ],
    },
    "http": {
        "srcs": [
            Label("//:grub-core/net/http.c"),
        ],
    },
    "iorw": {
        "srcs": [
            Label("//:grub-core/commands/iorw.c"),
        ],
    },
    "iso9660": {
        "srcs": [
            Label("//:grub-core/fs/iso9660.c"),
        ],
    },
    "jfs": {
        "srcs": [
            Label("//:grub-core/fs/jfs.c"),
        ],
    },
    "jpeg": {
        "srcs": [
            Label("//:grub-core/video/readers/jpeg.c"),
        ],
    },
    "json": {
        "srcs": [
            Label("//:grub-core/lib/json/json.c"),
        ],
    },
    "keylayouts": {
        "srcs": [
            Label("//:grub-core/commands/keylayouts.c"),
        ],
    },
    "keystatus": {
        "srcs": [
            Label("//:grub-core/commands/keystatus.c"),
        ],
    },
    "ldm": {
        "srcs": [
            Label("//:grub-core/disk/ldm.c"),
        ],
    },
    "legacy_password_test": {
        "srcs": [
            Label("//:grub-core/tests/legacy_password_test.c"),
        ],
    },
    "linux16": {
        "srcs": [
            Label("//:grub-core/loader/i386/pc/linux.c"),
        ],
    },
    "loadbios": {
        "srcs": [
            Label("//:grub-core/commands/efi/loadbios.c"),
        ],
    },
    "loadenv": {
        "srcs": [
            Label("//:grub-core/commands/loadenv.c"),
            Label("//:grub-core/lib/envblk.c"),
        ],
    },
    "loopback": {
        "srcs": [
            Label("//:grub-core/disk/loopback.c"),
        ],
    },
    "ls": {
        "srcs": [
            Label("//:grub-core/commands/ls.c"),
        ],
    },
    "lsacpi": {
        "srcs": [
            Label("//:grub-core/commands/lsacpi.c"),
        ],
    },
    "lsdev": {
        "srcs": [
            Label("//:grub-core/commands/arc/lsdev.c"),
        ],
    },
    "lsefi": {
        "srcs": [
            Label("//:grub-core/commands/efi/lsefi.c"),
        ],
    },
    "lsefimmap": {
        "srcs": [
            Label("//:grub-core/commands/efi/lsefimmap.c"),
        ],
    },
    "lsefisystab": {
        "srcs": [
            Label("//:grub-core/commands/efi/lsefisystab.c"),
        ],
    },
    "lsmmap": {
        "srcs": [
            Label("//:grub-core/commands/lsmmap.c"),
        ],
    },
    "lspci": {
        "srcs": [
            Label("//:grub-core/commands/lspci.c"),
        ],
    },
    "lssal": {
        "srcs": [
            Label("//:grub-core/commands/efi/lssal.c"),
        ],
    },
    "lsxen": {
        "srcs": [
            Label("//:grub-core/commands/xen/lsxen.c"),
        ],
    },
    "luks": {
        "srcs": [
            Label("//:grub-core/disk/luks.c"),
        ],
    },
    "luks2": {
        "cflags": [
            "-fno-builtin",
        ],
        "include_dirs": [
            "grub-core/lib/posix_wrap",
            "grub-core/lib/gnulib",
            "grub-core/lib/json",
        ],
        "srcs": [
            Label("//:grub-core/disk/luks2.c"),
            Label("//:grub-core/lib/gnulib/base64.c"),
        ],
    },
    "lvm": {
        "srcs": [
            Label("//:grub-core/disk/lvm.c"),
        ],
    },
    "lzopio": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-DMINILZO_HAVE_CONFIG_H",
        ],
        "include_dirs": [
            "grub-core/lib/posix_wrap",
            "grub-core/lib/minilzo",
        ],
        "srcs": [
            Label("//:grub-core/io/lzopio.c"),
            Label("//:grub-core/lib/minilzo/minilzo.c"),
        ],
    },
    "macbless": {
        "srcs": [
            Label("//:grub-core/commands/macbless.c"),
        ],
    },
    "macho": {
        "srcs": [
            Label("//:grub-core/loader/macho.c"),
            Label("//:grub-core/loader/macho32.c"),
            Label("//:grub-core/loader/macho64.c"),
            Label("//:grub-core/loader/lzss.c"),
        ],
    },
    "mda_text": {
        "srcs": [
            Label("//:grub-core/term/i386/pc/mda_text.c"),
        ],
    },
    "mdraid09": {
        "srcs": [
            Label("//:grub-core/disk/mdraid_linux.c"),
        ],
    },
    "mdraid09_be": {
        "srcs": [
            Label("//:grub-core/disk/mdraid_linux_be.c"),
        ],
    },
    "mdraid1x": {
        "srcs": [
            Label("//:grub-core/disk/mdraid1x_linux.c"),
        ],
    },
    "memdisk": {
        "srcs": [
            Label("//:grub-core/disk/memdisk.c"),
        ],
    },
    "memrw": {
        "srcs": [
            Label("//:grub-core/commands/memrw.c"),
        ],
    },
    "minicmd": {
        "srcs": [
            Label("//:grub-core/commands/minicmd.c"),
        ],
    },
    "minix": {
        "srcs": [
            Label("//:grub-core/fs/minix.c"),
        ],
    },
    "minix2": {
        "srcs": [
            Label("//:grub-core/fs/minix2.c"),
        ],
    },
    "minix2_be": {
        "srcs": [
            Label("//:grub-core/fs/minix2_be.c"),
        ],
    },
    "minix3": {
        "srcs": [
            Label("//:grub-core/fs/minix3.c"),
        ],
    },
    "minix3_be": {
        "srcs": [
            Label("//:grub-core/fs/minix3_be.c"),
        ],
    },
    "minix_be": {
        "srcs": [
            Label("//:grub-core/fs/minix_be.c"),
        ],
    },
    "morse": {
        "srcs": [
            Label("//:grub-core/term/morse.c"),
        ],
    },
    "mpi": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-D_GCRYPT_IN_LIBGCRYPT=1",
        ],
        "include_dirs": [
            "grub-core/lib/libgcrypt_wrap",
            "grub-core/lib/posix_wrap",
            "include/grub/gcrypt",
        ],
        "srcs": [
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpiutil.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpi-bit.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpi-add.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpi-mul.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpi-mod.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpi-gcd.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpi-div.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpi-cmp.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpi-inv.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpi-pow.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpi-mpow.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpih-lshift.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpih-mul.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpih-mul1.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpih-mul2.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpih-mul3.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpih-add1.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpih-sub1.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpih-div.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpicoder.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpih-rshift.c"),
            Label("//:grub-core/lib/libgcrypt-grub/mpi/mpi-inline.c"),
            Label("//:grub-core/lib/libgcrypt_wrap/mem.c"),
        ],
    },
    "msdospart": {
        "srcs": [
            Label("//:grub-core/parttool/msdospart.c"),
        ],
    },
    "mul_test": {
        "srcs": [
            Label("//:grub-core/tests/mul_test.c"),
        ],
    },
    "multiboot": {
        "srcs": [
            Label("//:grub-core/loader/i386/multiboot_mbi.c"),
            Label("//:grub-core/loader/multiboot.c"),
        ],
    },
    "multiboot2": {
        "cppflags": [
            "-DGRUB_USE_MULTIBOOT2",
        ],
        "srcs": [
            Label("//:grub-core/loader/multiboot.c"),
            Label("//:grub-core/loader/multiboot_mbi2.c"),
        ],
    },
    "nativedisk": {
        "srcs": [
            Label("//:grub-core/commands/nativedisk.c"),
        ],
    },
    "net": {
        "srcs": [
            Label("//:grub-core/net/net.c"),
            Label("//:grub-core/net/dns.c"),
            Label("//:grub-core/net/bootp.c"),
            Label("//:grub-core/net/ip.c"),
            Label("//:grub-core/net/udp.c"),
            Label("//:grub-core/net/tcp.c"),
            Label("//:grub-core/net/icmp.c"),
            Label("//:grub-core/net/icmp6.c"),
            Label("//:grub-core/net/ethernet.c"),
            Label("//:grub-core/net/arp.c"),
            Label("//:grub-core/net/netbuff.c"),
        ],
    },
    "newc": {
        "srcs": [
            Label("//:grub-core/fs/newc.c"),
        ],
    },
    "nilfs2": {
        "srcs": [
            Label("//:grub-core/fs/nilfs2.c"),
        ],
    },
    "normal": {
        "cflags": [
            "-fno-builtin",
        ],
        "include_dirs": [
            "grub-core/lib/posix_wrap",
        ],
        "nodist": [
            "grub_script.tab.c",
            "grub_script.yy.c",
            "grub_script.tab.h",
            "grub_script.yy.h",
        ],
        "srcs": [
            Label("//:grub-core/normal/main.c"),
            Label("//:grub-core/normal/cmdline.c"),
            Label("//:grub-core/normal/dyncmd.c"),
            Label("//:grub-core/normal/auth.c"),
            Label("//:grub-core/normal/autofs.c"),
            Label("//:grub-core/normal/color.c"),
            Label("//:grub-core/normal/completion.c"),
            Label("//:grub-core/normal/menu.c"),
            Label("//:grub-core/normal/menu_entry.c"),
            Label("//:grub-core/normal/menu_text.c"),
            Label("//:grub-core/normal/misc.c"),
            Label("//:grub-core/normal/crypto.c"),
            Label("//:grub-core/normal/term.c"),
            Label("//:grub-core/normal/context.c"),
            Label("//:grub-core/normal/charset.c"),
            Label("//:grub-core/lib/getline.c"),
            Label("//:grub-core/script/main.c"),
            Label("//:grub-core/script/script.c"),
            Label("//:grub-core/script/execute.c"),
            Label("//:grub-core/script/function.c"),
            Label("//:grub-core/script/lexer.c"),
            Label("//:grub-core/script/argv.c"),
            Label("//:grub-core/commands/menuentry.c"),
            Label("//:grub-core/unidata.c"),
        ],
    },
    "ntfs": {
        "srcs": [
            Label("//:grub-core/fs/ntfs.c"),
        ],
    },
    "ntfscomp": {
        "srcs": [
            Label("//:grub-core/fs/ntfscomp.c"),
        ],
    },
    "odc": {
        "srcs": [
            Label("//:grub-core/fs/odc.c"),
        ],
    },
    "offsetio": {
        "srcs": [
            Label("//:grub-core/io/offset.c"),
        ],
    },
    "ofnet": {
        "srcs": [
            Label("//:grub-core/net/drivers/ieee1275/ofnet.c"),
        ],
    },
    "ohci": {
        "srcs": [
            Label("//:grub-core/bus/usb/ohci.c"),
        ],
    },
    "part_acorn": {
        "srcs": [
            Label("//:grub-core/partmap/acorn.c"),
        ],
    },
    "part_amiga": {
        "srcs": [
            Label("//:grub-core/partmap/amiga.c"),
        ],
    },
    "part_apple": {
        "srcs": [
            Label("//:grub-core/partmap/apple.c"),
        ],
    },
    "part_bsd": {
        "srcs": [
            Label("//:grub-core/partmap/bsdlabel.c"),
        ],
    },
    "part_dfly": {
        "srcs": [
            Label("//:grub-core/partmap/dfly.c"),
        ],
    },
    "part_dvh": {
        "srcs": [
            Label("//:grub-core/partmap/dvh.c"),
        ],
    },
    "part_gpt": {
        "srcs": [
            Label("//:grub-core/partmap/gpt.c"),
        ],
    },
    "part_msdos": {
        "srcs": [
            Label("//:grub-core/partmap/msdos.c"),
        ],
    },
    "part_plan": {
        "srcs": [
            Label("//:grub-core/partmap/plan.c"),
        ],
    },
    "part_sun": {
        "srcs": [
            Label("//:grub-core/partmap/sun.c"),
        ],
    },
    "part_sunpc": {
        "srcs": [
            Label("//:grub-core/partmap/sunpc.c"),
        ],
    },
    "parttool": {
        "srcs": [
            Label("//:grub-core/commands/parttool.c"),
        ],
    },
    "password": {
        "srcs": [
            Label("//:grub-core/commands/password.c"),
        ],
    },
    "password_pbkdf2": {
        "srcs": [
            Label("//:grub-core/commands/password_pbkdf2.c"),
        ],
    },
    "pata": {
        "srcs": [
            Label("//:grub-core/disk/pata.c"),
        ],
    },
    "pbkdf2": {
        "srcs": [
            Label("//:grub-core/lib/pbkdf2.c"),
        ],
    },
    "pbkdf2_test": {
        "srcs": [
            Label("//:grub-core/tests/pbkdf2_test.c"),
        ],
    },
    "pcidump": {
        "srcs": [
            Label("//:grub-core/commands/pcidump.c"),
        ],
    },
    "pgp": {
        "cflags": [
            "-fno-builtin",
        ],
        "include_dirs": [
            "grub-core/lib/posix_wrap",
        ],
        "srcs": [
            Label("//:grub-core/commands/pgp.c"),
        ],
    },
    "play": {
        "srcs": [
            Label("//:grub-core/commands/i386/pc/play.c"),
        ],
    },
    "png": {
        "srcs": [
            Label("//:grub-core/video/readers/png.c"),
        ],
    },
    "priority_queue": {
        "srcs": [
            Label("//:grub-core/lib/priority_queue.c"),
        ],
    },
    "probe": {
        "srcs": [
            Label("//:grub-core/commands/probe.c"),
        ],
    },
    "procfs": {
        "srcs": [
            Label("//:grub-core/fs/proc.c"),
        ],
    },
    "progress": {
        "srcs": [
            Label("//:grub-core/lib/progress.c"),
        ],
    },
    "raid5rec": {
        "srcs": [
            Label("//:grub-core/disk/raid5_recover.c"),
        ],
    },
    "raid6rec": {
        "srcs": [
            Label("//:grub-core/disk/raid6_recover.c"),
        ],
    },
    "rdmsr": {
        "srcs": [
            Label("//:grub-core/commands/i386/rdmsr.c"),
        ],
    },
    "read": {
        "srcs": [
            Label("//:grub-core/commands/read.c"),
        ],
    },
    "regexp": {
        "cflags": [
            "-fno-builtin",
        ],
        "include_dirs": [
            "grub-core/lib/posix_wrap",
            "grub-core/lib/gnulib",
        ],
        "srcs": [
            Label("//:grub-core/commands/regexp.c"),
            Label("//:grub-core/commands/wildcard.c"),
            Label("//:grub-core/lib/gnulib/regex.c"),
        ],
    },
    "reiserfs": {
        "srcs": [
            Label("//:grub-core/fs/reiserfs.c"),
        ],
    },
    "romfs": {
        "srcs": [
            Label("//:grub-core/fs/romfs.c"),
        ],
    },
    "scsi": {
        "srcs": [
            Label("//:grub-core/disk/scsi.c"),
        ],
    },
    "search": {
        "srcs": [
            Label("//:grub-core/commands/search_wrap.c"),
        ],
    },
    "search_fs_file": {
        "srcs": [
            Label("//:grub-core/commands/search_file.c"),
        ],
    },
    "search_fs_uuid": {
        "srcs": [
            Label("//:grub-core/commands/search_uuid.c"),
        ],
    },
    "search_label": {
        "srcs": [
            Label("//:grub-core/commands/search_label.c"),
        ],
    },
    "setjmp": {
        "srcs": [
            Label("//:grub-core/lib/setjmp.S"),
        ],
    },
    "setjmp_test": {
        "srcs": [
            Label("//:grub-core/tests/setjmp_test.c"),
        ],
    },
    "setpci": {
        "srcs": [
            Label("//:grub-core/commands/setpci.c"),
        ],
    },
    "sfs": {
        "srcs": [
            Label("//:grub-core/fs/sfs.c"),
        ],
    },
    "shift_test": {
        "srcs": [
            Label("//:grub-core/tests/shift_test.c"),
        ],
    },
    "signature_test": {
        "extra_inputs": [
            Label("//:grub-core/tests/signatures.h"),
        ],
        "srcs": [
            Label("//:grub-core/tests/signature_test.c"),
        ],
    },
    "sleep": {
        "srcs": [
            Label("//:grub-core/commands/sleep.c"),
        ],
    },
    "sleep_test": {
        "srcs": [
            Label("//:grub-core/tests/sleep_test.c"),
        ],
    },
    "spkmodem": {
        "srcs": [
            Label("//:grub-core/term/spkmodem.c"),
        ],
    },
    "squash4": {
        "cflags": [
            "-fno-builtin",
        ],
        "cppflags": [
            "-DMINILZO_HAVE_CONFIG_H",
        ],
        "include_dirs": [
            "grub-core/lib/posix_wrap",
            "grub-core/lib/xzembed",
            "grub-core/lib/minilzo",
        ],
        "srcs": [
            Label("//:grub-core/fs/squash4.c"),
        ],
    },
    "strtoull_test": {
        "srcs": [
            Label("//:grub-core/tests/strtoull_test.c"),
        ],
    },
    "suspend": {
        "srcs": [
            Label("//:grub-core/commands/ieee1275/suspend.c"),
        ],
    },
    "syslinuxcfg": {
        "srcs": [
            Label("//:grub-core/lib/syslinux_parse.c"),
            Label("//:grub-core/commands/syslinuxcfg.c"),
        ],
    },
    "tar": {
        "srcs": [
            Label("//:grub-core/fs/tar.c"),
        ],
    },
    "terminal": {
        "srcs": [
            Label("//:grub-core/commands/terminal.c"),
        ],
    },
    "terminfo": {
        "srcs": [
            Label("//:grub-core/term/terminfo.c"),
            Label("//:grub-core/term/tparm.c"),
        ],
    },
    "test": {
        "srcs": [
            Label("//:grub-core/commands/test.c"),
        ],
    },
    "test_blockarg": {
        "srcs": [
            Label("//:grub-core/tests/test_blockarg.c"),
        ],
    },
    "testload": {
        "srcs": [
            Label("//:grub-core/commands/testload.c"),
        ],
    },
    "testspeed": {
        "srcs": [
            Label("//:grub-core/commands/testspeed.c"),
        ],
    },
    "tftp": {
        "srcs": [
            Label("//:grub-core/net/tftp.c"),
        ],
    },
    "tga": {
        "srcs": [
            Label("//:grub-core/video/readers/tga.c"),
        ],
    },
    "time": {
        "srcs": [
            Label("//:grub-core/commands/time.c"),
        ],
    },
    "tpm": {
        "srcs": [
            Label("//:grub-core/commands/efi/tpm.c"),
            Label("//:grub-core/commands/tpm.c"),
        ],
    },
    "tr": {
        "srcs": [
            Label("//:grub-core/commands/tr.c"),
        ],
    },
    "trig": {
        "nodist": [
            "trigtables.c",
        ],
    },
    "true": {
        "srcs": [
            Label("//:grub-core/commands/true.c"),
        ],
    },
    "udf": {
        "srcs": [
            Label("//:grub-core/fs/udf.c"),
        ],
    },
    "ufs1": {
        "srcs": [
            Label("//:grub-core/fs/ufs.c"),
        ],
    },
    "ufs1_be": {
        "srcs": [
            Label("//:grub-core/fs/ufs_be.c"),
        ],
    },
    "ufs2": {
        "srcs": [
            Label("//:grub-core/fs/ufs2.c"),
        ],
    },
    "uhci": {
        "srcs": [
            Label("//:grub-core/bus/usb/uhci.c"),
        ],
    },
    "usb": {
        "srcs": [
            Label("//:grub-core/bus/usb/usb.c"),
            Label("//:grub-core/bus/usb/usbtrans.c"),
            Label("//:grub-core/bus/usb/usbhub.c"),
        ],
    },
    "usb_keyboard": {
        "srcs": [
            Label("//:grub-core/term/usb_keyboard.c"),
        ],
    },
    "usbms": {
        "srcs": [
            Label("//:grub-core/disk/usbms.c"),
        ],
    },
    "usbserial_common": {
        "srcs": [
            Label("//:grub-core/bus/usb/serial/common.c"),
        ],
    },
    "usbserial_ftdi": {
        "srcs": [
            Label("//:grub-core/bus/usb/serial/ftdi.c"),
        ],
    },
    "usbserial_pl2303": {
        "srcs": [
            Label("//:grub-core/bus/usb/serial/pl2303.c"),
        ],
    },
    "usbserial_usbdebug": {
        "srcs": [
            Label("//:grub-core/bus/usb/serial/usbdebug_late.c"),
        ],
    },
    "usbtest": {
        "srcs": [
            Label("//:grub-core/commands/usbtest.c"),
        ],
    },
    "video": {
        "srcs": [
            Label("//:grub-core/video/video.c"),
        ],
    },
    "video_bochs": {
        "srcs": [
            Label("//:grub-core/video/bochs.c"),
        ],
    },
    "video_cirrus": {
        "srcs": [
            Label("//:grub-core/video/cirrus.c"),
        ],
    },
    "video_colors": {
        "srcs": [
            Label("//:grub-core/video/colors.c"),
        ],
    },
    "video_fb": {
        "srcs": [
            Label("//:grub-core/video/fb/video_fb.c"),
            Label("//:grub-core/video/fb/fbblit.c"),
            Label("//:grub-core/video/fb/fbfill.c"),
            Label("//:grub-core/video/fb/fbutil.c"),
        ],
    },
    "videoinfo": {
        "srcs": [
            Label("//:grub-core/commands/videoinfo.c"),
        ],
    },
    "videotest": {
        "srcs": [
            Label("//:grub-core/commands/videotest.c"),
        ],
    },
    "videotest_checksum": {
        "srcs": [
            Label("//:grub-core/tests/videotest_checksum.c"),
        ],
    },
    "wrmsr": {
        "srcs": [
            Label("//:grub-core/commands/i386/wrmsr.c"),
        ],
    },
    "xfs": {
        "srcs": [
            Label("//:grub-core/fs/xfs.c"),
        ],
    },
    "xnu": {
        "srcs": [
            Label("//:grub-core/loader/xnu_resume.c"),
            Label("//:grub-core/loader/i386/xnu.c"),
            Label("//:grub-core/loader/xnu.c"),
        ],
    },
    "xnu_uuid": {
        "srcs": [
            Label("//:grub-core/commands/xnu_uuid.c"),
        ],
    },
    "xnu_uuid_test": {
        "srcs": [
            Label("//:grub-core/tests/xnu_uuid_test.c"),
        ],
    },
    "xzio": {
        "include_dirs": [
            "grub-core/lib/posix_wrap",
            "grub-core/lib/xzembed",
        ],
        "srcs": [
            Label("//:grub-core/io/xzio.c"),
            Label("//:grub-core/lib/xzembed/xz_dec_bcj.c"),
            Label("//:grub-core/lib/xzembed/xz_dec_lzma2.c"),
            Label("//:grub-core/lib/xzembed/xz_dec_stream.c"),
        ],
    },
    "zfs": {
        "srcs": [
            Label("//:grub-core/fs/zfs/zfs.c"),
            Label("//:grub-core/fs/zfs/zfs_lzjb.c"),
            Label("//:grub-core/fs/zfs/zfs_lz4.c"),
            Label("//:grub-core/fs/zfs/zfs_sha256.c"),
            Label("//:grub-core/fs/zfs/zfs_fletcher.c"),
        ],
    },
    "zfscrypt": {
        "srcs": [
            Label("//:grub-core/fs/zfs/zfscrypt.c"),
        ],
    },
    "zfsinfo": {
        "srcs": [
            Label("//:grub-core/fs/zfs/zfsinfo.c"),
        ],
    },
    "zstd": {
        "cflags": [
            "-fno-builtin",
        ],
        "include_dirs": [
            "grub-core/lib/posix_wrap",
            "grub-core/lib/zstd",
        ],
        "srcs": [
            Label("//:grub-core/lib/zstd/debug.c"),
            Label("//:grub-core/lib/zstd/entropy_common.c"),
            Label("//:grub-core/lib/zstd/error_private.c"),
            Label("//:grub-core/lib/zstd/fse_decompress.c"),
            Label("//:grub-core/lib/zstd/huf_decompress.c"),
            Label("//:grub-core/lib/zstd/module.c"),
            Label("//:grub-core/lib/zstd/xxhash.c"),
            Label("//:grub-core/lib/zstd/zstd_common.c"),
            Label("//:grub-core/lib/zstd/zstd_decompress.c"),
        ],
    },
}
