libgps (modules/libgps)

What this file documents
- How to regenerate generated sources used by the overlay: ais_json.i and gps_maskdump.c
- Why Bazel uses py_binary + genrule for generation
- How to update integrity after modifying overlay files

Regenerating ais_json.i
- From repository root run:

  mkdir -p modules/libgps/3.27.5/overlay
  bazel run //modules/libgps/3.27.5/overlay:jsongen -- --ais --target=parser > modules/libgps/3.27.5/overlay/ais_json.i

Regenerating libgps/gps_maskdump.c
- From repository root run (the genrule rewrites ../include/ to include/):

  mkdir -p modules/libgps/3.27.5/overlay/libgps
  bazel run //modules/libgps/3.27.5/overlay:maskaudit -- -c . | sed 's|../include/|include/|g' > modules/libgps/3.27.5/overlay/libgps/gps_maskdump.c

Notes
- These generator binaries are provided in the overlay as py_binary targets (jsongen and maskaudit) to avoid depending on system Python and to make generation reproducible.
- The repository intentionally avoids checking in generated outputs (ais_json.i) — generation happens at build time via genrule. If you prefer a checked-in artifact, explain the tradeoffs in a PR.

After changing overlay files
- Run: bazel run //tools:update_integrity
- Verify changes locally with the presubmit reproducer: //tools:bcr_validation or by running bazel build targets in modules/libgps/3.27.5/presubmit.yml

If you are bumping the libgps version
- Check upstream SCons for how jsongen.py and maskaudit.py are invoked to ensure parity

