# Generated code. DO NOT EDIT.

ASM_CRYPTO_EXTRA_SRCS = [
    "crypto/aes/aes_cbc.c",
    "crypto/armcap.c",
    "crypto/bn/bn_asm.c",
    "crypto/camellia/camellia.c",
    "crypto/camellia/cmll_cbc.c",
    "crypto/ec/ecp_nistz256.c",
    "crypto/rc4/rc4_enc.c",
    "crypto/rc4/rc4_skey.c",
    "crypto/whrlpool/wp_block.c",
    "providers/implementations/rands/seeding/rand_cpu_x86.c"
]

ASM_SSL_EXTRA_SRCS = []

ASM_APP_EXTRA_SRCS = []

PERLASM = {
    "crypto/aes/aes-armv4.S": {
        "args": [],
        "script": "crypto/aes/asm/aes-armv4.pl"
    },
    "crypto/aes/aesv8-armx.S": {
        "args": [],
        "script": "crypto/aes/asm/aesv8-armx.pl"
    },
    "crypto/aes/bsaes-armv7.S": {
        "args": [],
        "script": "crypto/aes/asm/bsaes-armv7.pl"
    },
    "crypto/armv4cpuid.S": {
        "args": [],
        "script": "crypto/armv4cpuid.pl"
    },
    "crypto/bn/armv4-gf2m.S": {
        "args": [],
        "script": "crypto/bn/asm/armv4-gf2m.pl"
    },
    "crypto/bn/armv4-mont.S": {
        "args": [],
        "script": "crypto/bn/asm/armv4-mont.pl"
    },
    "crypto/chacha/chacha-armv4.S": {
        "args": [],
        "script": "crypto/chacha/asm/chacha-armv4.pl"
    },
    "crypto/ec/ecp_nistz256-armv4.S": {
        "args": [],
        "script": "crypto/ec/asm/ecp_nistz256-armv4.pl"
    },
    "crypto/modes/ghash-armv4.S": {
        "args": [],
        "script": "crypto/modes/asm/ghash-armv4.pl"
    },
    "crypto/modes/ghashv8-armx.S": {
        "args": [],
        "script": "crypto/modes/asm/ghashv8-armx.pl"
    },
    "crypto/poly1305/poly1305-armv4.S": {
        "args": [],
        "script": "crypto/poly1305/asm/poly1305-armv4.pl"
    },
    "crypto/sha/keccak1600-armv4.S": {
        "args": [],
        "script": "crypto/sha/asm/keccak1600-armv4.pl"
    },
    "crypto/sha/sha1-armv4-large.S": {
        "args": [],
        "script": "crypto/sha/asm/sha1-armv4-large.pl"
    },
    "crypto/sha/sha256-armv4.S": {
        "args": [],
        "script": "crypto/sha/asm/sha256-armv4.pl"
    },
    "crypto/sha/sha512-armv4.S": {
        "args": [],
        "script": "crypto/sha/asm/sha512-armv4.pl"
    }
}

LIBCRYPTO_DEFINES = [
    "-DAES_ASM",
    "-DBSAES_ASM",
    "-DECP_NISTZ256_ASM",
    "-DGHASH_ASM",
    "-DKECCAK1600_ASM",
    "-DOPENSSL_BN_ASM_GF2m",
    "-DOPENSSL_BN_ASM_MONT",
    "-DOPENSSL_CPUID_OBJ",
    "-DPOLY1305_ASM",
    "-DSHA1_ASM",
    "-DSHA256_ASM",
    "-DSHA512_ASM"
]

LIBSSL_DEFINES = []

OPENSSL_APP_DEFINES = [
    "-DNDEBUG"
]

OPENSSL_DEFINES = [
    "-DNDEBUG",
    "-DOPENSSL_BUILDING_OPENSSL",
    "-DOPENSSL_NO_KTLS",
    "-DOPENSSL_PIC",
    "-DOPENSSL_USE_NODELETE"
]
