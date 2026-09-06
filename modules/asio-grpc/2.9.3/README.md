Several include paths in the asio-grpc tests need to be patched to support bazel-generated files. Below are commands to get started when updating a version. These were used to make the changes in the bazel_test_fixes.patch file.

```bash
rg doctest/doctest.h -l | xargs sed -i -e 's;<doctest/doctest.h>;"doctest/doctest.h";g'
```

```bash
rg test/v1/test_mock.grpc.pb.h -l | xargs sed -i -e 's;test/v1/test_mock.grpc.pb.h;test/proto/test/v1/test_mock.grpc.pb.h;g'
```

```bash
rg test/v1/test.grpc.pb.h -l | xargs sed -i -e 's;test/v1/test.grpc.pb.h;test/proto/test/v1/test.grpc.pb.h;g'
```

```bash
rg grpc/health/v1/health.grpc.pb.h -l | xargs sed -i -e 's;grpc/health/v1/health.grpc.pb.h;test/proto/grpc/health/v1/health.grpc.pb.h;g'

rg '<test/proto/grpc/health/v1/health.grpc.pb.h>' -l | xargs sed -i -e 's;<test/proto/grpc/health/v1/health.grpc.pb.h>;"test/proto/grpc/health/v1/health.grpc.pb.h";g'
```
