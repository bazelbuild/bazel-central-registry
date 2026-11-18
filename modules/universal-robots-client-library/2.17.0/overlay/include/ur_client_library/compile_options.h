#pragma once

namespace urcl
{
// Compile-time configuration options for the UR client library.
// Bazel does not run CMake's `configure_file`, so this overlay provides the
// static header that `PrimaryClient` requires instead of `src/compile_options.h.in`.
struct CompileOptions
{
  // Configures the PrimaryParser strict mode.
  // Set to false so unrecognized or newly added fields in newer robot
  // controller firmware log a warning instead of throwing an exception.
  constexpr static bool PRIMARY_CLIENT_STRICT_PARSING = false;
};

inline constexpr CompileOptions COMPILE_OPTIONS;
}  // namespace urcl
