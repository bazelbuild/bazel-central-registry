# libXdamage 1.1.6

Link `@libxdamage` (or `@libxdamage//:xdamage`) for the native X Damage extension
client library. The overlay follows `src/Makefile.am` and uses BCR's X11,
Xfixes, and protocol headers. The smoke test links the extension-query and
damage-creation APIs without requiring a running X server.
