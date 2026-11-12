# cnats

The module packages the [NATS C client](https://github.com/nats-io/nats.c)
using native `rules_cc` static and shared libraries on Linux, macOS, and Windows
(MSVC).

Choose an available version from [metadata.json](metadata.json) and replace
`VERSION` below.

```starlark
bazel_dep(name = "cnats", version = "VERSION")
```

Depend on `@cnats` (`@cnats//:cnats`), and include
`<nats/nats.h>`. The public status and version headers are also available under
`nats/`. Internal headers and the deprecated flat `<nats.h>` include are not
part of the public interface.

For dynamic linking, use the shared header target in `deps` and the shared
library in `dynamic_deps`:

```starlark
cc_binary(
    name = "client",
    srcs = ["client.c"],
    deps = ["@cnats//:cnats_shared_headers"],
    dynamic_deps = ["@cnats//:cnats_shared"],
)
```

The shared target produces `libcnats.so`, `libcnats.dylib`, or `cnats.dll`.
Bazel supplies the runtime library to consumers. Windows uses private
`nats_EXPORTS` for the DLL build and propagated `nats_IMPORTS` for its consumers;
the static target retains `NATS_STATIC` and neither DLL definition.
Unix export lists and Windows export declarations restrict the shared library
to the cnats public API, keeping embedded OpenSSL and internal symbols private.
The Unix linker files are checked in; building cnats does not require `awk` or
`sed` to generate them.

The BUILD overlay mirrors the source groups in upstream `src/CMakeLists.txt`:
`src/*.c`, `src/glib/*.c`, and either `src/unix/*.c` or `src/win/*.c`. The
checked-in `src/version.h` supplies version information without code generation.
Platform definitions and system libraries follow the root CMake configuration.

Core NATS, JetStream (including key/value and ObjectStore), and microservices
are included. TLS uses the OpenSSL BCR dependency declared in each version's
`MODULE.bazel`, with hostname verification enabled. Consumers may select a newer
OpenSSL version through normal Bazel module resolution. The shared cnats target embeds
OpenSSL rather than requiring separate OpenSSL shared libraries.
Consumers should call `nats_Open` before standalone message operations and
`nats_CloseAndWait` when finished.

Deprecated NATS Streaming, experimental APIs, optional libsodium, and
libuv/libevent adapter integrations are not enabled. The consumer smoke tests
exercise the public API and TLS configuration using one C consumer with both
static and shared cnats linkage, without a running NATS server.

Source archive URLs and integrity hashes are recorded in each version's
`source.json`. When using GitHub tag-generated archives, a BCR submission
requires the documented URL-stability exception: comment
`@bazel-io skip_check unstable_url` on the pull request. New-module presubmit
configuration also requires BCR maintainer review.
