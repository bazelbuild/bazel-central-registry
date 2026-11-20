// Initialises RmlUi with a render interface that only records the calls, then lays out and renders a
// document with a box, text (FreeType, with the embedded font of the Debugger) and, with the SVG plugin,
// an inline SVG image (lunasvg).
#include <RmlUi/Core.h>
#include <RmlUi/Debugger.h>
#ifdef TEST_SVG_PLUGIN
#include <RmlUi/SVG/ElementSVG.h>
#endif

#include <algorithm>
#include <cstdio>

namespace {

class RecordingRenderInterface : public Rml::RenderInterface {
public:
    Rml::CompiledGeometryHandle CompileGeometry(Rml::Span<const Rml::Vertex>, Rml::Span<const int>) override
    {
        return ++last_handle;
    }
    void RenderGeometry(Rml::CompiledGeometryHandle, Rml::Vector2f, Rml::TextureHandle) override { ++rendered_geometries; }
    void ReleaseGeometry(Rml::CompiledGeometryHandle) override {}
    Rml::TextureHandle LoadTexture(Rml::Vector2i&, const Rml::String&) override { return 0; }
    Rml::TextureHandle GenerateTexture(Rml::Span<const Rml::byte>, Rml::Vector2i dimensions) override
    {
        generated_textures.push_back(dimensions);
        return ++last_handle;
    }
    void ReleaseTexture(Rml::TextureHandle) override {}
    void EnableScissorRegion(bool) override {}
    void SetScissorRegion(Rml::Rectanglei) override {}

    int rendered_geometries = 0;
    Rml::Vector<Rml::Vector2i> generated_textures;

private:
    Rml::CompiledGeometryHandle last_handle = 0;
};

bool Check(bool condition, const char* what)
{
    if (!condition)
        std::fprintf(stderr, "check failed: %s\n", what);
    return condition;
}

const char* const document_rml = R"(<rml>
<head>
<style>
body { width: 400dp; height: 300dp; font-family: rmlui-debugger-font; font-size: 16dp; color: #000; }
#box { display: block; width: 50dp; height: 20dp; background-color: #f00; }
</style>
</head>
<body>
<div id="box"/>
<p id="text">Hello, RmlUi!</p>
<svg id="image" width="16" height="16" viewBox="0 0 16 16"><rect width="16" height="16" fill="#00f"/></svg>
</body>
</rml>)";

bool RenderDocument(Rml::Context* context, RecordingRenderInterface& render_interface)
{
    Rml::ElementDocument* document = context->LoadDocumentFromMemory(document_rml);
    if (!Check(document != nullptr, "LoadDocumentFromMemory"))
        return false;

    document->Show();
    context->Update();
    context->Render();

    bool ok = true;
    Rml::Element* box = document->GetElementById("box");
    ok &= Check(box && box->GetBox().GetSize() == Rml::Vector2f(50, 20), "layout of #box");
    Rml::Element* text = document->GetElementById("text");
    ok &= Check(text && text->GetBox().GetSize().y > 0, "layout of #text");
    ok &= Check(render_interface.rendered_geometries > 0, "geometry rendered");
    // The glyphs of the text are rendered from a texture.
    ok &= Check(!render_interface.generated_textures.empty(), "font texture generated");
#ifdef TEST_SVG_PLUGIN
    ok &= Check(rmlui_dynamic_cast<Rml::ElementSVG*>(document->GetElementById("image")) != nullptr, "svg element");
    const auto& textures = render_interface.generated_textures;
    ok &= Check(std::find(textures.begin(), textures.end(), Rml::Vector2i(16, 16)) != textures.end(), "svg texture generated");
#endif
    return ok;
}

} // namespace

int main()
{
    RecordingRenderInterface render_interface;
    Rml::SetRenderInterface(&render_interface);
    if (!Check(Rml::Initialise(), "Rml::Initialise"))
        return 1;

    bool ok = false;
    if (Rml::Context* context = Rml::CreateContext("main", Rml::Vector2i(800, 600)))
    {
        // Loads the embedded fonts of the Debugger through the FreeType font engine.
        ok = Check(Rml::Debugger::Initialise(context), "Rml::Debugger::Initialise");
        ok &= RenderDocument(context, render_interface);
    }
    else
    {
        Check(false, "Rml::CreateContext");
    }

    Rml::Shutdown();
    return ok ? 0 : 1;
}
