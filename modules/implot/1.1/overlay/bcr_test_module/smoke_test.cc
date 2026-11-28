#include <imgui/imgui.h>
#include <implot/implot.h>

#include <cstdio>

static_assert(IMPLOT_VERSION_NUM == 10100, "Expected ImPlot 1.1");

int main()
{
    if (!IMGUI_CHECKVERSION())
        return 1;

    ImGui::CreateContext();
    ImPlot::CreateContext();
    ImGuiIO& io = ImGui::GetIO();
    io.IniFilename = nullptr;
    io.LogFilename = nullptr;
    io.DisplaySize = ImVec2(1920, 1080);
    io.DeltaTime = 1.0f / 60.0f;
    io.BackendFlags |= ImGuiBackendFlags_RendererHasVtxOffset;

    unsigned char* pixels = nullptr;
    int width = 0, height = 0;
    io.Fonts->GetTexDataAsRGBA32(&pixels, &width, &height);
    io.Fonts->SetTexID(static_cast<ImTextureID>(1));

    bool passed = pixels != nullptr && width > 0 && height > 0;
    bool saw_plot = false;
    bool saw_draw_data = false;
    for (int frame = 0; frame < 20; ++frame)
    {
        ImGui::NewFrame();
        ImGui::ShowDemoWindow();
        ImPlot::ShowDemoWindow();

        ImGui::SetNextWindowPos(ImVec2(0, 0), ImGuiCond_Always);
        ImGui::SetNextWindowSize(ImVec2(600, 400), ImGuiCond_Always);
        ImGui::Begin("BCR plot");
        if (ImPlot::BeginPlot("Line and scatter"))
        {
            ImPlot::SetupAxesLimits(0, 3, -1, 5, ImGuiCond_Always);
            const double xs[] = {0, 1, 2, 3};
            const double ys[] = {0, 1, 4, 2};
            ImPlot::PlotLine("Line", xs, ys, 4);
            ImPlot::PlotScatter("Scatter", xs, ys, 4);
            const ImPlotRect limits = ImPlot::GetPlotLimits();
            if (!limits.Contains(2, 4))
            {
                std::fprintf(stderr, "Unexpected plot limits on frame %d\n", frame);
                passed = false;
            }
            saw_plot = true;
            ImPlot::EndPlot();
        }
        ImGui::End();

        ImGui::Render();
        const ImDrawData* draw_data = ImGui::GetDrawData();
        if (draw_data == nullptr || !draw_data->Valid)
        {
            std::fprintf(stderr, "Invalid draw data on frame %d\n", frame);
            passed = false;
        }
        else
            saw_draw_data |= draw_data->TotalVtxCount > 0 && draw_data->TotalIdxCount > 0;
    }

    ImPlot::DestroyContext();
    ImGui::DestroyContext();
    if (!saw_plot || !saw_draw_data)
        std::fprintf(stderr, "No plot or geometry was generated\n");
    return passed && saw_plot && saw_draw_data ? 0 : 1;
}
