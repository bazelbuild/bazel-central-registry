"Version string utilities."

# Upstream's VERSION file (`git describe --long --abbrev=40`), which configure reads. A constant because Starlark cannot
# read a source file while BUILD files load.
UPSTREAM_VERSION = "5.3.0-0-g54eaed1d8b56b1aa528be3bdd1877e59c56fa90c"

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
