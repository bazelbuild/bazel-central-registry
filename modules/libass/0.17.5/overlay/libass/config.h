/* Hand-written replacement for the meson/autoconf generated config.h.
 * Only platform-independent settings live here; platform- and
 * architecture-dependent macros (CONFIG_FONTCONFIG, CONFIG_CORETEXT,
 * CONFIG_ASM, ARCH_*) are passed via local_defines in BUILD.bazel. */

#define CONFIG_ICONV 1
#define CONFIG_LARGE_TILES 0
#define CONFIG_SOURCEVERSION "bazel, release 0.17.5"
#define CONFIG_UNIBREAK 1

#define HAVE_FSTAT 1
#define HAVE_STRDUP 1
#define HAVE_STRNDUP 1
