There are two relevant patches

  * `lemon.patch` changes the includes of the own lemon headers from
     system-includes `<...>` to local project includes `"..."`
  * `allocator-patch.patch` makes the older code-base compatible with
    c++20.
