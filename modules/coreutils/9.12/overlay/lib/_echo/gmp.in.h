/* gmp.h, as lib/gnulib.mk writes it: generated under GL_GENERATE_GMP_H, the variant chosen
   by the conditionals each rule is under (substituted as the words true / false). */
#define _gl_echo_true 1
#define _gl_echo_false 0
#if _gl_echo_@GL_GENERATE_MINI_GMP_H@
#include "mini-gmp.h"
#if GNULIB_LIBGMP_MPQ
# include "mini-mpq.h"
#endif
#endif
#if _gl_echo_@GL_GENERATE_GMP_GMP_H@
#include <gmp/gmp.h>
#endif
#undef _gl_echo_true
#undef _gl_echo_false
