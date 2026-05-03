#include <mpfr.h>

int main(void) {
  mpfr_t value;
  int ok;

  mpfr_init2(value, 128);
  mpfr_set_ui(value, 2, MPFR_RNDN);
  mpfr_sqrt(value, value, MPFR_RNDN);
  ok = mpfr_cmp_ui(value, 1) > 0 && mpfr_cmp_ui(value, 2) < 0;
  mpfr_clear(value);

  return ok ? 0 : 1;
}
