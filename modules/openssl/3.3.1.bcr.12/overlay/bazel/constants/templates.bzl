# Generated code. DO NOT EDIT.
#
# Build-time generated files, extracted from configdata.pm:
#   util/dofile.pl templates (template -> output), and
#   scripts that write a file to stdout (output -> script, args, deps; e.g.
#   util/mkerr.pl and crypto/objects/objects.pl on OpenSSL 4.1+), in
#   dependency order. $(SRCDIR)/ marks a source file argument, $(BLDDIR)/
#   another generated file.
# HERMETIC_ENV is the environment every generator runs with.

DOFILE_HDR_TEMPLATES = {
    "include/crypto/bn_conf.h.in": "include/crypto/bn_conf.h",
    "include/crypto/dso_conf.h.in": "include/crypto/dso_conf.h",
    "include/internal/param_names.h.in": "include/internal/param_names.h",
    "include/openssl/asn1.h.in": "include/openssl/asn1.h",
    "include/openssl/asn1t.h.in": "include/openssl/asn1t.h",
    "include/openssl/bio.h.in": "include/openssl/bio.h",
    "include/openssl/cmp.h.in": "include/openssl/cmp.h",
    "include/openssl/cms.h.in": "include/openssl/cms.h",
    "include/openssl/conf.h.in": "include/openssl/conf.h",
    "include/openssl/configuration.h.in": "include/openssl/configuration.h",
    "include/openssl/core_names.h.in": "include/openssl/core_names.h",
    "include/openssl/crmf.h.in": "include/openssl/crmf.h",
    "include/openssl/crypto.h.in": "include/openssl/crypto.h",
    "include/openssl/ct.h.in": "include/openssl/ct.h",
    "include/openssl/err.h.in": "include/openssl/err.h",
    "include/openssl/ess.h.in": "include/openssl/ess.h",
    "include/openssl/fipskey.h.in": "include/openssl/fipskey.h",
    "include/openssl/lhash.h.in": "include/openssl/lhash.h",
    "include/openssl/ocsp.h.in": "include/openssl/ocsp.h",
    "include/openssl/opensslv.h.in": "include/openssl/opensslv.h",
    "include/openssl/pkcs12.h.in": "include/openssl/pkcs12.h",
    "include/openssl/pkcs7.h.in": "include/openssl/pkcs7.h",
    "include/openssl/safestack.h.in": "include/openssl/safestack.h",
    "include/openssl/srp.h.in": "include/openssl/srp.h",
    "include/openssl/ssl.h.in": "include/openssl/ssl.h",
    "include/openssl/ui.h.in": "include/openssl/ui.h",
    "include/openssl/x509.h.in": "include/openssl/x509.h",
    "include/openssl/x509_vfy.h.in": "include/openssl/x509_vfy.h",
    "include/openssl/x509v3.h.in": "include/openssl/x509v3.h",
    "providers/common/include/prov/der_digests.h.in": "providers/common/include/prov/der_digests.h",
    "providers/common/include/prov/der_dsa.h.in": "providers/common/include/prov/der_dsa.h",
    "providers/common/include/prov/der_ec.h.in": "providers/common/include/prov/der_ec.h",
    "providers/common/include/prov/der_ecx.h.in": "providers/common/include/prov/der_ecx.h",
    "providers/common/include/prov/der_rsa.h.in": "providers/common/include/prov/der_rsa.h",
    "providers/common/include/prov/der_sm2.h.in": "providers/common/include/prov/der_sm2.h",
    "providers/common/include/prov/der_wrap.h.in": "providers/common/include/prov/der_wrap.h"
}

DOFILE_SRC_TEMPLATES = {
    "crypto/params_idx.c.in": "crypto/params_idx.c",
    "providers/common/der/der_digests_gen.c.in": "providers/common/der/der_digests_gen.c",
    "providers/common/der/der_dsa_gen.c.in": "providers/common/der/der_dsa_gen.c",
    "providers/common/der/der_ec_gen.c.in": "providers/common/der/der_ec_gen.c",
    "providers/common/der/der_ecx_gen.c.in": "providers/common/der/der_ecx_gen.c",
    "providers/common/der/der_rsa_gen.c.in": "providers/common/der/der_rsa_gen.c",
    "providers/common/der/der_sm2_gen.c.in": "providers/common/der/der_sm2_gen.c",
    "providers/common/der/der_wrap_gen.c.in": "providers/common/der/der_wrap_gen.c"
}

STDOUT_SCRIPTS = {}

HERMETIC_ENV = {
    "SOURCE_DATE_EPOCH": "443779200",
    "OSSL_COPYRIGHT_YEAR": "1984"
}
