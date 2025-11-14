# prjtrellis

When adding new versions it's critical to ensure the `prjtrellis_db` module
is also updated to the matching version.

Versions should be gauranteed by a circular dependency between `prjtrellis-db <--> prjtrellis`.
