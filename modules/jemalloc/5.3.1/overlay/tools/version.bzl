"Version string utilities."

# Upstream's VERSION file (`git describe --long --abbrev=40`), which configure reads. A constant because Starlark cannot
# read a source file while BUILD files load.
UPSTREAM_VERSION = "5.3.1-0-g81034ce1f1373e37dc865038e1bc8eeecf559ce8"

def _parse_version(version):
    """Splits a VERSION string, `<major>.<minor>.<bugfix>-<nrev>-g<gid>`, into configure's components."""
    release, nrev, gid = version.split("-", 2)
    major, minor, bugfix = release.split(".")

    return struct(
        full = version,
        major = major,
        minor = minor,
        bugfix = bugfix,
        nrev = nrev,
        gid = gid.removeprefix("g"),
    )

# UPSTREAM_VERSION's components: full (the whole string), major, minor, bugfix, nrev and gid (without the "g").
VERSION = _parse_version(UPSTREAM_VERSION)
