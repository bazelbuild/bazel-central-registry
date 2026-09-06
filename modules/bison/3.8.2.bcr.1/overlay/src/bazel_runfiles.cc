#include "rules_cc/cc/runfiles/runfiles.h"

#include <cstring>
#include <string>

using rules_cc::cc::runfiles::Runfiles;

struct BazelRunfiles {
	std::unique_ptr<Runfiles> ptr;
};

extern "C" {

static struct BazelRunfiles *bazel_runfiles = NULL;

void bazel_runfiles_init(const char *argv0_cstr) {
	if (bazel_runfiles != nullptr) {
		return;
	}

	Runfiles *runfiles;
	std::string argv0(argv0_cstr);
	std::string source_repository(BAZEL_CURRENT_REPOSITORY);
	std::string error;
	runfiles = Runfiles::Create(argv0, source_repository, &error);
	if (runfiles == nullptr) {
		return;
	}

	bazel_runfiles = new BazelRunfiles;
	bazel_runfiles->ptr.reset(runfiles);
}

char *bazel_runfiles_bison_pkgdatadir() {
	if (bazel_runfiles == nullptr) {
		return nullptr;
	}

	std::string path = std::string(
		BAZEL_CURRENT_REPOSITORY "/data/m4sugar/m4sugar.m4"
	);
	std::string result = bazel_runfiles->ptr->Rlocation(path);
	if (result.empty()) {
		return nullptr;
	}

	char *datadir = strdup(result.c_str());
	/* "data/m4sugar/m4sugar.m4" => "data" */
	datadir[result.size() - 19] = '\x00';
	return datadir;
}

char *bazel_runfiles_m4() {
	if (bazel_runfiles == nullptr) {
		return nullptr;
	}
	const char *runfiles_m4_cstr = getenv("BISON_BAZEL_RUNFILES_M4");
	if (runfiles_m4_cstr == nullptr) {
		return nullptr;
	}
	std::string runfiles_m4(runfiles_m4_cstr);
	std::string path;
	if (runfiles_m4.find("../") == 0) {
		path = runfiles_m4.substr(3);
	} else {
		path = std::string(BAZEL_CURRENT_REPOSITORY) + "/" + runfiles_m4;
	}
	std::string result = bazel_runfiles->ptr->Rlocation(path);
	if (result.empty()) {
		return nullptr;
	}
	return strdup(result.c_str());
}

}
