/* Generated from libcrypt.map.in by gen-crypt-symbol-vers-h.  DO NOT EDIT.  */

#ifndef _CRYPT_SYMBOL_VERS_H
#define _CRYPT_SYMBOL_VERS_H 1

/* For each public symbol <sym>, INCLUDE_<sym> is true if it
   has any versions above the backward compatibility minimum.
   Compatibility-only symbols are not included in the static
   library, or in the shared library when configured with
   --disable-obsolete-api.  */
#if defined PIC && ENABLE_OBSOLETE_API

#define INCLUDE_crypt                  1
#define INCLUDE_crypt_checksalt        1
#define INCLUDE_crypt_gensalt          1
#define INCLUDE_crypt_gensalt_r        1
#define INCLUDE_crypt_gensalt_ra       1
#define INCLUDE_crypt_gensalt_rn       1
#define INCLUDE_crypt_preferred_method 1
#define INCLUDE_crypt_r                1
#define INCLUDE_crypt_ra               1
#define INCLUDE_crypt_rn               1
#define INCLUDE_encrypt                0
#define INCLUDE_encrypt_r              0
#define INCLUDE_fcrypt                 0
#define INCLUDE_setkey                 0
#define INCLUDE_setkey_r               0
#define INCLUDE_xcrypt                 1
#define INCLUDE_xcrypt_gensalt         1
#define INCLUDE_xcrypt_gensalt_r       1
#define INCLUDE_xcrypt_r               1

#else

#define INCLUDE_crypt                  1
#define INCLUDE_crypt_checksalt        1
#define INCLUDE_crypt_gensalt          1
#define INCLUDE_crypt_gensalt_r        0
#define INCLUDE_crypt_gensalt_ra       1
#define INCLUDE_crypt_gensalt_rn       1
#define INCLUDE_crypt_preferred_method 1
#define INCLUDE_crypt_r                1
#define INCLUDE_crypt_ra               1
#define INCLUDE_crypt_rn               1
#define INCLUDE_encrypt                0
#define INCLUDE_encrypt_r              0
#define INCLUDE_fcrypt                 0
#define INCLUDE_setkey                 0
#define INCLUDE_setkey_r               0
#define INCLUDE_xcrypt                 0
#define INCLUDE_xcrypt_gensalt         0
#define INCLUDE_xcrypt_gensalt_r       0
#define INCLUDE_xcrypt_r               0

#endif

/* When the public symbols are being given versions, they must be
   defined under a different, private name first.  */
#ifdef PIC
#define crypt                  _crypt_crypt
#define crypt_checksalt        _crypt_crypt_checksalt
#define crypt_gensalt          _crypt_crypt_gensalt
#define crypt_gensalt_r        _crypt_crypt_gensalt_r
#define crypt_gensalt_ra       _crypt_crypt_gensalt_ra
#define crypt_gensalt_rn       _crypt_crypt_gensalt_rn
#define crypt_preferred_method _crypt_crypt_preferred_method
#define crypt_r                _crypt_crypt_r
#define crypt_ra               _crypt_crypt_ra
#define crypt_rn               _crypt_crypt_rn
#define xcrypt                 _crypt_xcrypt
#define xcrypt_gensalt         _crypt_xcrypt_gensalt
#define xcrypt_gensalt_r       _crypt_xcrypt_gensalt_r
#define xcrypt_r               _crypt_xcrypt_r
#endif

/* For each public symbol <sym> that is included, define its
   highest version as the default, and aliases at each
   compatibility version. */
#define SYMVER_crypt \
  symver_default ("crypt", crypt, XCRYPT_2.0)
#define SYMVER_crypt_checksalt \
  symver_default ("crypt_checksalt", crypt_checksalt, XCRYPT_4.3)
#define SYMVER_crypt_gensalt \
  symver_default ("crypt_gensalt", crypt_gensalt, XCRYPT_2.0)
#define SYMVER_crypt_gensalt_r \
  symver_compat0 ("crypt_gensalt_r", crypt_gensalt_r, XCRYPT_2.0)
#define SYMVER_crypt_gensalt_ra \
  symver_default ("crypt_gensalt_ra", crypt_gensalt_ra, XCRYPT_2.0)
#define SYMVER_crypt_gensalt_rn \
  symver_default ("crypt_gensalt_rn", crypt_gensalt_rn, XCRYPT_2.0)
#define SYMVER_crypt_preferred_method \
  symver_default ("crypt_preferred_method", crypt_preferred_method, XCRYPT_4.4)
#define SYMVER_crypt_r \
  symver_default ("crypt_r", crypt_r, XCRYPT_2.0)
#define SYMVER_crypt_ra \
  symver_default ("crypt_ra", crypt_ra, XCRYPT_2.0)
#define SYMVER_crypt_rn \
  symver_default ("crypt_rn", crypt_rn, XCRYPT_2.0)
#define SYMVER_encrypt symver_nop()
#define SYMVER_encrypt_r symver_nop()
#define SYMVER_fcrypt symver_nop()
#define SYMVER_setkey symver_nop()
#define SYMVER_setkey_r symver_nop()
#define SYMVER_xcrypt \
  symver_compat0 ("xcrypt", xcrypt, XCRYPT_2.0)
#define SYMVER_xcrypt_gensalt \
  symver_compat0 ("xcrypt_gensalt", xcrypt_gensalt, XCRYPT_2.0)
#define SYMVER_xcrypt_gensalt_r \
  symver_compat0 ("xcrypt_gensalt_r", xcrypt_gensalt_r, XCRYPT_2.0)
#define SYMVER_xcrypt_r \
  symver_compat0 ("xcrypt_r", xcrypt_r, XCRYPT_2.0)

#endif /* crypt-symbol-vers.h */
