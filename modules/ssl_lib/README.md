# ssl_lib

## Purpose

The purpose of the `ssl_lib` module in BCR is to provide a single point of
control for choosing the SSL. This module provides a standardized `deps` for
other modules that require SSL, i.e., `deps = ["@ssl_lib//:crypto"]` and
`deps = ["@ssl_lib//:ssl"]`.

In other packaging systems, this is sometimes known as a "virtual package".

By default this module points to the BoringSSL library. Applications that would
like to use a different implementation should set the `crypto_lib` and `ssl_lib`
flags to the replacement labels, e.g.,
`--@ssl_lib//:crypto_lib=@openssl//:crypto` and
`--@ssl_lib//:ssl_lib=@openssl//:ssl`.

## Version updates

This module specifically does NOT pin the latest version of boringssl. We don't
want to churn here every time boringssl releases. Downstream projects should
rely on their own top-level MODULE file to set the MVS baseline for their
minimum version.
