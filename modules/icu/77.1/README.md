# ICU for BCR notes

ICU already has a number of `BUILD.bazel` files, but they are mostly meant for use during ICU development for [building ICU data](https://unicode-org.github.io/icu/processes/unicode-update.html#bazel-build-process).
This means that they only Bazelfied what they needed for that to work and not everything in the `icu4c` library has a build target yet.
So if something you need is missing, you will either need to patch it in to an existing upstream ICU `BUILD.bazel` file or add one in the overlay if it doesn't exist upstream.

## ICU data

ICU requires [data files to function correctly](https://unicode-org.github.io/icu/userguide/icu_data/).
It can either use a prebuilt `.dat` file or link a shared object file that wraps the data generated using `icu4c/source/tools/genccode`.
Since `genccode` isn't Bazelfied, it was easier to use the prebuilt `.dat` file that comes with each ICU release.
The prebuilt `.dat` files are only available via the release `src` asset and don't exist in the repo.
But the ICU `BUILD.bazel` files are only available in the repo, but not the `src` release asset.
Thus we pull from the repo in `sources.json` to obtain the code with the `BUILD.bazel` files and in `MODULE.bazel` we use `http_archive` to get the prebuilt `.dat` file that comes with each ICU release.

Normally in order to tell ICU where the prebuilt `.dat` file is located, you can set the define directive [`ICU_DATA_DIR`](https://unicode-org.github.io/icu/userguide/icu_data/#icu-data-directory).
However, since we're passing this data file in with Bazel, we need to use the Bazel C++ runfiles library to look up its actual location.
The patches we've added allows for this.

## Tests

The ICU tests are not Bazelfied, so we've just added a simple test file to excercise that the data loading works correctly at runtime.
