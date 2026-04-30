# Generated code. DO NOT EDIT.

ASM_CRYPTO_EXTRA_SRCS = [
    "crypto/bn/asm/x86_64-gcc.c",
    "crypto/bn/rsaz_exp.c",
    "crypto/bn/rsaz_exp_x2.c",
    "crypto/ec/ecp_nistz256.c"
]

ASM_SSL_EXTRA_SRCS = []

ASM_APP_EXTRA_SRCS = []

PERLASM_GEN = "\n".join([
    "$(PERL) $(execpath crypto/aes/asm/aes-x86_64.pl) elf $(execpath crypto/aes/aes-x86_64.s);",
    "$(PERL) $(execpath crypto/aes/asm/aesni-mb-x86_64.pl) elf $(execpath crypto/aes/aesni-mb-x86_64.s);",
    "$(PERL) $(execpath crypto/aes/asm/aesni-sha1-x86_64.pl) elf $(execpath crypto/aes/aesni-sha1-x86_64.s);",
    "$(PERL) $(execpath crypto/aes/asm/aesni-sha256-x86_64.pl) elf $(execpath crypto/aes/aesni-sha256-x86_64.s);",
    "$(PERL) $(execpath crypto/aes/asm/aesni-x86_64.pl) elf $(execpath crypto/aes/aesni-x86_64.s);",
    "$(PERL) $(execpath crypto/aes/asm/aesni-xts-avx512.pl) elf $(execpath crypto/aes/aesni-xts-avx512.s);",
    "$(PERL) $(execpath crypto/aes/asm/bsaes-x86_64.pl) elf $(execpath crypto/aes/bsaes-x86_64.s);",
    "$(PERL) $(execpath crypto/aes/asm/vpaes-x86_64.pl) elf $(execpath crypto/aes/vpaes-x86_64.s);",
    "$(PERL) $(execpath crypto/bn/asm/rsaz-2k-avx512.pl) elf $(execpath crypto/bn/rsaz-2k-avx512.s);",
    "$(PERL) $(execpath crypto/bn/asm/rsaz-2k-avxifma.pl) elf $(execpath crypto/bn/rsaz-2k-avxifma.s);",
    "$(PERL) $(execpath crypto/bn/asm/rsaz-3k-avx512.pl) elf $(execpath crypto/bn/rsaz-3k-avx512.s);",
    "$(PERL) $(execpath crypto/bn/asm/rsaz-3k-avxifma.pl) elf $(execpath crypto/bn/rsaz-3k-avxifma.s);",
    "$(PERL) $(execpath crypto/bn/asm/rsaz-4k-avx512.pl) elf $(execpath crypto/bn/rsaz-4k-avx512.s);",
    "$(PERL) $(execpath crypto/bn/asm/rsaz-4k-avxifma.pl) elf $(execpath crypto/bn/rsaz-4k-avxifma.s);",
    "$(PERL) $(execpath crypto/bn/asm/rsaz-avx2.pl) elf $(execpath crypto/bn/rsaz-avx2.s);",
    "$(PERL) $(execpath crypto/bn/asm/rsaz-x86_64.pl) elf $(execpath crypto/bn/rsaz-x86_64.s);",
    "$(PERL) $(execpath crypto/bn/asm/x86_64-gf2m.pl) elf $(execpath crypto/bn/x86_64-gf2m.s);",
    "$(PERL) $(execpath crypto/bn/asm/x86_64-mont.pl) elf $(execpath crypto/bn/x86_64-mont.s);",
    "$(PERL) $(execpath crypto/bn/asm/x86_64-mont5.pl) elf $(execpath crypto/bn/x86_64-mont5.s);",
    "$(PERL) $(execpath crypto/camellia/asm/cmll-x86_64.pl) elf $(execpath crypto/camellia/cmll-x86_64.s);",
    "$(PERL) $(execpath crypto/chacha/asm/chacha-x86_64.pl) elf $(execpath crypto/chacha/chacha-x86_64.s);",
    "$(PERL) $(execpath crypto/ec/asm/ecp_nistz256-x86_64.pl) elf $(execpath crypto/ec/ecp_nistz256-x86_64.s);",
    "$(PERL) $(execpath crypto/ec/asm/x25519-x86_64.pl) elf $(execpath crypto/ec/x25519-x86_64.s);",
    "$(PERL) $(execpath crypto/md5/asm/md5-x86_64.pl) elf $(execpath crypto/md5/md5-x86_64.s);",
    "$(PERL) $(execpath crypto/modes/asm/aes-gcm-avx512.pl) elf $(execpath crypto/modes/aes-gcm-avx512.s);",
    "$(PERL) $(execpath crypto/modes/asm/aesni-gcm-x86_64.pl) elf $(execpath crypto/modes/aesni-gcm-x86_64.s);",
    "$(PERL) $(execpath crypto/modes/asm/ghash-x86_64.pl) elf $(execpath crypto/modes/ghash-x86_64.s);",
    "$(PERL) $(execpath crypto/poly1305/asm/poly1305-x86_64.pl) elf $(execpath crypto/poly1305/poly1305-x86_64.s);",
    "$(PERL) $(execpath crypto/rc4/asm/rc4-md5-x86_64.pl) elf $(execpath crypto/rc4/rc4-md5-x86_64.s);",
    "$(PERL) $(execpath crypto/rc4/asm/rc4-x86_64.pl) elf $(execpath crypto/rc4/rc4-x86_64.s);",
    "$(PERL) $(execpath crypto/sha/asm/keccak1600-x86_64.pl) elf $(execpath crypto/sha/keccak1600-x86_64.s);",
    "$(PERL) $(execpath crypto/sha/asm/sha1-mb-x86_64.pl) elf $(execpath crypto/sha/sha1-mb-x86_64.s);",
    "$(PERL) $(execpath crypto/sha/asm/sha1-x86_64.pl) elf $(execpath crypto/sha/sha1-x86_64.s);",
    "$(PERL) $(execpath crypto/sha/asm/sha256-mb-x86_64.pl) elf $(execpath crypto/sha/sha256-mb-x86_64.s);",
    "$(PERL) $(execpath crypto/sha/asm/sha512-x86_64.pl) elf $(execpath crypto/sha/sha256-x86_64.s);",
    "$(PERL) $(execpath crypto/sha/asm/sha512-x86_64.pl) elf $(execpath crypto/sha/sha512-x86_64.s);",
    "$(PERL) $(execpath crypto/whrlpool/asm/wp-x86_64.pl) elf $(execpath crypto/whrlpool/wp-x86_64.s);",
    "$(PERL) $(execpath crypto/x86_64cpuid.pl) elf $(execpath crypto/x86_64cpuid.s);",
    "$(PERL) $(execpath engines/asm/e_padlock-x86_64.pl) elf $(execpath engines/e_padlock-x86_64.s);"
])

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
    "-DPADLOCK_ASM",
    "-DPOLY1305_ASM",
    "-DRC4_ASM",
    "-DSHA1_ASM",
    "-DSHA256_ASM",
    "-DSHA512_ASM",
    "-DVPAES_ASM",
    "-DWHIRLPOOL_ASM",
    "-DX25519_ASM"
]

LIBSSL_DEFINES = [
    "-DAES_ASM"
]

OPENSSL_APP_DEFINES = []

OPENSSL_DEFINES = [
    "-DNDEBUG",
    "-DOPENSSL_BUILDING_OPENSSL",
    "-DOPENSSL_NO_KTLS",
    "-DOPENSSL_PIC"
]
