#include <mpc.h>

int main(void) {
  mpc_t z;
  mpc_t result;
  int ok;

  mpc_init2(z, 128);
  mpc_init2(result, 128);
  mpc_set_ui_ui(z, 1, 1, MPC_RNDNN);
  mpc_mul(result, z, z, MPC_RNDNN);
  ok = mpfr_zero_p(mpc_realref(result)) && mpfr_cmp_ui(mpc_imagref(result), 2) == 0;
  mpc_clear(result);
  mpc_clear(z);

  return ok ? 0 : 1;
}
