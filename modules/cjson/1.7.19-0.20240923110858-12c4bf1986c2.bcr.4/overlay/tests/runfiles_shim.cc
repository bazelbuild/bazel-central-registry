#include "runfiles_shim.h"
#include "rules_cc/cc/runfiles/runfiles.h"

#include <cstdlib>
#include <cstring>
#include <memory>
#include <string>

extern "C" {

char *runfiles_resolve(const char *runfile_path, const char *fallback_path)
{
    (void)fallback_path;
    if (!runfile_path || !runfile_path[0])
        return nullptr;

    static std::unique_ptr<rules_cc::cc::runfiles::Runfiles> runfiles;
    if (!runfiles)
    {
        std::string error;
        runfiles.reset(rules_cc::cc::runfiles::Runfiles::CreateForTest(&error));
        if (!runfiles)
            return nullptr;
    }

    std::string path = runfiles->Rlocation(runfile_path);
    if (path.empty())
        return nullptr;

    return strdup(path.c_str());
}

} /* extern "C" */
