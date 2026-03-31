# Generated code. DO NOT EDIT.

ASM_CRYPTO_EXTRA_SRCS = [
    "crypto/bn/asm/s390x.S",
    "crypto/bn/bn_s390x.c",
    "crypto/camellia/camellia.c",
    "crypto/camellia/cmll_cbc.c",
    "crypto/ec/ecp_s390x_nistp.c",
    "crypto/ec/ecx_s390x.c",
    "crypto/hmac/hmac_s390x.c",
    "crypto/s390xcap.c",
    "crypto/whrlpool/wp_block.c"
]

ASM_SSL_EXTRA_SRCS = []

ASM_APP_EXTRA_SRCS = []

PERLASM_GEN = "\n".join([
    "$(PERL) $(execpath crypto/aes/asm/aes-s390x.pl) 64 $(execpath crypto/aes/aes-s390x.S);",
    "$(PERL) $(execpath crypto/bn/asm/s390x-gf2m.pl) 64 $(execpath crypto/bn/s390x-gf2m.s);",
    "$(PERL) $(execpath crypto/bn/asm/s390x-mont.pl) 64 $(execpath crypto/bn/s390x-mont.S);",
    "$(PERL) $(execpath crypto/chacha/asm/chacha-s390x.pl) 64 $(execpath crypto/chacha/chacha-s390x.S);",
    "$(PERL) $(execpath crypto/modes/asm/ghash-s390x.pl) 64 $(execpath crypto/modes/ghash-s390x.S);",
    "$(PERL) $(execpath crypto/poly1305/asm/poly1305-s390x.pl) 64 $(execpath crypto/poly1305/poly1305-s390x.S);",
    "$(PERL) $(execpath crypto/rc4/asm/rc4-s390x.pl) 64 $(execpath crypto/rc4/rc4-s390x.s);",
    "$(PERL) $(execpath crypto/s390xcpuid.pl) 64 $(execpath crypto/s390xcpuid.S);",
    "$(PERL) $(execpath crypto/sha/asm/keccak1600-s390x.pl) 64 $(execpath crypto/sha/keccak1600-s390x.S);",
    "$(PERL) $(execpath crypto/sha/asm/sha1-s390x.pl) 64 $(execpath crypto/sha/sha1-s390x.S);",
    "$(PERL) $(execpath crypto/sha/asm/sha512-s390x.pl) 64 $(execpath crypto/sha/sha256-s390x.S);",
    "$(PERL) $(execpath crypto/sha/asm/sha512-s390x.pl) 64 $(execpath crypto/sha/sha512-s390x.S);"
])

LIBCRYPTO_DEFINES = [
    "-DAES_ASM",
    "-DAES_CTR_ASM",
    "-DAES_XTS_ASM",
    "-DGHASH_ASM",
    "-DKECCAK1600_ASM",
    "-DOPENSSL_BN_ASM_GF2m",
    "-DOPENSSL_BN_ASM_MONT",
    "-DOPENSSL_CPUID_OBJ",
    "-DOPENSSL_HMAC_S390X",
    "-DPOLY1305_ASM",
    "-DRC4_ASM",
    "-DS390X_EC_ASM",
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
