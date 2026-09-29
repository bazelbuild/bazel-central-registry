// Smoke-test the bazel-native graphviz library from a downstream
// module: build a tiny graph in memory, run dot layout, and render
// to the dot output format. Failure to compile or link this file
// would indicate a regression in the public API surface exposed by
// `@graphviz//:graphviz`.

#include <cgraph/cgraph.h>
#include <gvc/gvc.h>
#include <gvc/gvcext.h>

#include <cstdio>
#include <cstdlib>
#include <cstring>

int main() {
    // The bazel-native build statically registers plugins via
    // `lt_preloaded_symbols`. Pass them in explicitly; calling
    // `gvContext()` would leave the context with no builtins
    // because that overload passes NULL.
    GVC_t *gvc = gvContextPlugins(lt_preloaded_symbols, 0);
    if (gvc == nullptr) {
        std::fprintf(stderr, "gvContext() returned null\n");
        return 1;
    }

    Agraph_t *g = agopen(const_cast<char *>("g"), Agdirected, nullptr);
    Agnode_t *a = agnode(g, const_cast<char *>("a"), 1);
    Agnode_t *b = agnode(g, const_cast<char *>("b"), 1);
    agedge(g, a, b, nullptr, 1);

    if (gvLayout(gvc, g, "dot") != 0) {
        std::fprintf(stderr, "gvLayout failed\n");
        return 1;
    }

    char *out = nullptr;
    std::size_t len = 0;
    if (gvRenderData(gvc, g, "dot", &out, &len) != 0 || out == nullptr) {
        std::fprintf(stderr, "gvRenderData failed\n");
        return 1;
    }

    int ok = std::strstr(out, "a -> b") != nullptr;
    gvFreeRenderData(out);
    gvFreeLayout(gvc, g);
    agclose(g);
    gvFreeContext(gvc);

    if (!ok) {
        std::fprintf(stderr, "rendered output did not contain 'a -> b'\n");
        return 1;
    }
    return 0;
}
