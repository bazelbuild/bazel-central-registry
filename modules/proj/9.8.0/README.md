The upstream `proj-9.8.0` source archive does not ship Bazel files, so this
module uses an overlay for `BUILD.bazel` and `MODULE.bazel`.

The overlay was derived from the local Bazelization in `../PROJ`, with the
version pinned to the released `9.8.0` archive and the module definition
adapted to depend on BCR's `sqlite3` module instead of declaring its own
`http_archive`.
