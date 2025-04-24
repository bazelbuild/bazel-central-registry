# exempi for BCR notes

*   exempi's directory structure is a bit more complex than other libraries, so it was more readable to put `BUILD` files throughout the project than have everything done in the root `BUILD` file.
*   The `BUILD` files generally mimic the `Makefile.am` files for each directory.
*   Note that there are a number of source files for Adobe's new DOM based API that exempi does not yet expose, so these are omitted from the Bazel build.
