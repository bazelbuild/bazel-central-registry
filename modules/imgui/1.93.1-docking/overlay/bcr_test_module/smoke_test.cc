#include <imgui/imgui.h>
#include <imgui/imgui_impl_null.h>

#include <cstdio>
#include <cstring>

#ifndef IMGUI_HAS_DOCK
#error "This test requires the docking release of Dear ImGui."
#endif

static_assert(IMGUI_VERSION_NUM == 19310, "Expected Dear ImGui 1.93.1");

int main()
{
    if (!IMGUI_CHECKVERSION() || std::strcmp(ImGui::GetVersion(), IMGUI_VERSION) != 0)
        return 1;

    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO();
    io.IniFilename = nullptr;
    io.LogFilename = nullptr;
    io.ConfigFlags |= ImGuiConfigFlags_DockingEnable;
    ImGui::StyleColorsDark();
    if (!ImGui_ImplNull_Init())
    {
        ImGui::DestroyContext();
        return 1;
    }

    bool passed = true;
    bool saw_draw_data = false;
    for (int frame = 0; frame < 20; ++frame)
    {
        ImGui_ImplNull_NewFrame();
        ImGui::NewFrame();
        const ImGuiID dockspace = ImGui::DockSpaceOverViewport();

        ImGui::SetNextWindowDockID(dockspace, ImGuiCond_Always);
        ImGui::ShowDemoWindow();

        ImGui::SetNextWindowDockID(dockspace, ImGuiCond_Always);
        ImGui::Begin("BCR docked window");
        ImGui::TextUnformatted("Dear ImGui from the Bazel Central Registry");
        static float value = 0.5f;
        ImGui::SliderFloat("Value", &value, 0.0f, 1.0f);
        if (frame > 0 && (!ImGui::IsWindowDocked() || ImGui::GetWindowDockID() != dockspace))
        {
            std::fprintf(stderr, "Window was not docked on frame %d\n", frame);
            passed = false;
        }
        ImGui::End();

        ImGui::Render();
        ImDrawData* draw_data = ImGui::GetDrawData();
        if (draw_data == nullptr || !draw_data->Valid)
        {
            std::fprintf(stderr, "Invalid draw data on frame %d\n", frame);
            passed = false;
        }
        else
        {
            saw_draw_data |= draw_data->TotalVtxCount > 0 && draw_data->TotalIdxCount > 0;
            ImGui_ImplNullRender_RenderDrawData(draw_data);
        }
    }

    ImGui_ImplNull_Shutdown();
    ImGui::DestroyContext();
    if (!saw_draw_data)
        std::fprintf(stderr, "No geometry was generated\n");
    return passed && saw_draw_data ? 0 : 1;
}
