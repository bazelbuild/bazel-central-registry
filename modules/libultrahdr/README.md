# libultrahdr

The Bazel configuration follows upstream `CMakeLists.txt`. The public library
target is `@libultrahdr//:ultrahdr`, with `@libultrahdr` as its alias. It exposes
the C API in `ultrahdr_api.h` and the C++ headers under `ultrahdr/`.

JPEG, HEIF/HEIC and AVIF encoding and decoding are enabled by default. The
HEIF backend uses libheif 1.21.2 with the ISO 21496-1 gain-map API from the
patch shipped by upstream libultrahdr, ported to the current libheif API.
The HEVC and AV1 backends use BCR x265, libde265 and libaom. The libheif x265
adapter accepts 8-bit input with the BCR Main10 encoder. The private patched
libheif must not be linked alongside another libheif implementation.
The HEIF backend brings libheif (LGPLv3) and x265 (GPLv2) dependencies.

| Build flag                             | Default | Function                             |
|----------------------------------------|---------|--------------------------------------|
| `--@libultrahdr//:enable_heif`         | `True`  | HEIF/HEIC and AVIF                   |
| `--@libultrahdr//:enable_intrinsics`   | `True`  | ARM NEON acceleration                |
| `--@libultrahdr//:enable_smpte2094_50` | `False` | SMPTE ST 2094-50 gain-map generation |
| `--@libultrahdr//:enable_logs`         | `False` | Upstream diagnostic logging          |
| `--@libultrahdr//:write_iso`           | `True`  | ISO 21496-1 metadata during encoding |
| `--@libultrahdr//:write_xmp`           | `False` | XMP metadata during encoding         |

Decoding supports both ISO and XMP metadata independently of the write flags.
SMPTE uses the upstream Rust implementation and generated CXX bridges;
`@libultrahdr//:smpte2094_50` also exposes its metadata and interpolation API.
The bridge patch fixes four Span conversions in the upstream C++ adapter.

| Target                             | Function                                            |
|------------------------------------|-----------------------------------------------------|
| `@libultrahdr//:ultrahdr_app`      | Upstream C++ command-line application               |
| `@libultrahdr//:ultrahdr_gpu`      | Library with EGL/OpenGL ES acceleration             |
| `@libultrahdr//:ultrahdr_gpu_app`  | Command-line application with GPU support           |
| `@libultrahdr//:uhdrjni`           | Native Java/JNI library                             |
| `@libultrahdr//:java`              | Java API with the native library bundled in its JAR |
| `@libultrahdr//:ultrahdr_java_app` | Upstream Java command-line application              |

GPU executables require an EGL/OpenGL ES 3 implementation, such as Mesa or
ANGLE. Linux links `EGL` and `GLESv2`; Windows links `EGL.lib` and `GLESv2.lib`.
macOS also needs an EGL/GLES implementation. Supply its library directory
through the consuming toolchain or link options. To use an existing Bazel SDK
target instead of the system libraries, set
`--@libultrahdr//:gles_backend=@my_gpu_sdk//:gles`. The registry header modules
provide headers, while the platform supplies the driver and runtime libraries.
Java loads the bundled JNI library through rules_jni, including from a deploy
JAR; it does not require a manually configured `java.library.path`.
