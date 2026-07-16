import unittest
import subprocess
import os
import sys
from unittest import main


class BazelBuildTest(unittest.TestCase):
    """
    A test suite for verifying Bzlmod migration tool for python extensions.
    """

    _CREATED_FILES = [
        "MODULE.bazel",
        "MODULE.bazel.lock",
        "WORKSPACE.bzlmod",
        "migration_info.md",
        "query_direct_deps",
        "resolved_deps.py",
    ]

    def _cleanup_created_files(self):
        """
        Remove files which were created by migration tool.
        """
        for file_name in self._CREATED_FILES:
            file_path = os.path.join(os.getcwd(), file_name)
            if os.path.exists(file_path):
                os.remove(file_path)

    def _run_command(self, command, expected_failure=False):
        """
        Helper function to run a command and return its result.
        It captures `stdout`, `stderr` and `returncode` for debugging.
        """
        try:
            result = subprocess.run(command, capture_output=True, text=True, check=True)
            return result
        except FileNotFoundError:
            self.fail("Command not found.")
        except subprocess.CalledProcessError as e:
            if expected_failure:
                return e
            self.fail(f"Command failed with exit code {e.returncode}:\nSTDOUT:\n{e.stdout}\nSTDERR:\n{e.stderr}")

    def _print_message(self, message):
        GREEN = "\033[92m"
        RESET = "\033[0m"
        print(f"{GREEN}{message}{RESET}")

    def modify_build_file(self, old, new):
        with open("BUILD", "r") as f:
            original_content = f.read()
        with open("BUILD", "w") as f:
            modified_content = str(original_content).replace(old, new)
            f.write(modified_content)

    def test_migration_of_module_deps(self):
        self._cleanup_created_files()
        try:
            targets = "//..."

            # Verify bazel build is successful with enabled workspace
            print("\n--- Running bazel build with enabled workspace ---")
            result = self._run_command(
                ["bazel", "build", "--nobuild", "--enable_workspace", "--noenable_bzlmod", targets]
            )
            assert result.returncode == 0
            self._print_message("Success.")

            # Run migration script
            print("\n--- Running migration script ---")
            result = self._run_command(
                [sys.executable, "../../migrate_to_bzlmod.py", "-t=//..."], expected_failure=True
            )
            assert result.returncode == 1
            assert "Update pip dependency reference from" in result.stderr
            assert os.path.exists(
                "migration_info.md"
            ), "File 'migration_info.md' should be created during migration, but it doesn't exist."

            self._print_message("Expected error: User need to modify pypi reference.")

            # Verify Bzlmod have error
            print("\n--- Running bazel build with enabled bzlmod ---")
            result = self._run_command(
                ["bazel", "build", "--noenable_workspace", "--enable_bzlmod", "//..."], expected_failure=True
            )
            assert result.returncode == 1
            self._print_message("Expected error: Manual change for pypi reference is needed.")

            # Modify BUILD file
            self.modify_build_file("@pypi_yamllint//:rules_python_wheel_entry_point_yamllint", "@pypi//yamllint")
            print("\n--- Modifying BUILD file ---")
            self._print_message("Success.")

            # Rerun migration script
            print("\n--- Running migration script ---")
            result = self._run_command([sys.executable, "../../migrate_to_bzlmod.py", "-t=//..."])
            assert result.returncode == 0
            self._print_message("Success.")

            # Verify MODULE.bazel was created successfully
            print("\n--- Running bazel build with enabled bzlmod ---")
            result = self._run_command(["bazel", "build", "--noenable_workspace", "--enable_bzlmod", "//..."])
            assert result.returncode == 0
            self._print_message("Success.")
        finally:
            # Restore BUILD file to the initial content
            self.modify_build_file("@pypi//yamllint", "@pypi_yamllint//:rules_python_wheel_entry_point_yamllint")
            self._cleanup_created_files()


if __name__ == "__main__":
    main()
