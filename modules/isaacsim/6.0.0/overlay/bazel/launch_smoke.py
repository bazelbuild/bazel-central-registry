"""Runs inside Kit (`kit --exec`) once the app has started, then quits.

Two things are checked from in here, where the answers are actually knowable:

* which isaacsim.* extensions are *enabled* -- an app whose extension resolution
  failed still reaches this point, just without them, so counting them is what
  makes this a launch test rather than a "the binary ran" test;
* where each enabled extension was loaded from -- Kit downloads what it is
  missing, and a run that quietly pulled a package into its user data directory
  is not the hermetic run it looks like.
"""

import os

import omni.kit.app

_SENTINEL = "ISAACSIM_LAUNCH_OK"


def main() -> None:
    app = omni.kit.app.get_app()
    manager = app.get_extension_manager()

    enabled = [ext for ext in manager.get_extensions() if ext.get("enabled")]
    isaacsim_exts = sorted(
        ext.get("id") or ext["name"]
        for ext in enabled
        if ext["name"].startswith("isaacsim.")
    )
    for ext_id in isaacsim_exts:
        print(f"  enabled: {ext_id}")

    # Everything Kit fetches for itself ends up under the user data directory,
    # which the launcher points at the test's scratch space.
    home = os.path.realpath(os.environ.get("HOME", "~"))
    downloaded = sorted(
        f"{ext.get('id') or ext['name']} <- {ext['path']}"
        for ext in enabled
        if ext.get("path") and os.path.realpath(ext["path"]).startswith(home + os.sep)
    )
    if downloaded:
        print(f"NOT HERMETIC: {len(downloaded)} extension(s) came from outside the build:")
        for line in downloaded:
            print(f"  {line}")
        app.post_quit(1)
        return

    print(
        f"{_SENTINEL} isaacsim_extensions_enabled={len(isaacsim_exts)} "
        f"extensions_enabled={len(enabled)}",
    )
    app.post_quit(0)


main()
