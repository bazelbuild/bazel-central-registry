# Generated code. DO NOT EDIT.

ASM_CRYPTO_EXTRA_SRCS = [
    "crypto/aes/aes_cbc.c",
    "crypto/aes/aes_core.c",
    "crypto/armcap.c",
    "crypto/bn/bn_asm.c",
    "crypto/camellia/camellia.c",
    "crypto/camellia/cmll_cbc.c",
    "crypto/ec/ecp_nistz256.c",
    "crypto/ec/ecp_sm2p256.c",
    "crypto/ec/ecp_sm2p256_table.c",
    "crypto/rc4/rc4_enc.c",
    "crypto/rc4/rc4_skey.c",
    "crypto/whrlpool/wp_block.c",
    "providers/implementations/rands/seeding/rand_cpu_x86.c"
]

ASM_SSL_EXTRA_SRCS = []

ASM_APP_EXTRA_SRCS = []

PERLASM = {
    "crypto/aes/aesv8-armx.S": {
        "args": [],
        "script": "crypto/aes/asm/aesv8-armx.pl"
    },
    "crypto/aes/bsaes-armv8.S": {
        "args": [],
        "script": "crypto/aes/asm/bsaes-armv8.pl"
    },
    "crypto/aes/vpaes-armv8.S": {
        "args": [],
        "script": "crypto/aes/asm/vpaes-armv8.pl"
    },
    "crypto/arm64cpuid.S": {
        "args": [],
        "script": "crypto/arm64cpuid.pl"
    },
    "crypto/bn/armv8-mont.S": {
        "args": [],
        "script": "crypto/bn/asm/armv8-mont.pl"
    },
    "crypto/chacha/chacha-armv8-sve.S": {
        "args": [],
        "script": "crypto/chacha/asm/chacha-armv8-sve.pl"
    },
    "crypto/chacha/chacha-armv8.S": {
        "args": [],
        "script": "crypto/chacha/asm/chacha-armv8.pl"
    },
    "crypto/ec/ecp_nistz256-armv8.S": {
        "args": [],
        "script": "crypto/ec/asm/ecp_nistz256-armv8.pl"
    },
    "crypto/ec/ecp_sm2p256-armv8.S": {
        "args": [],
        "script": "crypto/ec/asm/ecp_sm2p256-armv8.pl"
    },
    "crypto/md5/md5-aarch64.S": {
        "args": [],
        "script": "crypto/md5/asm/md5-aarch64.pl"
    },
    "crypto/modes/aes-gcm-armv8-unroll8_64.S": {
        "args": [],
        "script": "crypto/modes/asm/aes-gcm-armv8-unroll8_64.pl"
    },
    "crypto/modes/aes-gcm-armv8_64.S": {
        "args": [],
        "script": "crypto/modes/asm/aes-gcm-armv8_64.pl"
    },
    "crypto/modes/ghashv8-armx.S": {
        "args": [],
        "script": "crypto/modes/asm/ghashv8-armx.pl"
    },
    "crypto/poly1305/poly1305-armv8.S": {
        "args": [],
        "script": "crypto/poly1305/asm/poly1305-armv8.pl"
    },
    "crypto/sha/keccak1600-armv8.S": {
        "args": [],
        "script": "crypto/sha/asm/keccak1600-armv8.pl"
    },
    "crypto/sha/sha1-armv8.S": {
        "args": [],
        "script": "crypto/sha/asm/sha1-armv8.pl"
    },
    "crypto/sha/sha256-armv8.S": {
        "args": [],
        "script": "crypto/sha/asm/sha512-armv8.pl"
    },
    "crypto/sha/sha512-armv8.S": {
        "args": [],
        "script": "crypto/sha/asm/sha512-armv8.pl"
    },
    "crypto/sm3/sm3-armv8.S": {
        "args": [],
        "script": "crypto/sm3/asm/sm3-armv8.pl"
    },
    "crypto/sm4/sm4-armv8.S": {
        "args": [],
        "script": "crypto/sm4/asm/sm4-armv8.pl"
    },
    "crypto/sm4/vpsm4-armv8.S": {
        "args": [],
        "script": "crypto/sm4/asm/vpsm4-armv8.pl"
    },
    "crypto/sm4/vpsm4_ex-armv8.S": {
        "args": [],
        "script": "crypto/sm4/asm/vpsm4_ex-armv8.pl"
    }
}

LIBCRYPTO_DEFINES = [
    "-DBSAES_ASM",
    "-DECP_NISTZ256_ASM",
    "-DECP_SM2P256_ASM",
    "-DKECCAK1600_ASM",
    "-DMD5_ASM",
    "-DOPENSSL_BN_ASM_MONT",
    "-DOPENSSL_CPUID_OBJ",
    "-DOPENSSL_SM3_ASM",
    "-DPOLY1305_ASM",
    "-DSHA1_ASM",
    "-DSHA256_ASM",
    "-DSHA512_ASM",
    "-DSM4_ASM",
    "-DVPAES_ASM",
    "-DVPSM4_ASM"
]

LIBSSL_DEFINES = []

OPENSSL_APP_DEFINES = [
    "-DNDEBUG",
    "-D_REENTRANT"
]

OPENSSL_DEFINES = [
    "-DNDEBUG",
    "-DOPENSSL_BUILDING_OPENSSL",
    "-DOPENSSL_NO_KTLS",
    "-DOPENSSL_PIC",
    "-D_REENTRANT"
]
