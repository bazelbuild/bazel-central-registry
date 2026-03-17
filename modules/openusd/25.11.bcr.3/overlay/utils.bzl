def package_module_name(package):
    return package[:1].upper() + package[1:]

def package_local_defines(package, common_local_defines):
    return common_local_defines + [
        package.upper() + "_EXPORTS=1",
        "MFB_ALT_PACKAGE_NAME=" + package,
        "MFB_PACKAGE_MODULE=" + package_module_name(package),
        "MFB_PACKAGE_NAME=" + package,
    ]

def openusd_package_srcs(package, package_dirs, extra_patterns, extra_excludes, extra_srcs):
    package_dir = package_dirs[package]
    return native.glob(
        [package_dir + "/*.cpp"] + extra_patterns.get(package, []),
        exclude = [
            package_dir + "/module.cpp",
            package_dir + "/py*.cpp",
            package_dir + "/testenv/**",
            package_dir + "/wrap*.cpp",
        ] + extra_excludes.get(package, []),
    ) + extra_srcs.get(package, [])
