# Libwebsockets

The BUILD files here are hand crafted Bazel targets migrated from CMake. The only major
difference is in the [CMake configure_file](https://cmake.org/cmake/help/latest/command/configure_file.html) which is
replaced with [rules_cc_autoconf](https://github.com/periareon/rules_cc_autoconf) to accomplish the same checks and outputs.
