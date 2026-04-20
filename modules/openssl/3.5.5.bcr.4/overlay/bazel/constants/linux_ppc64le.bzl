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
    "crypto/whrlpool/wp_block.c"
]

ASM_SSL_EXTRA_SRCS = []

ASM_APP_EXTRA_SRCS = []

PERLASM_GEN = "\n".join([
    "$(PERL) $(execpath crypto/aes/asm/aes-ppc.pl) linux64le $(execpath crypto/aes/aes-ppc.s);",
    "$(PERL) $(execpath crypto/aes/asm/aesp8-ppc.pl) linux64le $(execpath crypto/aes/aesp8-ppc.s);",
    "$(PERL) $(execpath crypto/aes/asm/vpaes-ppc.pl) linux64le $(execpath crypto/aes/vpaes-ppc.s);",
    "$(PERL) $(execpath crypto/bn/asm/ppc-mont.pl) linux64le $(execpath crypto/bn/ppc-mont.s);",
    "$(PERL) $(execpath crypto/bn/asm/ppc.pl) linux64le $(execpath crypto/bn/bn-ppc.s);",
    "$(PERL) $(execpath crypto/bn/asm/ppc64-mont-fixed.pl) linux64le $(execpath crypto/bn/ppc64-mont-fixed.s);",
    "$(PERL) $(execpath crypto/chacha/asm/chacha-ppc.pl) linux64le $(execpath crypto/chacha/chacha-ppc.s);",
    "$(PERL) $(execpath crypto/chacha/asm/chachap10-ppc.pl) linux64le $(execpath crypto/chacha/chachap10-ppc.s);",
    "$(PERL) $(execpath crypto/ec/asm/ecp_nistz256-ppc64.pl) linux64le $(execpath crypto/ec/ecp_nistz256-ppc64.s);",
    "$(PERL) $(execpath crypto/ec/asm/x25519-ppc64.pl) linux64le $(execpath crypto/ec/x25519-ppc64.s);",
    "$(PERL) $(execpath crypto/modes/asm/aes-gcm-ppc.pl) linux64le $(execpath crypto/modes/aes-gcm-ppc.s);",
    "$(PERL) $(execpath crypto/modes/asm/ghashp8-ppc.pl) linux64le $(execpath crypto/modes/ghashp8-ppc.s);",
    "$(PERL) $(execpath crypto/poly1305/asm/poly1305-ppc.pl) linux64le $(execpath crypto/poly1305/poly1305-ppc.s);",
    "$(PERL) $(execpath crypto/poly1305/asm/poly1305-ppcfp.pl) linux64le $(execpath crypto/poly1305/poly1305-ppcfp.s);",
    "$(PERL) $(execpath crypto/ppccpuid.pl) linux64le $(execpath crypto/ppccpuid.s);",
    "$(PERL) $(execpath crypto/sha/asm/keccak1600-ppc64.pl) linux64le $(execpath crypto/sha/keccak1600-ppc64.s);",
    "$(PERL) $(execpath crypto/sha/asm/sha1-ppc.pl) linux64le $(execpath crypto/sha/sha1-ppc.s);",
    "$(PERL) $(execpath crypto/sha/asm/sha512-ppc.pl) linux64le $(execpath crypto/sha/sha256-ppc.s);",
    "$(PERL) $(execpath crypto/sha/asm/sha512-ppc.pl) linux64le $(execpath crypto/sha/sha512-ppc.s);",
    "$(PERL) $(execpath crypto/sha/asm/sha512p8-ppc.pl) linux64le $(execpath crypto/sha/sha256p8-ppc.s);",
    "$(PERL) $(execpath crypto/sha/asm/sha512p8-ppc.pl) linux64le $(execpath crypto/sha/sha512p8-ppc.s);"
])

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

OPENSSL_APP_DEFINES = []

OPENSSL_DEFINES = [
    "-DNDEBUG",
    "-DOPENSSL_BUILDING_OPENSSL",
    "-DOPENSSL_NO_KTLS",
    "-DOPENSSL_PIC"
]
