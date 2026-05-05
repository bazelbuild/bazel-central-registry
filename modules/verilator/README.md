# Verilator

Bazel module for [Verilator](https://verilator.org), the open-source Verilog/SystemVerilog
simulator and lint system.

Each version is hand-crafted based on the configure + Makefiles.

## Scope

This module builds the Verilator **compiler tooling** -- the binaries that translate
Verilog/SystemVerilog into C++ source code. It also provides the `verilated` C++ runtime
library for linking generated simulations.

This module does **not** replicate the full upstream `configure`/`make install` workflow.
In particular, `verilator --build` (which shells out to `make` using a generated
`verilated.mk`) is not supported. Compiling the generated C++ is left to consumers
to implement using Bazel's own `cc_library`/`cc_binary` rules or similar.

If any files needed for your workflow are not exposed, please open a pull request.
