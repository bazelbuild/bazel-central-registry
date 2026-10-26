# libepoxy 1.5.10

Link `@libepoxy` (or `@libepoxy//:epoxy`) for the native Linux GL, GLX, and EGL
dispatch library. Upstream `gen_dispatch.py` generates dispatch sources from
the release's Khronos XML files on the execution platform. No installed GL
headers or libraries are needed at build time. GPU drivers are loaded with
`dlopen` at runtime; linking this library statically does not embed a driver.
The smoke test links all three public dispatch APIs without opening a display.
