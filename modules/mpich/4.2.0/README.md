# MPICH

This module builds the MPICH 4.2.0 C runtime from its release archive.

The public @mpich//:mpich target supplies C headers and the shared
libmpich.so.12 library. @mpich//:runtime exposes the installed runtime
tree for consumers that load MPICH dynamically rather than linking it.

The build intentionally selects the portable CH3 socket device and omits
Fortran, C++, and process-manager binaries. This keeps the module's
runtime dependency surface small while preserving the MPI C ABI used by
prebuilt consumers such as mpi4py.
