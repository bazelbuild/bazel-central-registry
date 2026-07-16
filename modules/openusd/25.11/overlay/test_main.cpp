#include <iostream>

#include <pxr/usd/usd/stage.h>
#include <pxr/usd/usdGeom/sphere.h>
#include <pxr/base/tf/token.h>
#include <pxr/base/plug/registry.h>

#include "tools/cpp/runfiles/runfiles.h"

using bazel::tools::cpp::runfiles::Runfiles;

int main(int argc, char** argv) {
    std::cout << "--- USD Initialization Test ---\n";

    // Use the bazel runfiles lib to get the path to the openusd plugins that this
    // executable depends on. Use Create() for regular binaries and CreateForTest()
    // for tests.
    std::string error;
    //std::unique_ptr<Runfiles> runfiles(Runfiles::Create(argv[0], &error));
    std::unique_ptr<Runfiles> runfiles(Runfiles::CreateForTest(&error));
    if (runfiles == nullptr) {
      std::cout << "NO RUNFILES FOUND" << std::endl;
      return 1;
    }

    // Register our custom plugins path with the plugin registry.
    // If we do not do this, OpenUSD will throw when creating a stage.
    std::string pluginsPath = runfiles->Rlocation("usd");
    std::cout << "PATH to openusd/usd => " << pluginsPath << std::endl;
    pxr::PlugRegistry::GetInstance().RegisterPlugins(pluginsPath);

    // Create a USD Stage (the core container for a scene)
    auto stage = pxr::UsdStage::CreateNew(std::string("HelloWorld.usda"));
    if (stage) {
        // Create a primary root primitive (like a scene root)
        pxr::SdfPath primPath("/World/MyFirstPrim");
        pxr::UsdGeomSphere sphere = 
            pxr::UsdGeomSphere::Define(stage, primPath);
        std::cout << "Successfully created a primitive at path: " 
                  << sphere.GetPath().GetString() << "\n";

		    // Print a tftoken
        pxr::TfToken myToken("Success!");
        std::cout << "TfToken status: " << myToken.GetString() << "\n";
    } else {
        std::cerr << "ERROR: Failed to create an in-memory USD stage!\n";
        return 1;
    }
    
    std::cout << "--- USD Test Complete ---\n";
    return 0;
}
