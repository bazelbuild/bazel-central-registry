"""Run a Python generator and write its stdout to the declared output."""

from contextlib import redirect_stdout
from pathlib import Path
import runpy
import sys

output, script, *args = sys.argv[1:]
sys.argv[:] = [script, *args]
sys.path.insert(0, str(Path(script).parent))
with open(output, "w", encoding="utf-8", newline="\n") as stream:
    with redirect_stdout(stream):
        runpy.run_path(script, run_name="__main__")
