import sys

from nanobind.stubgen import StubGen

# Confirm that it doesn't crash.
StubGen(module=sys).get()
