LuaJIT 2.1 uses the POSIX timestamp of the source commit as its release
number. This entry uses the timestamp recorded in the source archive and
LuaJIT's version-header generator.

The Linux x86_64 and ARM64 VM generators run on the execution platform.
Select the generator for the target architecture before Bazel builds it.
Consumers can use the exported bytecode saver to embed Lua sources and
package the copyright notice with the VM.

LuaJIT switched x86_64 to GC64 by default after the beta3 release [1].
The Bazel setting follows that default. GC64 uses a different bytecode
format. On Linux x86_64, pass `--@luajit//:gc64=false` to keep the old
frame layout. ARM64 always uses GC64.

[1]: https://github.com/LuaJIT/LuaJIT/commit/bd00094c3b50e193fb32aad79b7ea8ea6b78ed25
