"""Code generation for the faiss GPU IVF-interleaved scan kernels.

This mirrors the `generate_ivf_interleaved_code()` CMake function in
`faiss/gpu/CMakeLists.txt`. It instantiates
`impl/scan/IVFInterleavedScanKernelTemplate.cu` for the Cartesian product of
(codec, metric, thread configuration), replacing the SUB_* placeholders, and
returns the list of generated `.cu` source labels.
"""

_CODECS = [
    "faiss::gpu::Codec<0, 1>",
    "faiss::gpu::Codec<1, 1>",
    "faiss::gpu::Codec<2, 1>",
    "faiss::gpu::Codec<3, 1>",
    "faiss::gpu::Codec<4, 1>",
    "faiss::gpu::Codec<5, 1>",
    "faiss::gpu::Codec<6, 1>",
    "faiss::gpu::CodecFloat",
]

_METRICS = [
    "faiss::gpu::IPDistance",
    "faiss::gpu::L2Distance",
]

# (threads, num_warp_q, num_thread_q)
_THREADS_AND_WARPS = [
    (128, 1024, 8),
    (128, 1, 1),
    (128, 128, 3),
    (128, 256, 4),
    (128, 32, 2),
    (128, 512, 8),
    (128, 64, 3),
    (64, 2048, 8),
]

def _sanitize(s):
    # Equivalent to CMake's `string(REGEX REPLACE "[^A-Za-z0-9_]" "" ...)`:
    # the placeholder values only ever contain these non-word characters.
    for ch in [":", "<", ">", ",", " "]:
        s = s.replace(ch, "")
    return s

def generate_ivf_interleaved_sources(name, template):
    """Generates the IVF-interleaved scan kernel specializations.

    Args:
        name: prefix for the generated genrule targets.
        template: label of the `.cu` template with SUB_* placeholders.

    Returns:
        A list of generated `.cu` source file names, suitable for `srcs`.
    """
    srcs = []
    for codec in _CODECS:
        for metric in _METRICS:
            for tw in _THREADS_AND_WARPS:
                threads, warp_q, thread_q = tw[0], tw[1], tw[2]
                stem = _sanitize("template_{}_{}_{}_{}_{}".format(
                    codec,
                    metric,
                    threads,
                    warp_q,
                    thread_q,
                ))
                out = stem + ".cu"

                # The order of substitutions does not matter: no placeholder is
                # a substring of another, and no replacement value reintroduces
                # a SUB_* token. `|` is a safe sed delimiter (absent from the
                # C++ type strings).
                cmd = ("sed " +
                       "-e 's|SUB_CODEC_TYPE|{codec}|g' " +
                       "-e 's|SUB_METRIC_TYPE|{metric}|g' " +
                       "-e 's|SUB_NUM_WARP_Q|{warp_q}|g' " +
                       "-e 's|SUB_NUM_THREAD_Q|{thread_q}|g' " +
                       "-e 's|SUB_THREADS|{threads}|g' " +
                       "$< > $@").format(
                    codec = codec,
                    metric = metric,
                    threads = threads,
                    warp_q = warp_q,
                    thread_q = thread_q,
                )
                native.genrule(
                    name = "{}_{}".format(name, stem),
                    srcs = [template],
                    outs = [out],
                    cmd = cmd,
                )
                srcs.append(out)
    return srcs
