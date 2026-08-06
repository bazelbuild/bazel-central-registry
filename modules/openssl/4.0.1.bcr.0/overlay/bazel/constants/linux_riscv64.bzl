# Generated code. DO NOT EDIT.

ASM_CRYPTO_EXTRA_SRCS = [
    "crypto/aes/aes_cbc.c",
    "crypto/bn/bn_asm.c",
    "crypto/camellia/camellia.c",
    "crypto/camellia/cmll_cbc.c",
    "crypto/chacha/chacha_enc.c",
    "crypto/chacha/chacha_riscv.c",
    "crypto/ec/ecp_sm2p256.c",
    "crypto/ec/ecp_sm2p256_table.c",
    "crypto/md5/md5_riscv.c",
    "crypto/rc4/rc4_enc.c",
    "crypto/rc4/rc4_skey.c",
    "crypto/riscvcap.c",
    "crypto/sha/keccak1600.c",
    "crypto/sha/sha_riscv.c",
    "crypto/sm3/sm3_riscv.c",
    "crypto/whrlpool/wp_block.c"
]

ASM_SSL_EXTRA_SRCS = []

ASM_APP_EXTRA_SRCS = []

PERLASM_GEN = "\n".join([
    "$(PERL) $(execpath crypto/aes/asm/aes-riscv64-zkn.pl) linux64 $(execpath crypto/aes/aes-riscv64-zkn.s);",
    "$(PERL) $(execpath crypto/aes/asm/aes-riscv64-zvbb-zvkg-zvkned.pl) linux64 $(execpath crypto/aes/aes-riscv64-zvbb-zvkg-zvkned.s);",
    "$(PERL) $(execpath crypto/aes/asm/aes-riscv64-zvkb-zvkned.pl) linux64 $(execpath crypto/aes/aes-riscv64-zvkb-zvkned.s);",
    "$(PERL) $(execpath crypto/aes/asm/aes-riscv64-zvkned.pl) linux64 $(execpath crypto/aes/aes-riscv64-zvkned.s);",
    "$(PERL) $(execpath crypto/aes/asm/aes-riscv64.pl) linux64 $(execpath crypto/aes/aes-riscv64.s);",
    "$(PERL) $(execpath crypto/bn/asm/riscv64-mont.pl) linux64 $(execpath crypto/bn/riscv64-mont.S);",
    "$(PERL) $(execpath crypto/chacha/asm/chacha-riscv64-v-zbb.pl) linux64 $(execpath crypto/chacha/chacha-riscv64-v-zbb.s);",
    "$(PERL) $(execpath crypto/chacha/asm/chacha-riscv64-v-zbb.pl) linux64 zvkb $(execpath crypto/chacha/chacha-riscv64-v-zbb-zvkb.s);",
    "$(PERL) $(execpath crypto/ec/asm/ecp_sm2p256-riscv64.pl) linux64 $(execpath crypto/ec/ecp_sm2p256-riscv64.S);",
    "$(PERL) $(execpath crypto/md5/asm/md5-riscv64-zbb.pl) linux64 $(execpath crypto/md5/md5-riscv64.S);",
    "$(PERL) $(execpath crypto/md5/asm/md5-riscv64-zbb.pl) linux64 zbb $(execpath crypto/md5/md5-riscv64-zbb.S);",
    "$(PERL) $(execpath crypto/modes/asm/aes-gcm-riscv64-zvkb-zvkg-zvkned.pl) linux64 $(execpath crypto/modes/aes-gcm-riscv64-zvkb-zvkg-zvkned.s);",
    "$(PERL) $(execpath crypto/modes/asm/ghash-riscv64-zvkb-zvbc.pl) linux64 $(execpath crypto/modes/ghash-riscv64-zvkb-zvbc.s);",
    "$(PERL) $(execpath crypto/modes/asm/ghash-riscv64-zvkg.pl) linux64 $(execpath crypto/modes/ghash-riscv64-zvkg.s);",
    "$(PERL) $(execpath crypto/modes/asm/ghash-riscv64.pl) linux64 $(execpath crypto/modes/ghash-riscv64.s);",
    "$(PERL) $(execpath crypto/riscv64cpuid.pl) linux64 $(execpath crypto/riscv64cpuid.s);",
    "$(PERL) $(execpath crypto/sha/asm/sha256-riscv64-zbb.pl) linux64 $(execpath crypto/sha/sha256-riscv64.S);",
    "$(PERL) $(execpath crypto/sha/asm/sha256-riscv64-zbb.pl) linux64 zbb $(execpath crypto/sha/sha256-riscv64-zbb.S);",
    "$(PERL) $(execpath crypto/sha/asm/sha256-riscv64-zvkb-zvknha_or_zvknhb.pl) linux64 $(execpath crypto/sha/sha256-riscv64-zvkb-zvknha_or_zvknhb.S);",
    "$(PERL) $(execpath crypto/sha/asm/sha512-riscv64-zbb.pl) linux64 $(execpath crypto/sha/sha512-riscv64-zbb.S);",
    "$(PERL) $(execpath crypto/sha/asm/sha512-riscv64-zvkb-zvknhb.pl) linux64 $(execpath crypto/sha/sha512-riscv64-zvkb-zvknhb.S);",
    "$(PERL) $(execpath crypto/sm3/asm/sm3-riscv64-zbb.pl) linux64 $(execpath crypto/sm3/sm3-riscv64-zbb.S);",
    "$(PERL) $(execpath crypto/sm3/asm/sm3-riscv64-zvksh.pl) linux64 $(execpath crypto/sm3/sm3-riscv64-zvksh.S);",
    "$(PERL) $(execpath crypto/sm4/asm/sm4-riscv64-zvksed.pl) linux64 $(execpath crypto/sm4/sm4-riscv64-zvksed.s);"
])

LIBCRYPTO_DEFINES = [
    "-DAES_ASM",
    "-DECP_SM2P256_ASM",
    "-DGHASH_ASM",
    "-DINCLUDE_C_CHACHA20",
    "-DINCLUDE_C_SHA256",
    "-DINCLUDE_C_SHA512",
    "-DMD5_ASM",
    "-DOPENSSL_BN_ASM_MONT",
    "-DOPENSSL_CPUID_OBJ",
    "-DOPENSSL_SM3_ASM",
    "-DSHA256_ASM",
    "-DSHA512_ASM",
    "-DSM4_ASM"
]

LIBSSL_DEFINES = []

OPENSSL_APP_DEFINES = []

OPENSSL_DEFINES = [
    "-DNDEBUG",
    "-DOPENSSL_NO_KTLS",
    "-DOPENSSL_PIC"
]
