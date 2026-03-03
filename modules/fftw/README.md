# FFTW

## Overview
This module is a community-maintained alternative build system for FFTW, translated
from the official GNU Autotools build system.

## Targets
This module exposes `:fftw_double` and `:fftw_float`. For convenience, there is also
the `:fftw` target that provides both `double` and `float` interfaces.

## Benchmarking
This module also exposes `:bench_double` and `:bench_float`, which you can use to
validate or benchmark FFTW on your platform.
