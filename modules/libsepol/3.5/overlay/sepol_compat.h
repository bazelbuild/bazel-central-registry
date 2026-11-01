/* Force-included when building libsepol (see BUILD.bazel). */
#include <stdlib.h>

/*
 * Upstream defines a static reallocarray() fallback unless HAVE_REALLOCARRAY
 * is set, which clashes with glibc >= 2.26's declaration. Renaming it after
 * stdlib.h is included works on any libc version.
 */
#define reallocarray sepol_reallocarray
