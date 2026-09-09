// SPDX-License-Identifier: Apache-2.0
//
// Overlay-only file added by the openfpgaloader BCR port. See dataResolver.hpp
// for the contract.

#include "dataResolver.hpp"

#include <cstdlib>
#include <fstream>
#include <string>

#include "common.hpp"

#ifdef USE_RULES_CC_RUNFILES
#include <memory>

#include "rules_cc/cc/runfiles/runfiles.h"

#if defined(__linux__)
#include <unistd.h>
#elif defined(__APPLE__)
#include <mach-o/dyld.h>
#elif defined(_WIN32)
#include <windows.h>
#endif

namespace {

// The runfiles library needs the executable path to locate its manifest when
// RUNFILES_MANIFEST_FILE / RUNFILES_DIR aren't set (i.e. the binary was
// invoked directly, not via `bazel run`). Look it up via platform APIs so we
// don't have to patch main() to plumb argv[0] down here.
std::string executablePath() {
#if defined(__linux__)
	char buf[4096];
	ssize_t n = readlink("/proc/self/exe", buf, sizeof(buf) - 1);
	if (n > 0) {
		buf[n] = '\0';
		return std::string(buf);
	}
#elif defined(__APPLE__)
	char buf[4096];
	uint32_t sz = sizeof(buf);
	if (_NSGetExecutablePath(buf, &sz) == 0)
		return std::string(buf);
#elif defined(_WIN32)
	char buf[MAX_PATH];
	DWORD n = GetModuleFileNameA(nullptr, buf, sizeof(buf));
	if (n > 0)
		return std::string(buf, n);
#endif
	return "";
}

}  // namespace
#endif  // USE_RULES_CC_RUNFILES

#ifndef DATA_DIR
#define DATA_DIR "/usr/local/share"
#endif

std::string resolveDataFile(const std::string& subdir,
		const std::string& basename) {
#ifdef USE_RULES_CC_RUNFILES
	{
		using rules_cc::cc::runfiles::Runfiles;
		std::string error;
		std::unique_ptr<Runfiles> rf(Runfiles::Create(
			executablePath(), BAZEL_CURRENT_REPOSITORY, &error));
		if (rf != nullptr) {
			const std::string rlocationpath =
				"openfpgaloader/" + subdir + "/" + basename;
			const std::string resolved = rf->Rlocation(rlocationpath);
			if (!resolved.empty()) {
				std::ifstream probe(resolved.c_str());
				if (probe.good())
					return resolved;
			}
		}
	}
#else
	(void)subdir;
#endif
	// Fallback: upstream install layout is flat under DATA_DIR.
	const std::string dir = get_shell_env_var(
		"OPENFPGALOADER_SOJ_DIR", DATA_DIR "/openFPGALoader");
	return dir + "/" + basename;
}
