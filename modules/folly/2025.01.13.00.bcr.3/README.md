## Steps to Bazelfying a Folly release

1.  Clone the Folly repo:

    ```shell
    git clone https://github.com/facebook/folly.git
    ```

1.  Create a Git branch at the release you want to Bazelfy.
    For example:

    ```shell
    git checkout -b bazel v2025.01.13.00
    ```

1.  Create a new BCR Folly version.

1.  Run the `bcr_to_folly.sh` script, which will bootstrap your Folly repo by copying all the `BUILD` files from the BCR Folly to your repo.
    This script is only meant to be run once on a clean Folly repo.
    For example:

    ```shell
    cd /path/to/your/bazel-central-registry/modules/folly/2025.01.13.00.bcr.3/scripts
    ./bcr_to_folly.sh /path/to/your/folly/repo
    ```

1.  Update and/or add `BUILD` files in your Folly repo as needed.
    Updated any source files as needed.

1.  Because of the way the `includes` work for Folly BCR, you won't actually be able to build/test targets correctly from inside the Folly repo.
    The Folly repo must be tested as an external dep.
    The easiest way to do this is to create another folder with its own Bazel module, use `local_path_override` to depend on Folly, and run all Bazel commands from that module.
    For example in another folder's `MODULE.bazel` file:

    ```python
    bazel_dep(name = "folly")
    local_path_override(
        module_name = "folly",
        path = "../folly",  # assuming this folder is beside the Folly repo
    )
    ```

    Then build/test Folly with `@folly`.
    E.g., `bazel build @folly//...`

1.  Run the `folly_to_bcr.sh` script to copy the `BUILD` files back into your new BCR Folly version.
    You can run this script as many times as needed while iterating.
    For example:

    ```shell
    cd /path/to/your/bazel-central-registry/modules/folly/2025.01.13.00.bcr.3/scripts
    ./folly_to_bcr.sh /path/to/your/folly/repo
    ```

1.  Generate Git patch files for any changes you made to Folly patch files and ensure they are added to the `patches` directory in BCR Folly.

1.  Update integrity as needed (must be run from the `bazel-central-registry` module).
    For example:

    ```shell
    bazel run -- //tools:update_integrity folly
    ```

## Tips and other notes

*   For Folly `BUILD` files, use our Bazel `cpp_library` macro instead of the Folly `cpp_library macro`.
*   Add any custom `bzl` files under a directory called `bzl` in the Folly source tree.
*   Folly uses a build system called [Buck2](https://buck2.build/) which is very similar to Bazel.
    The `BUCK` files in the folly source tree can be mostly copied to a file in the same directory called `BUILD.bazel`, and then modified from there to support Bazel.
