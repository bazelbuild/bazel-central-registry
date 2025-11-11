#include <iostream>

#include <pxr/usd/usd/stage.h>
#include <pxr/usd/usdGeom/sphere.h>
#include <pxr/base/tf/token.h>

int main() {
    std::cout << "--- USD Initialization Test ---\n";

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