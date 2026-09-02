#!/usr/bin/env python3
import os
import sys
import tempfile
from pathlib import Path

tools_dir = Path(__file__).parent
sys.path.insert(0, str(tools_dir))

from bcr_validation import BcrValidationResult, _validate_overlay_build_files


def test_skip_check_yml_has_author_association():
    workflow = tools_dir.parent / ".github" / "workflows" / "skip_check.yml"
    content = workflow.read_text()
    assert "author_association" in content, "skip_check.yml missing author_association condition"
    assert (
        "OWNER" in content and "MEMBER" in content and "COLLABORATOR" in content
    ), "skip_check.yml missing required permission checks"
    print("PASS: skip_check.yml contains author_association permission check")


def test_overlay_rejects_local_tags():
    with tempfile.TemporaryDirectory() as tmp:
        module_dir = Path(tmp)
        overlay_dir = module_dir / "overlay"
        overlay_dir.mkdir()
        build_file = overlay_dir / "BUILD.bazel"
        build_file.write_text('genrule(name = "x", tags = ["local"], outs = ["y"], cmd = "echo hi")')
        result = _validate_overlay_build_files(module_dir)
        assert (
            result == BcrValidationResult.NEED_BCR_MAINTAINER_REVIEW
        ), f"Expected NEED_BCR_MAINTAINER_REVIEW, got {result}"
        print('PASS: _validate_overlay_build_files rejects tags=["local"]')


def test_overlay_accepts_normal_build():
    with tempfile.TemporaryDirectory() as tmp:
        module_dir = Path(tmp)
        overlay_dir = module_dir / "overlay"
        overlay_dir.mkdir()
        build_file = overlay_dir / "BUILD.bazel"
        build_file.write_text('cc_library(name = "x", srcs = ["a.cc"])')
        result = _validate_overlay_build_files(module_dir)
        assert result == BcrValidationResult.GOOD, f"Expected GOOD, got {result}"
        print("PASS: _validate_overlay_build_files accepts normal overlay BUILD files")


def test_overlay_no_overlay_dir():
    with tempfile.TemporaryDirectory() as tmp:
        module_dir = Path(tmp)
        result = _validate_overlay_build_files(module_dir)
        assert result == BcrValidationResult.GOOD, f"Expected GOOD, got {result}"
        print("PASS: _validate_overlay_build_files returns GOOD when no overlay dir")


if __name__ == "__main__":
    test_skip_check_yml_has_author_association()
    test_overlay_rejects_local_tags()
    test_overlay_accepts_normal_build()
    test_overlay_no_overlay_dir()
    print("\nAll security fix tests passed.")
