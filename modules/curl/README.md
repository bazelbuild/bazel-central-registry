# curl

Starting with `8.22.0.bcr.2`, HTTP/2 support can be enabled with nghttp2:

```text
build --@curl//:http2=true
```

The `http2` flag defaults to `false`, preserving the existing build behavior.
When enabled, both `@curl//:curl` and `@curl//:curl_shared` support HTTP/2.
The flag works with the existing `ssl_lib` backend selection.
