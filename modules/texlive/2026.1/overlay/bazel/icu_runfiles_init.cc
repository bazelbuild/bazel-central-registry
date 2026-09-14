// icu_runfiles_init.cc
//
// Pre-main initializer that points ICU at its data file (icudt78l.dat)
// in the Bazel runfiles tree. Without this, ICU's lazy lookup falls
// through to a system path (/usr/share/icu/...) that doesn't exist
// when the binary runs from a sandbox or runfiles tree, and
// locale-aware APIs like `ucol_open` / `unorm2_getInstance` return
// null/error.
//
// We do the lookup ourselves rather than relying on the icu BCR's
// putil.cpp patch so the runfiles concern lives with the consumer
// (texlive) and not with the icu module. ICU's `dataDirectoryInitFn`
// early-returns when `gDataDirectory` is already set, so our pre-main
// `u_setDataDirectory()` wins over any later icu-side default.
//
// Build-time wiring: the cc_library that compiles this file must set
//   * `local_defines = ["ICU_DATA_DIR_BAZEL=\"$(rlocationpath @icu_dat)\""]`
//   * `data = ["@icu_dat"]`
//   * `alwayslink = True` (otherwise the static constructor gets
//      dropped because nothing references the TU's symbols).

#include <memory>
#include <string>

#include "rules_cc/cc/runfiles/runfiles.h"
#include "unicode/putil.h"

namespace {

using rules_cc::cc::runfiles::Runfiles;

class IcuRunfilesDataDirInit {
 public:
    IcuRunfilesDataDirInit() {
        std::string error;
        std::unique_ptr<Runfiles> runfiles(
            Runfiles::Create("", BAZEL_CURRENT_REPOSITORY, &error));
        if (!runfiles) return;

        std::string dat = runfiles->Rlocation(ICU_DATA_DIR_BAZEL);
        if (dat.empty()) return;

        // ICU expects the directory containing the .dat file, not the
        // file path itself.
        std::string::size_type slash = dat.find_last_of('/');
        if (slash != std::string::npos) {
            dat.resize(slash);
        }
        u_setDataDirectory(dat.c_str());
    }
};

// Static-storage instance whose constructor runs at binary load, before
// main() and before any ICU initialization.
const IcuRunfilesDataDirInit kInit;

}  // namespace
