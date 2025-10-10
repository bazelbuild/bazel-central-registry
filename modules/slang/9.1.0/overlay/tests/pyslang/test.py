import pyslang
import os
import sys

test_dir = os.path.dirname(__file__)


def test_pyslang():
    """
    Import pyslang and show that we can load a syntax tree from an RTL file.
    """
    tree = pyslang.SyntaxTree.fromFile(f"{test_dir}/test_module.sv")
    mod = tree.root.members[0]
    if mod.header.name.value != "test_module":
        raise RuntimeError(f"Expected module name 'test_module', got '{mod.header.name.value}'")

    return 0


if __name__ == "__main__":
    sys.exit(test_pyslang())
