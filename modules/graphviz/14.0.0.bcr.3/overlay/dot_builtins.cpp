// Builtin plugin registration for the bazel-native graphviz build.
//
// Upstream's cmd/dot/dot_builtins.cpp references plugins that are not
// part of this build (kitty, vt, pango/gd/quartz/webp -- renderers that
// need external libraries). Statically register only the plugins we
// actually compile.
//
// neato_layout supplies every layout engine other than dot: neato, fdp,
// sfdp, circo, twopi, osage and patchwork.

#include <gvc/gvplugin.h>

extern "C" {

extern gvplugin_library_t gvplugin_dot_layout_LTX_library;
extern gvplugin_library_t gvplugin_neato_layout_LTX_library;
extern gvplugin_library_t gvplugin_core_LTX_library;

lt_symlist_t lt_preloaded_symbols[] = {
    {"gvplugin_dot_layout_LTX_library", &gvplugin_dot_layout_LTX_library},
    {"gvplugin_neato_layout_LTX_library", &gvplugin_neato_layout_LTX_library},
    {"gvplugin_core_LTX_library", &gvplugin_core_LTX_library},
    {0, 0},
};

}
