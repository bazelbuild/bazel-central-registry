# Graphene 1.10.8

Link `@graphene` for the native Linux library, including GObject types.
The overlay follows upstream `src/meson.build` and generates the version and
platform headers from the release templates. SIMD headers select SSE or NEON
according to the target compiler's architecture macros.
The consumer test exercises vector length and matrix identity operations.
