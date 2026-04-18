cmake_minimum_required(VERSION 3.20...3.29)

project(slang_export_headers)

include(GenerateExportHeader)

# Parts of this file are copied from the slang repo: source/CMakeLists.txt
# Recreated in CMake here to generate the correct headers for the current platform

add_library(
  slang_slang
  STATIC
  PlaceholderSource.cpp
  )

# Set the output name to match what bazel expects
set_target_properties(slang_slang PROPERTIES
  OUTPUT_NAME slang_export_headers
  PREFIX ""
)

# For the generated export header, suppress annoying warnings
# Copied from slang repo
set(suppress_export_warnings
    "
#if defined(_MSC_VER) && !defined(__ICL)
  #pragma warning(disable:4251)
  #pragma warning(disable:4275)
#elif defined(__GNUC__) && !defined(__clang__)
  #pragma GCC diagnostic ignored \"-Wattributes\"
#endif
")

# Generate the export header
# Partially copied from slang repo
generate_export_header(
  slang_slang
  BASE_NAME slang
  EXPORT_FILE_NAME ${CMAKE_CURRENT_BINARY_DIR}/slang/slang_export.h
  CUSTOM_CONTENT_FROM_VARIABLE
  suppress_export_warnings)

# Install the generated header
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/slang/slang_export.h
        DESTINATION include/slang)

# Install the library target
install(TARGETS slang_slang
        EXPORT slang_slang_targets
        ARCHIVE DESTINATION lib
        INCLUDES DESTINATION include)
