#include <assert.h>
#include <clarabel.h>
#include <stdio.h>

int main(void) {
  ClarabelCscMatrix P;
  clarabel_CscMatrix_init(&P, 2, 2, (uintptr_t[]){0, 1, 2}, (uintptr_t[]){0, 1},
                          (ClarabelFloat[]){6., 4.});

  ClarabelFloat q[2] = {-1., -4.};

  ClarabelCscMatrix A;
  clarabel_CscMatrix_init(&A, 5, 2, (uintptr_t[]){0, 3, 6},
                          (uintptr_t[]){0, 1, 3, 0, 2, 4},
                          (ClarabelFloat[]){1., 1., -1., -2., 1., -1.});

  ClarabelFloat b[5] = {0., 1., 1., 1., 1.};
  ClarabelSupportedConeT cones[2] = {ClarabelZeroConeT(1),
                                     ClarabelNonnegativeConeT(4)};

  ClarabelDefaultSettings settings = clarabel_DefaultSettings_default();
  settings.verbose = false;

  ClarabelDefaultSolver *solver =
      clarabel_DefaultSolver_new(&P, q, &A, b, 2, cones, &settings);
  assert(solver != NULL);

  clarabel_DefaultSolver_solve(solver);

  ClarabelDefaultSolution solution = clarabel_DefaultSolver_solution(solver);
  assert(solution.status == ClarabelSolved);
  printf("C solver status = %d (Solved), obj_val = %f\n", solution.status,
         solution.obj_val);

  clarabel_DefaultSolver_free(solver);
  return 0;
}
