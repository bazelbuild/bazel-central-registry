# blas and lapack in BCR

## Purpose

The purpose of the `blas` and `lapack` modules in BCR is to provide a single
point of control for choosing the BLAS and/or LAPACK library. These modules
provide a standardized `deps` name to other modules that require BLAS and/or
LAPACK, i.e., `deps = ["@blas"]` and/or `deps = ["@lapack"]`.

By default these modules point to the host OS library (except on Windows, where
there is no default available). Applications that would like to use a different
implementation should set the `@blas//:blas` label flag to the replacment label,
i.e., `--@blas//:blas=@my_other_blas//:target`.

## Capabilities

The required BLAS and/or LAPACK capabilities are left unspecified, i.e., single
vs double precision, real vs complex, 64-bit, CBLAS, LAPACKE, etc. We expect the
downstream application module to make a choice that's compatible with its needs.

## source.json

These modules have no upstream, but source.json requires an upstream URL.
Therefore, we've written a source.json file that contains dummy information
(pointing to a bazel-skylib download).
