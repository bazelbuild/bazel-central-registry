"""Cross-platform test runner for verilator_internal_test.

Reads a JSON config from the path given by the VERILATOR_INTERNAL_TEST_CONFIG
environment variable (runfiles-relative), sets up a working directory, and
invokes the Verilator binary with the configured arguments.
"""

import json
import os
import subprocess
import sys

from python.runfiles import Runfiles


def main():
    r = Runfiles.Create()

    config_rel = os.environ.get("VERILATOR_INTERNAL_TEST_CONFIG")
    if not config_rel:
        print("VERILATOR_INTERNAL_TEST_CONFIG not set", file=sys.stderr)
        return 1

    with open(r.Rlocation(config_rel)) as f:
        config = json.load(f)

    verilator = r.Rlocation(config["verilator"])
    srcs = [r.Rlocation(s) for s in config["srcs"]]
    inc_dirs = [r.Rlocation(d) for d in config["inc_dirs"]]
    verilator_args = config["verilator_args"]
    top_module = config["top_module"]

    env = dict(os.environ, **r.EnvVars())
    env["VERILATOR_ROOT"] = os.path.dirname(os.path.dirname(verilator))

    workdir = os.environ["TEST_TMPDIR"]
    os.makedirs(workdir, exist_ok=True)
    os.chdir(workdir)

    outdir = "obj_dir"
    os.makedirs(outdir, exist_ok=True)

    cmd = [verilator, "--Mdir", outdir, "-I" + outdir]
    cmd.extend(verilator_args)
    for d in inc_dirs:
        cmd.append("-I" + d)
    cmd.extend(srcs)
    cmd.extend(["--top-module", top_module])

    return subprocess.run(cmd, env=env).returncode


if __name__ == "__main__":
    sys.exit(main())
