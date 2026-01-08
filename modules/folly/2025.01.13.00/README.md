## Notes on bazelifying a folly release

First clone the folly repository from https://github.com/facebook/folly

Cd into the folly source and checkout the release branch that you would like to bazelify.

First, create a BUILD.bazel file for every BUCK file in the repo.

Use our cpp_library macro written for bazel instead of the folly cpp_library macro:

```bash
find . -name BUILD.bazel | xargs sed -i -e 's;load("@fbcode_macros//build_defs:cpp_library.bzl", "cpp_library");load("//bzl:cpp_library.bzl", "cpp_library");g'
```

Add any custom bzl files under a directory called `//bzl` in the folly source tree.

After creating BUILD.bazel files, they can be copied here using the sync_overlay_build_files.sh helper script:

```bash
./sync_bazel_files.sh /path/to/folly
```

Then you can update the hashes in sources.json with the following command.

NOTE: This must be run from the root of the bazel-central-registry workspace:

```bash
python3 ./tools/update_integrity.py folly --version="[VERSION]"
```

### Tips for creating BUILD.bazel files

Folly uses a build system called BUCK2 which is very similar to bazel.

The BUCK files in the folly source tree can be mostly copied to a file in the same directory called BUILD.bazel, and then modified from there to support bazel.
