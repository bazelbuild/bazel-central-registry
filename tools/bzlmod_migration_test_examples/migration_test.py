import unittest
import subprocess
import os
import sys
from unittest import main


class BazelBuildTest(unittest.TestCase):
    """
    A test suite for verifying Bzlmod migration tool for maven and python extensions.
    """

    _CREATED_FILES = [
        "MODULE.bazel",
        "MODULE.bazel.lock",
        "WORKSPACE.bzlmod",
        "migration_info.md",
        "query_direct_deps",
        "resolved_deps.py",
        "extension_for_",
    ]

    def _cleanup_created_files(self):
        """
        Remove files which were created by migration tool.
        """
        my_dir = os.getcwd()
        for fname in os.listdir(my_dir):
            if any(fname.startswith(p) for p in self._CREATED_FILES):
                os.remove(os.path.join(my_dir, fname))

    def _run_command(self, command):
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
            self.fail(f"Command failed with exit code {e.returncode}:\nSTDOUT:\n{e.stdout}\nSTDERR:\n{e.stderr}")

    def _print_message(self, message):
        GREEN = "\033[92m"
        RESET = "\033[0m"
        print(f"{GREEN}{message}{RESET}")

    def test_migration_of_module_deps(self):
        self._cleanup_created_files()
        targets = "//..."

        # Verify bazel build is successful with enabled workspace
        print("\n--- Running bazel build with enabled workspace ---")
        result = self._run_command(["bazel", "build", "--nobuild", "--enable_workspace", "--noenable_bzlmod", targets])
        assert result.returncode == 0
        self._print_message("Success.")

        # Run migration script
        print("\n--- Running migration script ---")
        result = self._run_command([sys.executable, "../../migrate_to_bzlmod.py", "-t=" + targets])
        assert result.returncode == 0
        assert os.path.exists(
            "migration_info.md"
        ), "File 'migration_info.md' should be created during migration, but it doesn't exist."
        self._print_message("Success.")

        # Verify MODULE.bazel was created successfully
        print("\n--- Running bazel build with enabled bzlmod ---")
        result = self._run_command(["bazel", "build", "--noenable_workspace", "--enable_bzlmod", targets])
        assert result.returncode == 0
        self._print_message("Success.")

        self._cleanup_created_files()


if __name__ == "__main__":
    main()
