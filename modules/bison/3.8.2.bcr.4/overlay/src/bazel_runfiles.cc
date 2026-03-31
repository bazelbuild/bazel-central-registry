#include "rules_cc/cc/runfiles/runfiles.h"

#include <cstdio>
#include <cstring>
#include <string>

#ifdef _WIN32
#include <windows.h>
#include <malloc.h>
static LONG WINAPI bison_crash_handler(EXCEPTION_POINTERS *info) {
	fprintf(stderr,
		"BISON_RUNFILES_DEBUG: CRASH! ExceptionCode=0x%08lx ExceptionAddress=%p\n",
		info->ExceptionRecord->ExceptionCode,
		info->ExceptionRecord->ExceptionAddress);
	fflush(stderr);
	return EXCEPTION_CONTINUE_SEARCH;
}
#endif

using rules_cc::cc::runfiles::Runfiles;

struct BazelRunfiles {
	std::unique_ptr<Runfiles> ptr;
};

extern "C" {

static struct BazelRunfiles *bazel_runfiles = NULL;

static const char *safe(const char *s) { return s ? s : "(null)"; }

void bazel_runfiles_init(const char *argv0_cstr) {
#ifdef _WIN32
	SetUnhandledExceptionFilter(bison_crash_handler);
#endif
	fprintf(stderr, "BISON_RUNFILES_DEBUG: init enter, argv0=%s\n", argv0_cstr);
	fprintf(stderr, "BISON_RUNFILES_DEBUG: BAZEL_CURRENT_REPOSITORY=%s\n", BAZEL_CURRENT_REPOSITORY);
	fprintf(stderr, "BISON_RUNFILES_DEBUG: BISON_PKGDATADIR=%s\n", safe(getenv("BISON_PKGDATADIR")));
	fprintf(stderr, "BISON_RUNFILES_DEBUG: M4=%s\n", safe(getenv("M4")));
	fprintf(stderr, "BISON_RUNFILES_DEBUG: BISON_BAZEL_RUNFILES_M4=%s\n", safe(getenv("BISON_BAZEL_RUNFILES_M4")));

	if (bazel_runfiles != nullptr) {
		fprintf(stderr, "BISON_RUNFILES_DEBUG: already initialized, returning\n");
		return;
	}

	Runfiles *runfiles;
	std::string argv0(argv0_cstr);
	std::string source_repository(BAZEL_CURRENT_REPOSITORY);
	std::string error;
	fprintf(stderr, "BISON_RUNFILES_DEBUG: calling Runfiles::Create(%s, %s)\n", argv0.c_str(), source_repository.c_str());
	runfiles = Runfiles::Create(argv0, source_repository, &error);
	if (runfiles == nullptr) {
		fprintf(stderr, "BISON_RUNFILES_DEBUG: Runfiles::Create failed: %s\n", error.c_str());
		return;
	}
	fprintf(stderr, "BISON_RUNFILES_DEBUG: Runfiles::Create succeeded\n");

	bazel_runfiles = new BazelRunfiles;
	bazel_runfiles->ptr.reset(runfiles);
	fprintf(stderr, "BISON_RUNFILES_DEBUG: init exit, bazel_runfiles=OK\n");
}

char *bazel_runfiles_bison_pkgdatadir() {
	fprintf(stderr, "BISON_RUNFILES_DEBUG: pkgdatadir enter, bazel_runfiles=%s\n", bazel_runfiles ? "OK" : "NULL");
	if (bazel_runfiles == nullptr) {
		fprintf(stderr, "BISON_RUNFILES_DEBUG: pkgdatadir exit, returning NULL (no runfiles)\n");
		return nullptr;
	}

	std::string path = std::string(
		BAZEL_CURRENT_REPOSITORY "/data/m4sugar/m4sugar.m4"
	);
	fprintf(stderr, "BISON_RUNFILES_DEBUG: pkgdatadir calling Rlocation(%s)\n", path.c_str());
	std::string result = bazel_runfiles->ptr->Rlocation(path);
	fprintf(stderr, "BISON_RUNFILES_DEBUG: pkgdatadir Rlocation returned: %s\n", result.c_str());
	if (result.empty()) {
		fprintf(stderr, "BISON_RUNFILES_DEBUG: pkgdatadir exit, returning NULL (empty Rlocation)\n");
		return nullptr;
	}

	char *datadir = strdup(result.c_str());
	/* "data/m4sugar/m4sugar.m4" => "data" */
	datadir[result.size() - 19] = '\x00';
	fprintf(stderr, "BISON_RUNFILES_DEBUG: pkgdatadir exit, returning: %s\n", datadir);
	return datadir;
}

static char *resolve_m4_via_rlocation(const std::string &key) {
	fprintf(stderr, "BISON_RUNFILES_DEBUG: m4 calling Rlocation(%s)\n", key.c_str());
	std::string result = bazel_runfiles->ptr->Rlocation(key);
	fprintf(stderr, "BISON_RUNFILES_DEBUG: m4 Rlocation returned: %s\n", result.c_str());
	if (result.empty()) {
		fprintf(stderr, "BISON_RUNFILES_DEBUG: m4 Rlocation returned empty\n");
		return nullptr;
	}
	char *m4path = strdup(result.c_str());
#ifdef _WIN32
	DWORD attrs = GetFileAttributesA(m4path);
	if (attrs == INVALID_FILE_ATTRIBUTES) {
		fprintf(stderr, "BISON_RUNFILES_DEBUG: m4 file NOT found at %s (GetLastError=%lu)\n", m4path, GetLastError());
	} else {
		fprintf(stderr, "BISON_RUNFILES_DEBUG: m4 file exists at %s (attrs=0x%lx)\n", m4path, attrs);
	}
	fflush(stderr);
#endif
	fprintf(stderr, "BISON_RUNFILES_DEBUG: m4 exit, returning: %s\n", m4path);
	return m4path;
}

char *bazel_runfiles_m4() {
	fprintf(stderr, "BISON_RUNFILES_DEBUG: m4 enter, bazel_runfiles=%s\n", bazel_runfiles ? "OK" : "NULL");
	if (bazel_runfiles == nullptr) {
		fprintf(stderr, "BISON_RUNFILES_DEBUG: m4 exit, returning NULL (no runfiles)\n");
		return nullptr;
	}

	const char *runfiles_m4_cstr = getenv("BISON_BAZEL_RUNFILES_M4");
	fprintf(stderr, "BISON_RUNFILES_DEBUG: m4 BISON_BAZEL_RUNFILES_M4=%s\n", safe(runfiles_m4_cstr));
	if (runfiles_m4_cstr != nullptr) {
		std::string runfiles_m4(runfiles_m4_cstr);
		std::string path;
		if (runfiles_m4.find("../") == 0) {
			path = runfiles_m4.substr(3);
		} else {
			path = std::string(BAZEL_CURRENT_REPOSITORY) + "/" + runfiles_m4;
		}
		char *result = resolve_m4_via_rlocation(path);
		if (result != nullptr) return result;
	}

	const char *m4_env = getenv("M4");
	fprintf(stderr, "BISON_RUNFILES_DEBUG: m4 M4=%s\n", safe(m4_env));
	if (m4_env != nullptr) {
		std::string m4_path(m4_env);
		std::string marker(".runfiles/");
		size_t pos = m4_path.find(marker);
		if (pos != std::string::npos) {
			std::string key = m4_path.substr(pos + marker.size());
			fprintf(stderr, "BISON_RUNFILES_DEBUG: m4 extracted Rlocation key from M4: %s\n", key.c_str());
			char *result = resolve_m4_via_rlocation(key);
			if (result != nullptr) return result;
		}
	}

	fprintf(stderr, "BISON_RUNFILES_DEBUG: m4 exit, returning NULL (no m4 found)\n");
	return nullptr;
}

void bazel_check_heap(const char *where) {
#ifdef _WIN32
	int result = _heapchk();
	if (result == _HEAPOK || result == _HEAPEMPTY) {
		fprintf(stderr, "BISON_RUNFILES_DEBUG: heap OK at %s\n", where);
	} else {
		fprintf(stderr, "BISON_RUNFILES_DEBUG: HEAP CORRUPT at %s (_heapchk=%d)\n", where, result);
	}
	fflush(stderr);
#endif
}

}
