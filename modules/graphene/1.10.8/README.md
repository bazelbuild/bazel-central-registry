# Graphene 1.10.8

Link `@graphene` for the native Linux library, including GObject types.
`@graphene//:graphene` requires `@platforms//os:linux`; Windows and clang-cl
are not supported. The generated `src/config.h` assumes pthreads, POSIX
allocation, `sincosf`, and GNU visibility attributes.

The overlay follows upstream `src/meson.build` and generates the version and
platform headers from the release templates. SIMD headers select SSE or NEON
according to the target compiler's architecture macros.
The consumer test exercises vector length and matrix identity operations.
