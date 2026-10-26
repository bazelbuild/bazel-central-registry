/* Stub config.h for the bazel-native build.
 *
 * All preprocessor macros that the autotools `config.h` would carry are
 * supplied via `-D` flags on the cc_library/cc_binary `defines` and
 * `copts` attributes in BUILD.bazel. This file exists only because many
 * source files include `"config.h"` unconditionally.
 */

#pragma once
