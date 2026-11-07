# Generated code. DO NOT EDIT.

ASM_CRYPTO_EXTRA_SRCS = [
    "crypto/bn/bn_asm.c",
    "crypto/bn/rsaz_exp.c",
    "crypto/bn/rsaz_exp_x2.c",
    "crypto/ec/ecp_nistz256.c",
    "ms/uplink.c",
    "providers/implementations/rands/seeding/rand_cpu_x86.c",
    "providers/implementations/storemgmt/winstore_store.c"
]

ASM_SSL_EXTRA_SRCS = []

ASM_APP_EXTRA_SRCS = [
    "apps/lib/win32_init.c",
    "ms/applink.c"
]

PERLASM = {
    "crypto/aes/aes-cfb-avx512.s": {
        "args": [],
        "script": "crypto/aes/asm/aes-cfb-avx512.pl"
    },
    "crypto/aes/aes-x86_64.s": {
        "args": [],
        "script": "crypto/aes/asm/aes-x86_64.pl"
    },
    "crypto/aes/aesni-mb-x86_64.s": {
        "args": [],
        "script": "crypto/aes/asm/aesni-mb-x86_64.pl"
    },
    "crypto/aes/aesni-sha1-x86_64.s": {
        "args": [],
        "script": "crypto/aes/asm/aesni-sha1-x86_64.pl"
    },
    "crypto/aes/aesni-sha256-x86_64.s": {
        "args": [],
        "script": "crypto/aes/asm/aesni-sha256-x86_64.pl"
    },
    "crypto/aes/aesni-x86_64.s": {
        "args": [],
        "script": "crypto/aes/asm/aesni-x86_64.pl"
    },
    "crypto/aes/aesni-xts-avx512.s": {
        "args": [],
        "script": "crypto/aes/asm/aesni-xts-avx512.pl"
    },
    "crypto/aes/bsaes-x86_64.s": {
        "args": [],
        "script": "crypto/aes/asm/bsaes-x86_64.pl"
    },
    "crypto/aes/vpaes-x86_64.s": {
        "args": [],
        "script": "crypto/aes/asm/vpaes-x86_64.pl"
    },
    "crypto/bn/rsaz-2k-avx512.s": {
        "args": [],
        "script": "crypto/bn/asm/rsaz-2k-avx512.pl"
    },
    "crypto/bn/rsaz-2k-avxifma.s": {
        "args": [],
        "script": "crypto/bn/asm/rsaz-2k-avxifma.pl"
    },
    "crypto/bn/rsaz-3k-avx512.s": {
        "args": [],
        "script": "crypto/bn/asm/rsaz-3k-avx512.pl"
    },
    "crypto/bn/rsaz-3k-avxifma.s": {
        "args": [],
        "script": "crypto/bn/asm/rsaz-3k-avxifma.pl"
    },
    "crypto/bn/rsaz-4k-avx512.s": {
        "args": [],
        "script": "crypto/bn/asm/rsaz-4k-avx512.pl"
    },
    "crypto/bn/rsaz-4k-avxifma.s": {
        "args": [],
        "script": "crypto/bn/asm/rsaz-4k-avxifma.pl"
    },
    "crypto/bn/rsaz-avx2.s": {
        "args": [],
        "script": "crypto/bn/asm/rsaz-avx2.pl"
    },
    "crypto/bn/rsaz-x86_64.s": {
        "args": [],
        "script": "crypto/bn/asm/rsaz-x86_64.pl"
    },
    "crypto/bn/x86_64-gf2m.s": {
        "args": [],
        "script": "crypto/bn/asm/x86_64-gf2m.pl"
    },
    "crypto/bn/x86_64-mont.s": {
        "args": [],
        "script": "crypto/bn/asm/x86_64-mont.pl"
    },
    "crypto/bn/x86_64-mont5.s": {
        "args": [],
        "script": "crypto/bn/asm/x86_64-mont5.pl"
    },
    "crypto/camellia/cmll-x86_64.s": {
        "args": [],
        "script": "crypto/camellia/asm/cmll-x86_64.pl"
    },
    "crypto/chacha/chacha-x86_64.s": {
        "args": [],
        "script": "crypto/chacha/asm/chacha-x86_64.pl"
    },
    "crypto/ec/ecp_nistz256-x86_64.s": {
        "args": [],
        "script": "crypto/ec/asm/ecp_nistz256-x86_64.pl"
    },
    "crypto/ec/x25519-x86_64.s": {
        "args": [],
        "script": "crypto/ec/asm/x25519-x86_64.pl"
    },
    "crypto/md5/md5-x86_64.s": {
        "args": [],
        "script": "crypto/md5/asm/md5-x86_64.pl"
    },
    "crypto/modes/aes-gcm-avx512.s": {
        "args": [],
        "script": "crypto/modes/asm/aes-gcm-avx512.pl"
    },
    "crypto/modes/aesni-gcm-x86_64.s": {
        "args": [],
        "script": "crypto/modes/asm/aesni-gcm-x86_64.pl"
    },
    "crypto/modes/ghash-x86_64.s": {
        "args": [],
        "script": "crypto/modes/asm/ghash-x86_64.pl"
    },
    "crypto/poly1305/poly1305-x86_64.s": {
        "args": [],
        "script": "crypto/poly1305/asm/poly1305-x86_64.pl"
    },
    "crypto/rc4/rc4-md5-x86_64.s": {
        "args": [],
        "script": "crypto/rc4/asm/rc4-md5-x86_64.pl"
    },
    "crypto/rc4/rc4-x86_64.s": {
        "args": [],
        "script": "crypto/rc4/asm/rc4-x86_64.pl"
    },
    "crypto/sha/keccak1600-x86_64.s": {
        "args": [],
        "script": "crypto/sha/asm/keccak1600-x86_64.pl"
    },
    "crypto/sha/sha1-mb-x86_64.s": {
        "args": [],
        "script": "crypto/sha/asm/sha1-mb-x86_64.pl"
    },
    "crypto/sha/sha1-x86_64.s": {
        "args": [],
        "script": "crypto/sha/asm/sha1-x86_64.pl"
    },
    "crypto/sha/sha256-mb-x86_64.s": {
        "args": [],
        "script": "crypto/sha/asm/sha256-mb-x86_64.pl"
    },
    "crypto/sha/sha256-x86_64.s": {
        "args": [],
        "script": "crypto/sha/asm/sha512-x86_64.pl"
    },
    "crypto/sha/sha512-x86_64.s": {
        "args": [],
        "script": "crypto/sha/asm/sha512-x86_64.pl"
    },
    "crypto/sm3/sm3-x86_64.S": {
        "args": [],
        "script": "crypto/sm3/asm/sm3-x86_64.pl"
    },
    "crypto/sm4/sm4-x86_64.S": {
        "args": [],
        "script": "crypto/sm4/asm/sm4-x86_64.pl"
    },
    "crypto/uplink-x86_64.s": {
        "args": [],
        "script": "ms/uplink-x86_64.pl"
    },
    "crypto/whrlpool/wp-x86_64.s": {
        "args": [],
        "script": "crypto/whrlpool/asm/wp-x86_64.pl"
    },
    "crypto/x86_64cpuid.s": {
        "args": [],
        "script": "crypto/x86_64cpuid.pl"
    }
}

LIBCRYPTO_DEFINES = [
    "-DAES_ASM",
    "-DBSAES_ASM",
    "-DCMLL_ASM",
    "-DECP_NISTZ256_ASM",
    "-DGHASH_ASM",
    "-DKECCAK1600_ASM",
    "-DMD5_ASM",
    "-DOPENSSL_BN_ASM_GF2m",
    "-DOPENSSL_BN_ASM_MONT",
    "-DOPENSSL_BN_ASM_MONT5",
    "-DOPENSSL_CPUID_OBJ",
    "-DOPENSSL_IA32_SSE2",
    "-DOPENSSL_SM3_ASM",
    "-DOPENSSL_USE_APPLINK",
    "-DPOLY1305_ASM",
    "-DRC4_ASM",
    "-DSHA1_ASM",
    "-DSHA256_ASM",
    "-DSHA512_ASM",
    "-DSM4_ASM",
    "-DVPAES_ASM",
    "-DWHIRLPOOL_ASM",
    "-DX25519_ASM"
]

LIBSSL_DEFINES = [
    "-DAES_ASM"
]

OPENSSL_APP_DEFINES = [
    "-DNDEBUG"
]

OPENSSL_DEFINES = [
    "-DNDEBUG",
    "-DOPENSSL_NO_KTLS",
    "-DOPENSSL_PIC",
    "-DOPENSSL_SYS_WIN32",
    "-DUNICODE",
    "-DWIN32_LEAN_AND_MEAN",
    "-D_CRT_SECURE_NO_DEPRECATE",
    "-D_UNICODE",
    "-D_WINSOCK_DEPRECATED_NO_WARNINGS"
]
