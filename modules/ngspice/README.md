# ngspice

ngspice 47 circuit simulation with native Bazel rules. Use it as a library in
your application or run the command-line simulator. XSPICE code models and
OpenMP are enabled by default.

## Usage

Add to `MODULE.bazel`:

```starlark
bazel_dep(name = "ngspice", version = "47")
```

| Target | Purpose |
| --- | --- |
| `@ngspice` | Static API library; include `<ngspice/sharedspice.h>` |
| `@ngspice//:ngspice_bin` | Headless command-line simulator |
| `@ngspice//:runtime` | XSPICE code models and support scripts |

Run a circuit:

```sh
bazel run @ngspice//:ngspice_bin -- -b circuit.cir
```

The CLI loads its bundled code models automatically. User `.spiceinit` files
still apply; `-n` skips initialization, including code-model loading.

Disable XSPICE or OpenMP independently:

```sh
bazel build @ngspice --@ngspice//:xspice=false
bazel build @ngspice --@ngspice//:openmp=false
```

OpenMP parallelizes BSIM3/BSIM4 device evaluation. Set the thread count with
ngspice's `set num_threads=<n>` command. The module uses your C/C++ toolchain.

## Embedding

Add `@ngspice` to your target's `deps`. For XSPICE, also add
`@ngspice//:runtime` to `data`, resolve it through your runfiles library, and
load the models you need after initializing ngspice:

```text
codemodel "<runtime>/lib/ngspice/analog.cm"
```

See the [embedding example](47/overlay/bazel_test/shared_smoke.cc) for startup
configuration, model loading, and the event API.
