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
    "crypto/whrlpool/wp_block.c"
]

ASM_SSL_EXTRA_SRCS = []

ASM_APP_EXTRA_SRCS = []

PERLASM_GEN = "\n".join([
    "$(PERL) $(execpath crypto/aes/asm/aes-armv4.pl) linux32 $(execpath crypto/aes/aes-armv4.S);",
    "$(PERL) $(execpath crypto/aes/asm/aesv8-armx.pl) linux32 $(execpath crypto/aes/aesv8-armx.S);",
    "$(PERL) $(execpath crypto/aes/asm/bsaes-armv7.pl) linux32 $(execpath crypto/aes/bsaes-armv7.S);",
    "$(PERL) $(execpath crypto/armv4cpuid.pl) linux32 $(execpath crypto/armv4cpuid.S);",
    "$(PERL) $(execpath crypto/bn/asm/armv4-gf2m.pl) linux32 $(execpath crypto/bn/armv4-gf2m.S);",
    "$(PERL) $(execpath crypto/bn/asm/armv4-mont.pl) linux32 $(execpath crypto/bn/armv4-mont.S);",
    "$(PERL) $(execpath crypto/chacha/asm/chacha-armv4.pl) linux32 $(execpath crypto/chacha/chacha-armv4.S);",
    "$(PERL) $(execpath crypto/ec/asm/ecp_nistz256-armv4.pl) linux32 $(execpath crypto/ec/ecp_nistz256-armv4.S);",
    "$(PERL) $(execpath crypto/modes/asm/ghash-armv4.pl) linux32 $(execpath crypto/modes/ghash-armv4.S);",
    "$(PERL) $(execpath crypto/modes/asm/ghashv8-armx.pl) linux32 $(execpath crypto/modes/ghashv8-armx.S);",
    "$(PERL) $(execpath crypto/poly1305/asm/poly1305-armv4.pl) linux32 $(execpath crypto/poly1305/poly1305-armv4.S);",
    "$(PERL) $(execpath crypto/sha/asm/keccak1600-armv4.pl) linux32 $(execpath crypto/sha/keccak1600-armv4.S);",
    "$(PERL) $(execpath crypto/sha/asm/sha1-armv4-large.pl) linux32 $(execpath crypto/sha/sha1-armv4-large.S);",
    "$(PERL) $(execpath crypto/sha/asm/sha256-armv4.pl) linux32 $(execpath crypto/sha/sha256-armv4.S);",
    "$(PERL) $(execpath crypto/sha/asm/sha512-armv4.pl) linux32 $(execpath crypto/sha/sha512-armv4.S);"
])

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

OPENSSL_APP_DEFINES = []

OPENSSL_DEFINES = [
    "-DNDEBUG",
    "-DOPENSSL_BUILDING_OPENSSL",
    "-DOPENSSL_NO_KTLS",
    "-DOPENSSL_PIC"
]
