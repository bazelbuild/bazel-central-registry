#include "cblas.h"
#include "lapacke.h"
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

int main(void) {
    printf("Testing OpenBLAS native build with BLAS and LAPACK...\n");

    // 1. Test CBLAS dgemm
    double A[4] = {1.0, 2.0, 3.0, 4.0};
    double B[4] = {5.0, 6.0, 7.0, 8.0};
    double C[4] = {0.0, 0.0, 0.0, 0.0};

    cblas_dgemm(CblasRowMajor, CblasNoTrans, CblasNoTrans,
                2, 2, 2, 1.0, A, 2, B, 2, 0.0, C, 2);

    if (fabs(C[0] - 19.0) > 1e-6 || fabs(C[1] - 22.0) > 1e-6 ||
        fabs(C[2] - 43.0) > 1e-6 || fabs(C[3] - 50.0) > 1e-6) {
        fprintf(stderr, "CBLAS dgemm test failed: C = [%f, %f; %f, %f]\n",
                C[0], C[1], C[2], C[3]);
        return 1;
    }
    printf("CBLAS dgemm test passed!\n");

    // 2. Test LAPACK dgesv (using standard LAPACK signature from lapack.h)
    // Solve: [2 1; 1 2] * x = [3; 3] -> solution x = [1; 1]
    lapack_int n = 2;
    lapack_int nrhs = 1;
    double M[4] = {2.0, 1.0, 1.0, 2.0};
    lapack_int lda = 2;
    lapack_int ipiv[2];
    double b[2] = {3.0, 3.0};
    lapack_int ldb = 2;
    lapack_int info = 0;

    LAPACK_dgesv(&n, &nrhs, M, &lda, ipiv, b, &ldb, &info);
    if (info != 0 || fabs(b[0] - 1.0) > 1e-6 || fabs(b[1] - 1.0) > 1e-6) {
        fprintf(stderr, "LAPACK dgesv_ test failed: info=%d, b = [%f, %f]\n",
                info, b[0], b[1]);
        return 1;
    }
    printf("LAPACK dgesv_ test passed!\n");

    // 3. Test LAPACKE C interface
    double M2[4] = {2.0, 1.0, 1.0, 2.0};
    double b2[2] = {3.0, 3.0};
    info = LAPACKE_dgesv(LAPACK_ROW_MAJOR, 2, 1, M2, 2, ipiv, b2, 1);
    if (info != 0 || fabs(b2[0] - 1.0) > 1e-6 || fabs(b2[1] - 1.0) > 1e-6) {
        fprintf(stderr, "LAPACKE_dgesv test failed: info=%d, b2 = [%f, %f]\n",
                info, b2[0], b2[1]);
        return 1;
    }
    printf("LAPACKE_dgesv test passed!\n");

    printf("All OpenBLAS tests passed successfully!\n");
    return 0;
}
