# physx

The [NVIDIA PhysX SDK](https://github.com/NVIDIA-Omniverse/PhysX), from the
`110.1-omni-and-physx-5.9.0` tag — the release that carries PhysX SDK 5.9.0,
which is the version Omniverse Kit 110.1 and Isaac Sim 6.0.0 embed.

Upstream builds with CMake and ships no Bazel files, so `MODULE.bazel` and
`BUILD.bazel` are supplied as an overlay.

## What this provides

`@physx//:physx` is the public API — the headers. `@physx//:physx_schema` is
the PhysX USD schema (`PhysxSceneAPI` and friends), whose generated sources are
checked in upstream. Neither builds the libraries.

That is deliberate rather than unfinished-by-accident: the consumer this was
added for embeds PhysX through a host application (Omniverse Kit) that loads
its own PhysX at run time, so its extensions must compile against the interface
and link against nothing. A second PhysX in the process would be a bug, not a
feature. Compiling the SDK itself is a larger job — CMake-generated
configuration, per-platform SIMD selection — and can be added on top without
changing this target's meaning.

## Version

`5.9.0` is the PhysX SDK version. The tag also encodes the Omniverse PhysX
release it shipped with (110.1); if a later Omniverse release carries the same
SDK version, it belongs in a `5.9.0.bcr.N` rather than a new version.
