load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@rules_license//rules:license.bzl", "license")

package(
    default_applicable_licenses = [":license"],
    default_visibility = ["//visibility:public"],
)

exports_files(["LICENSE"])

license(
    name = "license",
    package_name = "poco",
    license_kinds = ["@rules_license//licenses/spdx:BSL-1.0"],
    license_text = "LICENSE",
    package_url = "https://github.com/pocoproject/poco",
)

cc_library(
    name = "PocoFoundation",
    srcs = glob(
        [
            "Foundation/src/*.cpp",
            # Bundled utf8proc, used by UTF8String.cpp unless POCO_UNBUNDLED.
            "Foundation/src/utf8proc.c",
        ],
        exclude = [
            "Foundation/src/DirectoryIterator_*.cpp",
            "Foundation/src/Environment_*.cpp",
            "Foundation/src/Event_*.cpp",
            "Foundation/src/EventLogChannel.cpp",
            "Foundation/src/FPEnvironment_*.cpp",
            "Foundation/src/FileStream_*.cpp",
            "Foundation/src/FileStreamRWLock*.cpp",
            "Foundation/src/File_*.cpp",
            "Foundation/src/Mutex_*.cpp",
            "Foundation/src/NamedEvent_*.cpp",
            "Foundation/src/NamedMutex_*.cpp",
            "Foundation/src/Path_*.cpp",
            "Foundation/src/PipeImpl_*.cpp",
            "Foundation/src/Process_*.cpp",
            "Foundation/src/RWLock_*.cpp",
            "Foundation/src/Semaphore_*.cpp",
            "Foundation/src/SharedLibrary_*.cpp",
            "Foundation/src/SharedMemory_*.cpp",
            "Foundation/src/Thread_*.cpp",
            "Foundation/src/Timezone_*.cpp",
            "Foundation/src/Var*.cpp",
            "Foundation/src/WindowsConsoleChannel.cpp",
        ],
    ),
    hdrs = glob(
        [
            "Foundation/include/Poco/*.h",
            "Foundation/src/*.cc",
            "Foundation/src/*.h",
            "Foundation/src/DirectoryIterator_*.cpp",
            "Foundation/src/Environment_*.cpp",
            "Foundation/src/Event_*.cpp",
            "Foundation/src/FPEnvironment_*.cpp",
            "Foundation/src/FileStream_*.cpp",
            "Foundation/src/File_*.cpp",
            "Foundation/src/Mutex_*.cpp",
            "Foundation/src/NamedEvent_*.cpp",
            "Foundation/src/NamedMutex_*.cpp",
            "Foundation/src/Path_*.cpp",
            "Foundation/src/PipeImpl_*.cpp",
            "Foundation/src/Process_*.cpp",
            "Foundation/src/RWLock_*.cpp",
            "Foundation/src/Semaphore_*.cpp",
            "Foundation/src/SharedLibrary_*.cpp",
            "Foundation/src/SharedMemory_*.cpp",
            "Foundation/src/Thread_*.cpp",
            "Foundation/src/Timezone_*.cpp",
            # Textually included by utf8proc.c.
            "Foundation/src/utf8proc_data.c",
        ],
    ),
    includes = ["Foundation/include"],
    # SharedMemory_POSIX.cpp uses shm_open/shm_unlink, which live in librt
    # before glibc 2.34.
    linkopts = select({
        "@bazel_tools//src/conditions:linux": ["-lrt"],
        "//conditions:default": [],
    }),
    # Checksum.cpp, DeflatingStream.cpp and InflatingStream.cpp use zlib. Like
    # pcre2, it comes from the BCR module rather than Poco's bundled copy.
    deps = [
        "@pcre2",
        "@zlib",
    ],
)

cc_library(
    name = "PocoNet",
    srcs = glob(["Net/src/*.cpp"]),
    hdrs = glob(["Net/include/Poco/Net/*.h"]),
    includes = [
        "Foundation/include",
        "Net/include",
    ],
    deps = [":PocoFoundation"],
)
