"Various test related utility functions"

load("@rules_cc//cc:cc_test.bzl", _cc_test = "cc_test")
load("//tools:cc.bzl", "CONLYOPTS", "COPTS", "CXXOPTS", "C_FEATURES")

def join_conf(conf1, conf2):
    """Joins two configuration strings with a ',' delimiter.

    Args:
        conf1: First configuration string or None
        conf2: Second configuration string or None

    Returns:
        A properly joined configuration string without dangling commas.
    """

    if conf1 and conf2:
        return "%s,%s" % (conf1, conf2)
    elif not conf1:
        return conf2
    elif not conf2:
        return conf1
    else:
        return ""

def test_name(data, suffix = None):
    """Generates a test name based on the source file name.

    Args:
        data: Dict with test data containing 'src' and optional 'name' key
        suffix: String suffix to remove from the source file name

    Returns:
        A string representing the test name.
    """
    name = data.get("name", data["src"].lower().removesuffix(".c").removesuffix(".cpp").replace("/", "_"))
    if suffix:
        return "%s_%s" % (name, suffix)
    else:
        return name

def cc_test(name, src, **kwargs):
    """rules_cc's cc_test with the flags every jemalloc test program compiles with.

    Each of upstream's test programs is built from one source file (Makefile.in:526, 530, 534); code a test shares with
    another comes in through deps.

    Args:
        name: The test's name.
        src: The test's source file.
        **kwargs: Passed to cc_test.
    """
    _cc_test(
        name = name,
        srcs = [src],
        conlyopts = CONLYOPTS,
        features = C_FEATURES,
        # The test library compiles with COPTS alone. The test programs' expect_*() and assert_*() calls pass empty
        # messages, which -Wformat-zero-length flags (configure.ac:255).
        copts = COPTS + select({
            "@rules_cc//cc/compiler:clang": ["-Wno-format-zero-length"],
            "@rules_cc//cc/compiler:clang-cl": ["-Wno-format-zero-length"],
            "@rules_cc//cc/compiler:emscripten": ["-Wno-format-zero-length"],
            "@rules_cc//cc/compiler:gcc": ["-Wno-format-zero-length"],
            "@rules_cc//cc/compiler:mingw-gcc": ["-Wno-format-zero-length"],
            "//conditions:default": [],
        }),
        cxxopts = CXXOPTS,
        **kwargs
    )
