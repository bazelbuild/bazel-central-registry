## Notes on bazelifying a folly release

First clone the folly repository from https://github.com/facebook/folly

Cd into the folly source and checkout the release branch that you would like to bazelify.

Folly uses angle brackets to include headers. Bazel requires quotes. Run the following command from the folly ssrc dir to create a patch that changes folly includes to quotes:

```bash
# NOTE: This will not work if you have already modified sources. Do this first after a fresh clone.
rg "#include <(folly.*)>" -l | xargs sed -i -E 's/#include <(folly.*)>/#include "\1"/g'
rg "#include <(double-conversion.*)>" -l | xargs sed -i -E 's/#include <(double-conversion.*)>/#include "\1"/g'
git diff > "/path/to/bazel-central-registry/modules/folly/[release]/patches/use_quote_includes.patch"
```

Create your MODULE.bazel and BUILD.bazel files (more help on that below).

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
