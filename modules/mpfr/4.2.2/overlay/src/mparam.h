/* Various Thresholds of MPFR, not exported.  -*- mode: C -*- */

#ifndef MPFR_TUNE_CASE
# define MPFR_TUNE_CASE "default"
#endif

#ifndef MPFR_MULHIGH_TAB
# define MPFR_MULHIGH_TAB -1,-1,-1,-1,-1,-1,-1,-1,0,0,0,0,0,0,0,0,0
#endif

#ifndef MPFR_SQRHIGH_TAB
# define MPFR_SQRHIGH_TAB -1,-1,-1,-1,-1,-1,-1,-1,0,0,0,0,0,0,0,0,0
#endif

#ifndef MPFR_DIVHIGH_TAB
# define MPFR_DIVHIGH_TAB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
#endif

#ifndef MPFR_MUL_THRESHOLD
# define MPFR_MUL_THRESHOLD 20
#endif

#ifndef MPFR_SQR_THRESHOLD
# define MPFR_SQR_THRESHOLD 20
#endif

#ifndef MPFR_DIV_THRESHOLD
# define MPFR_DIV_THRESHOLD 25
#endif

#ifndef MPFR_EXP_2_THRESHOLD
# define MPFR_EXP_2_THRESHOLD 100
#endif

#ifndef MPFR_EXP_THRESHOLD
# define MPFR_EXP_THRESHOLD 25000
#endif

#ifndef MPFR_SINCOS_THRESHOLD
# define MPFR_SINCOS_THRESHOLD 30000
#endif

#ifndef MPFR_AI_THRESHOLD1
# define MPFR_AI_THRESHOLD1 -13107
#endif

#ifndef MPFR_AI_THRESHOLD2
# define MPFR_AI_THRESHOLD2 1311
#endif

#ifndef MPFR_AI_THRESHOLD3
# define MPFR_AI_THRESHOLD3 19661
#endif
