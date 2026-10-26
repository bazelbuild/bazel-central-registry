# LVM2 (device-mapper library)

This module builds the `make install_device-mapper` subset of LVM2: the
`libdevmapper` library (`@lvm2//:devmapper`), its header and the `dmsetup` and
`dmstats` programs.  The LVM tools and daemons depend on libraries the registry
does not have (libaio, libblkid, udev) and are not built.

It uses [`rules_cc_autoconf`](https://registry.bazel.build/modules/rules_cc_autoconf)
to detect platform-specific configuration at build time rather than relying on
hard-coded defaults.
