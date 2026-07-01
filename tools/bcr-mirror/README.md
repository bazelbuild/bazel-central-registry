# BCR source archive mirror

This directory contains a [Cloudflare Worker](https://developers.cloudflare.com/workers/) that mirrors source archives for modules in a Bazel registry to a [Cloudflare R2](https://developers.cloudflare.com/r2/) bucket.
The bucket can then be used with Bazel's `--module_mirrors` flag (available as of Bazel 8.4.0).

## Usage

The worker supports requests to `/<module>/<version>` and mirrors the source archive for the specified module version to the configured R2 bucket.
Since this operation is idempotent and can only be used to add source archives referenced by the configured registry, the worker does not require authentication.

## Deployment

You may have to modify the variables and bindings in `wrangler.jsonc` as needed. Then deploy the worker via `npx wrangler deploy`.
