# Generated code. DO NOT EDIT.

ASM_CRYPTO_EXTRA_SRCS = [
    "crypto/bn/asm/s390x.S",
    "crypto/bn/bn_s390x.c",
    "crypto/camellia/camellia.c",
    "crypto/camellia/cmll_cbc.c",
    "crypto/ec/ecp_s390x_nistp.c",
    "crypto/ec/ecx_s390x.c",
    "crypto/s390xcap.c",
    "crypto/whrlpool/wp_block.c",
    "providers/implementations/rands/seeding/rand_cpu_x86.c"
]

ASM_SSL_EXTRA_SRCS = []

ASM_APP_EXTRA_SRCS = []

PERLASM = {
    "crypto/aes/aes-s390x.S": {
        "args": [],
        "script": "crypto/aes/asm/aes-s390x.pl"
    },
    "crypto/bn/s390x-gf2m.s": {
        "args": [],
        "script": "crypto/bn/asm/s390x-gf2m.pl"
    },
    "crypto/bn/s390x-mont.S": {
        "args": [],
        "script": "crypto/bn/asm/s390x-mont.pl"
    },
    "crypto/chacha/chacha-s390x.S": {
        "args": [],
        "script": "crypto/chacha/asm/chacha-s390x.pl"
    },
    "crypto/modes/ghash-s390x.S": {
        "args": [],
        "script": "crypto/modes/asm/ghash-s390x.pl"
    },
    "crypto/poly1305/poly1305-s390x.S": {
        "args": [],
        "script": "crypto/poly1305/asm/poly1305-s390x.pl"
    },
    "crypto/rc4/rc4-s390x.s": {
        "args": [],
        "script": "crypto/rc4/asm/rc4-s390x.pl"
    },
    "crypto/s390xcpuid.S": {
        "args": [],
        "script": "crypto/s390xcpuid.pl"
    },
    "crypto/sha/keccak1600-s390x.S": {
        "args": [],
        "script": "crypto/sha/asm/keccak1600-s390x.pl"
    },
    "crypto/sha/sha1-s390x.S": {
        "args": [],
        "script": "crypto/sha/asm/sha1-s390x.pl"
    },
    "crypto/sha/sha256-s390x.S": {
        "args": [],
        "script": "crypto/sha/asm/sha512-s390x.pl"
    },
    "crypto/sha/sha512-s390x.S": {
        "args": [],
        "script": "crypto/sha/asm/sha512-s390x.pl"
    }
}

LIBCRYPTO_DEFINES = [
    "-DAES_ASM",
    "-DAES_CTR_ASM",
    "-DAES_XTS_ASM",
    "-DGHASH_ASM",
    "-DKECCAK1600_ASM",
    "-DOPENSSL_BN_ASM_GF2m",
    "-DOPENSSL_BN_ASM_MONT",
    "-DOPENSSL_CPUID_OBJ",
    "-DPOLY1305_ASM",
    "-DRC4_ASM",
    "-DS390X_EC_ASM",
    "-DSHA1_ASM",
    "-DSHA256_ASM",
    "-DSHA512_ASM"
]

LIBSSL_DEFINES = []

OPENSSL_APP_DEFINES = [
    "-DNDEBUG"
]

OPENSSL_DEFINES = [
    "-DB_ENDIAN",
    "-DNDEBUG",
    "-DOPENSSL_BUILDING_OPENSSL",
    "-DOPENSSL_NO_KTLS",
    "-DOPENSSL_PIC",
    "-DOPENSSL_USE_NODELETE"
]
