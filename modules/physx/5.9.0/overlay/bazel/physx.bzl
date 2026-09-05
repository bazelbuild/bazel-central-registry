"""Building the PhysX SDK the way its CMake build does.

Upstream splits the SDK into fifteen CMake targets that are compiled with one
shared preprocessor configuration and linked as a group. `physx_component`
is that shape: one target per CMake target, same sources, same defines.

The sources are globbed rather than listed. Upstream enumerates them, but the
directory layout is regular enough that a glob reproduces every list exactly --
checked target by target against `physx/source/compiler/cmake/*.cmake` -- given
two adjustments: platform code lives in `unix/` and `windows/` subdirectories,
so `windows/` is excluded, and four targets draw from a second directory, which
//BUILD.bazel lists. The one file the CMake lists name that a glob does not
find, `internal/device/linux/PhysXIndicatorLinux.cpp`, is not in the public
source release at all.
"""

load("@rules_cc//cc:cc_library.bzl", "cc_library")

# Upstream's `checked` configuration: asserts and parameter validation on,
# optimised. Assembled from PHYSX_LINUX_COMPILE_DEFS and
# PHYSX_LINUX_CHECKED_COMPILE_DEFS in
# physx/source/compiler/cmake/linux/CMakeLists.txt.
#
# This is the configuration the Omniverse packman `physx` package is built with
# and that Isaac Sim's extensions link against, and matching it is not
# cosmetic. A process that embeds PhysX more than once -- Omniverse Kit does,
# once per extension that touches physics -- only works while every copy agrees
# on its own struct layouts, and `PX_SUPPORT_GPU_PHYSX` changes them. Objects
# handed across a module boundary by two disagreeing copies do not fail at link
# time.
#
# DISABLE_CUDA_PHYSX is deliberately absent: leaving it undefined is what turns
# PX_SUPPORT_GPU_PHYSX on, and GPU PhysX is what omni.physx runs.
PHYSX_DEFINES = [
    "NDEBUG",
    "PX_CHECKED=1",
    "PX_NVTX=0",
    "PX_PHYSX_STATIC_LIB",
    "PX_PUBLIC_RELEASE=1",
    "PX_SUPPORT_OMNI_PVD=1",
    "PX_SUPPORT_PVD=1",
]

# The union of every target's PRIVATE TARGET_INCLUDE_DIRECTORIES, minus the ones
# naming directories the public source release does not ship (upstream's CMake
# lists several platform include directories that are not there). Upstream gives
# each target a minimal set; sharing one list costs nothing -- an include
# directory nothing includes from changes no output -- and keeps this readable
# next to the CMake files.
PHYSX_INTERNAL_INCLUDES = [
    # The source root itself: the OmniPVD glue reaches the writer as
    # "../pvdruntime/include/OmniPvdWriter.h", relative to here.
    "physx/source",
    "physx/source/common/include",
    "physx/source/common/src",
    "physx/source/cudamanager/include",
    "physx/source/geomutils/include",
    "physx/source/geomutils/src",
    "physx/source/geomutils/src/ccd",
    "physx/source/geomutils/src/common",
    "physx/source/geomutils/src/contact",
    "physx/source/geomutils/src/convex",
    "physx/source/geomutils/src/distance",
    "physx/source/geomutils/src/gjk",
    "physx/source/geomutils/src/hf",
    "physx/source/geomutils/src/intersection",
    "physx/source/geomutils/src/mesh",
    "physx/source/geomutils/src/pcm",
    "physx/source/geomutils/src/sweep",
    "physx/source/gpucommon/include",
    "physx/source/lowlevel/api/include",
    "physx/source/lowlevel/common/include",
    "physx/source/lowlevel/common/include/collision",
    "physx/source/lowlevel/common/include/pipeline",
    "physx/source/lowlevel/common/include/utils",
    "physx/source/lowlevel/software/include",
    "physx/source/lowlevelaabb/include",
    "physx/source/lowlevelaabb/src",
    "physx/source/lowleveldynamics/include",
    "physx/source/lowleveldynamics/shared",
    "physx/source/lowleveldynamics/src",
    "physx/source/physx/src",
    "physx/source/physxextensions/src",
    "physx/source/physxextensions/src/serialization/Binary",
    "physx/source/physxextensions/src/serialization/File",
    "physx/source/physxextensions/src/serialization/Xml",
    "physx/source/physxgpu/include",
    "physx/source/physxmetadata/core/include",
    "physx/source/physxmetadata/extensions/include",
    "physx/source/pvd/include",
    # Under the SDK root rather than source/, which is why it looks out of
    # place: the OmniPVD stream writer PhysX records to.
    "physx/pvdruntime/include",
    "physx/source/scenequery/include",
    "physx/source/simulationcontroller/include",
    "physx/source/simulationcontroller/src",
]

def physx_component(name, dirs, deps = []):
    """One CMake target of the SDK.

    Args:
        name: Target name; the CMake target, lowercased.
        dirs: Source directories, as the CMake file lists them.
        deps: The components it compiles and links against.
    """
    cc_library(
        name = name,
        srcs = native.glob(
            [d + "/**/*.cpp" for d in dirs],
            exclude = ["physx/source/**/windows/**"],
        ) + native.glob(
            # The private headers the components share freely; they are found
            # through PHYSX_INTERNAL_INCLUDES rather than declared per target.
            [
                "physx/pvdruntime/include/**/*.h",
                "physx/source/**/*.h",
            ],
            exclude = ["physx/source/**/windows/**"],
        ),
        defines = PHYSX_DEFINES,
        includes = PHYSX_INTERNAL_INCLUDES,
        # The platform sources globbed above are the unix/ ones.
        target_compatible_with = ["@platforms//os:linux"],
        deps = deps + [Label("//:headers")],
    )
