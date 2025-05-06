build args:

boringssl
```shell
--@boost.mysql//:ssl=boringssl --@boost.asio//:ssl=boringssl
```

openssl:
```shell
--@boost.mysql//:ssl=openssl --@boost.asio//:ssl=openssl
```