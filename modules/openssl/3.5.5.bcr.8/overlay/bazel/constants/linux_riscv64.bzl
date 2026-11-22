# Generated code. DO NOT EDIT.

ASM_CRYPTO_EXTRA_SRCS = [
    "crypto/aes/aes_cbc.c",
    "crypto/bn/bn_asm.c",
    "crypto/camellia/camellia.c",
    "crypto/camellia/cmll_cbc.c",
    "crypto/chacha/chacha_enc.c",
    "crypto/chacha/chacha_riscv.c",
    "crypto/rc4/rc4_enc.c",
    "crypto/rc4/rc4_skey.c",
    "crypto/riscvcap.c",
    "crypto/sha/keccak1600.c",
    "crypto/sha/sha_riscv.c",
    "crypto/sm3/sm3_riscv.c",
    "crypto/whrlpool/wp_block.c",
    "providers/implementations/rands/seeding/rand_cpu_x86.c"
]

ASM_SSL_EXTRA_SRCS = []

ASM_APP_EXTRA_SRCS = []

PERLASM = {
    "crypto/aes/aes-riscv64-zkn.s": {
        "args": [],
        "script": "crypto/aes/asm/aes-riscv64-zkn.pl"
    },
    "crypto/aes/aes-riscv64-zvbb-zvkg-zvkned.s": {
        "args": [],
        "script": "crypto/aes/asm/aes-riscv64-zvbb-zvkg-zvkned.pl"
    },
    "crypto/aes/aes-riscv64-zvkb-zvkned.s": {
        "args": [],
        "script": "crypto/aes/asm/aes-riscv64-zvkb-zvkned.pl"
    },
    "crypto/aes/aes-riscv64-zvkned.s": {
        "args": [],
        "script": "crypto/aes/asm/aes-riscv64-zvkned.pl"
    },
    "crypto/aes/aes-riscv64.s": {
        "args": [],
        "script": "crypto/aes/asm/aes-riscv64.pl"
    },
    "crypto/chacha/chacha-riscv64-v-zbb-zvkb.s": {
        "args": [
            "zvkb"
        ],
        "script": "crypto/chacha/asm/chacha-riscv64-v-zbb.pl"
    },
    "crypto/chacha/chacha-riscv64-v-zbb.s": {
        "args": [],
        "script": "crypto/chacha/asm/chacha-riscv64-v-zbb.pl"
    },
    "crypto/modes/aes-gcm-riscv64-zvkb-zvkg-zvkned.s": {
        "args": [],
        "script": "crypto/modes/asm/aes-gcm-riscv64-zvkb-zvkg-zvkned.pl"
    },
    "crypto/modes/ghash-riscv64-zvkb-zvbc.s": {
        "args": [],
        "script": "crypto/modes/asm/ghash-riscv64-zvkb-zvbc.pl"
    },
    "crypto/modes/ghash-riscv64-zvkg.s": {
        "args": [],
        "script": "crypto/modes/asm/ghash-riscv64-zvkg.pl"
    },
    "crypto/modes/ghash-riscv64.s": {
        "args": [],
        "script": "crypto/modes/asm/ghash-riscv64.pl"
    },
    "crypto/riscv64cpuid.s": {
        "args": [],
        "script": "crypto/riscv64cpuid.pl"
    },
    "crypto/sha/sha256-riscv64-zvkb-zvknha_or_zvknhb.S": {
        "args": [],
        "script": "crypto/sha/asm/sha256-riscv64-zvkb-zvknha_or_zvknhb.pl"
    },
    "crypto/sha/sha512-riscv64-zvkb-zvknhb.S": {
        "args": [],
        "script": "crypto/sha/asm/sha512-riscv64-zvkb-zvknhb.pl"
    },
    "crypto/sm3/sm3-riscv64-zvksh.S": {
        "args": [],
        "script": "crypto/sm3/asm/sm3-riscv64-zvksh.pl"
    },
    "crypto/sm4/sm4-riscv64-zvksed.s": {
        "args": [],
        "script": "crypto/sm4/asm/sm4-riscv64-zvksed.pl"
    }
}

LIBCRYPTO_DEFINES = [
    "-DAES_ASM",
    "-DGHASH_ASM",
    "-DINCLUDE_C_CHACHA20",
    "-DINCLUDE_C_SHA256",
    "-DINCLUDE_C_SHA512",
    "-DOPENSSL_CPUID_OBJ",
    "-DOPENSSL_SM3_ASM",
    "-DSHA256_ASM",
    "-DSHA512_ASM",
    "-DSM4_ASM"
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
