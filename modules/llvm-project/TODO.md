# TODO

In increasing difficultly order:

- [ ] Figure out why permissions tests on Mac do not work with default temporary directory
- [ ] Run `//llvm/unittests:all` on Windows
    - [ ] Validate why LLVM `LegalizerInfoTest.SizeChangeStrategy` fails on Windows
    - [ ] Validate why LLVM `SMEAttributes.Constructors` fails on Windows
    - [ ] Validate why LLVM `AttributorTestBase.AAReachabilityTest` fails on Windows
- [ ] Add optional dependencies
    - [ ] Add `zlib` (or `zlib-ng`)
    - [ ] Add `zstd`
    - [ ] Add `pfm`
    - [ ] Add `mpfr` (and by extension, `gmp`)
- [ ] Use `blake3` from BCR
- [ ] Get `//clang` building on Windows
- [ ] Get Clang unit tests passing on Windows
- Run all LLVM project tests (`bazel test //...`)
    - [ ] Linux
    - [ ] Mac
    - [ ] Windows
