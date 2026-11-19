# Generated code. DO NOT EDIT.

ASM_CRYPTO_EXTRA_SRCS = [
    "crypto/aes/aes_cbc.c",
    "crypto/aes/aes_core.c",
    "crypto/bn/bn_ppc.c",
    "crypto/camellia/camellia.c",
    "crypto/camellia/cmll_cbc.c",
    "crypto/chacha/chacha_ppc.c",
    "crypto/ec/ecp_nistz256.c",
    "crypto/ec/ecp_ppc.c",
    "crypto/poly1305/poly1305_ppc.c",
    "crypto/ppccap.c",
    "crypto/rc4/rc4_enc.c",
    "crypto/rc4/rc4_skey.c",
    "crypto/sha/sha_ppc.c",
    "crypto/whrlpool/wp_block.c",
    "providers/implementations/rands/seeding/rand_cpu_x86.c"
]

ASM_SSL_EXTRA_SRCS = []

ASM_APP_EXTRA_SRCS = []

PERLASM = {
    "crypto/aes/aes-ppc.s": {
        "args": [],
        "script": "crypto/aes/asm/aes-ppc.pl"
    },
    "crypto/aes/aesp8-ppc.s": {
        "args": [],
        "script": "crypto/aes/asm/aesp8-ppc.pl"
    },
    "crypto/aes/vpaes-ppc.s": {
        "args": [],
        "script": "crypto/aes/asm/vpaes-ppc.pl"
    },
    "crypto/bn/bn-ppc.s": {
        "args": [],
        "script": "crypto/bn/asm/ppc.pl"
    },
    "crypto/bn/ppc-mont.s": {
        "args": [],
        "script": "crypto/bn/asm/ppc-mont.pl"
    },
    "crypto/bn/ppc64-mont-fixed.s": {
        "args": [],
        "script": "crypto/bn/asm/ppc64-mont-fixed.pl"
    },
    "crypto/chacha/chacha-ppc.s": {
        "args": [],
        "script": "crypto/chacha/asm/chacha-ppc.pl"
    },
    "crypto/chacha/chachap10-ppc.s": {
        "args": [],
        "script": "crypto/chacha/asm/chachap10-ppc.pl"
    },
    "crypto/ec/ecp_nistz256-ppc64.s": {
        "args": [],
        "script": "crypto/ec/asm/ecp_nistz256-ppc64.pl"
    },
    "crypto/ec/x25519-ppc64.s": {
        "args": [],
        "script": "crypto/ec/asm/x25519-ppc64.pl"
    },
    "crypto/modes/aes-gcm-ppc.s": {
        "args": [],
        "script": "crypto/modes/asm/aes-gcm-ppc.pl"
    },
    "crypto/modes/ghashp8-ppc.s": {
        "args": [],
        "script": "crypto/modes/asm/ghashp8-ppc.pl"
    },
    "crypto/poly1305/poly1305-ppc.s": {
        "args": [],
        "script": "crypto/poly1305/asm/poly1305-ppc.pl"
    },
    "crypto/poly1305/poly1305-ppcfp.s": {
        "args": [],
        "script": "crypto/poly1305/asm/poly1305-ppcfp.pl"
    },
    "crypto/ppccpuid.s": {
        "args": [],
        "script": "crypto/ppccpuid.pl"
    },
    "crypto/sha/keccak1600-ppc64.s": {
        "args": [],
        "script": "crypto/sha/asm/keccak1600-ppc64.pl"
    },
    "crypto/sha/sha1-ppc.s": {
        "args": [],
        "script": "crypto/sha/asm/sha1-ppc.pl"
    },
    "crypto/sha/sha256-ppc.s": {
        "args": [],
        "script": "crypto/sha/asm/sha512-ppc.pl"
    },
    "crypto/sha/sha256p8-ppc.s": {
        "args": [],
        "script": "crypto/sha/asm/sha512p8-ppc.pl"
    },
    "crypto/sha/sha512-ppc.s": {
        "args": [],
        "script": "crypto/sha/asm/sha512-ppc.pl"
    },
    "crypto/sha/sha512p8-ppc.s": {
        "args": [],
        "script": "crypto/sha/asm/sha512p8-ppc.pl"
    }
}

LIBCRYPTO_DEFINES = [
    "-DAES_ASM",
    "-DECP_NISTZ256_ASM",
    "-DKECCAK1600_ASM",
    "-DOPENSSL_BN_ASM_MONT",
    "-DOPENSSL_CPUID_OBJ",
    "-DPOLY1305_ASM",
    "-DSHA1_ASM",
    "-DSHA256_ASM",
    "-DSHA512_ASM",
    "-DVPAES_ASM",
    "-DX25519_ASM"
]

LIBSSL_DEFINES = []

OPENSSL_APP_DEFINES = [
    "-DNDEBUG"
]

OPENSSL_DEFINES = [
    "-DL_ENDIAN",
    "-DNDEBUG",
    "-DOPENSSL_NO_KTLS",
    "-DOPENSSL_PIC"
]
