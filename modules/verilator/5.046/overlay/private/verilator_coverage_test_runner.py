"""Cross-platform test runner for verilator_coverage_internal_test.

Reads a JSON config from the path given by the VERILATOR_COVERAGE_TEST_CONFIG
environment variable (runfiles-relative), runs the coverage tool, and compares
the output against an expected golden file.
"""

import difflib
import json
import os
import subprocess
import sys

from python.runfiles import Runfiles


def main():
    r = Runfiles.Create()

    config_rel = os.environ.get("VERILATOR_COVERAGE_TEST_CONFIG")
    if not config_rel:
        print("VERILATOR_COVERAGE_TEST_CONFIG not set", file=sys.stderr)
        return 1

    with open(r.Rlocation(config_rel)) as f:
        config = json.load(f)

    coverage = r.Rlocation(config["coverage"])
    srcs = [r.Rlocation(s) for s in config["srcs"]]
    expected = r.Rlocation(config["expected"])
    out = os.path.join(os.environ["TEST_TMPDIR"], "coverage.info")

    env = dict(os.environ, **r.EnvVars())
    result = subprocess.run([coverage, "--write-info", out] + srcs, env=env)
    if result.returncode != 0:
        print("verilator_coverage exited with code", result.returncode, file=sys.stderr)
        return result.returncode

    with open(expected) as ef:
        expected_lines = ef.readlines()
    with open(out) as of:
        output_lines = of.readlines()

    if expected_lines != output_lines:
        diff = difflib.unified_diff(
            expected_lines,
            output_lines,
            fromfile="expected",
            tofile="actual",
        )
        sys.stderr.writelines(diff)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
