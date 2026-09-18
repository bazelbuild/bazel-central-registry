#include <mpi.h>
#include <stddef.h>

int main(void) {
    int initialized = 0;
    int rank = -1;

    if (MPI_Init(NULL, NULL) != MPI_SUCCESS) {
        return 1;
    }
    if (MPI_Initialized(&initialized) != MPI_SUCCESS || !initialized) {
        return 2;
    }
    if (MPI_Comm_rank(MPI_COMM_WORLD, &rank) != MPI_SUCCESS || rank != 0) {
        return 3;
    }
    return MPI_Finalize() == MPI_SUCCESS ? 0 : 4;
}
