def package_module_name(package):
    return package[:1].upper() + package[1:]

def package_local_defines(package, common_local_defines):
    return common_local_defines + [
        package.upper() + "_EXPORTS=1",
        "MFB_ALT_PACKAGE_NAME=" + package,
        "MFB_PACKAGE_MODULE=" + package_module_name(package),
        "MFB_PACKAGE_NAME=" + package,
    ]
