import os
import sys
import subprocess

from python.runfiles import Create


def main():
    runfiles = Create()
    binary = runfiles.Rlocation(sys.argv[1])
    env = dict(os.environ) | runfiles.EnvVars()
    subprocess.run([binary, "--help"], env=env, check=True)


assert __name__ == "__main__"
main()
