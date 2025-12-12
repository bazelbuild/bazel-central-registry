"""Add a new Boost version to the Bazel Central Registry.

Automates the process of adding a new Boost release or BCR revision.

Process:
    1. Copies boost.* modules from closest previous version
    2. Updates MODULE.bazel files with new version and dependencies
    3. Runs `//tools:update_integrity` for all boost.* modules
    4. Generates boost meta-module with all modules

Configuration:
    - DEPENDENCY_VERSIONS: Standardized versions for common deps
    - LAST_AVAILABLE_VERSIONS: Proactively skip discontinued modules
"""

import argparse
import json
import logging
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

# Desired versions for common dependencies
# When updating MODULE.bazel files, bazel_dep declarations matching these keys
# will be updated to the specified versions
DEPENDENCY_VERSIONS = {
    "rules_cc": "0.2.4",
    "platforms": "1.0.0",
    "bazel_skylib": "1.8.2",
    "boringssl": "0.20251002.0",
    "bzip2": "1.0.8.bcr.3",
    "onetbb": "2022.2.0",
    "openssl": "3.3.1.bcr.9",
    "zlib": "1.3.1.bcr.7",
    "zstd": "1.5.7",
}

# Last available versions for discontinued modules
# If adding a version newer than the value here, skip creating that module
# BCR versions are compared using their base version (1.89.0.bcr.1 -> 1.89.0)
LAST_AVAILABLE_VERSIONS = {
    "boost.compatibility": "1.83.0",
    "boost.pin_version": "1.83.0",
}

BUILD_CONTENT = """\
load("@rules_license//rules:license.bzl", "license")

license(
    name = "license",
    license_kinds = ["@rules_license//licenses/spdx:BSL-1.0"],
    license_text = "LICENSE_1_0.txt",
)
"""

PRESUBMIT_CONTENT = """\
matrix:
  platform:
    - ubuntu2204
  bazel: [7.*, 8.*]
tasks:
  verify_targets:
    name: Verify build targets
    platform: ${{ platform }}
    bazel: ${{ bazel }}
    build_targets:
      - '//...'
"""

MODULE_TEMPLATE = """\
module(
    name = "boost",
    version = "{version}",
    bazel_compatibility = [">=7.6.0"],
    compatibility_level = {compatibility_level},
)

bazel_dep(name = "rules_license", version = "1.0.0")
"""

BAZEL_IGNORE = """\
doc
libs
more
status
tools
"""

# Historical note: Previously, the compatibility_level was different for every minor version of
# boost. Version 1.89.0 for example was given the compatibility level of 108900.
# This is not expected to change unless / until boost has a major version release.
# For more discussion, see:
# https://github.com/bazelbuild/bazel-central-registry/discussions/6511
COMPATIBILITY_LEVEL = 0


class Semver:
    """Semantic version with BCR support.

    Versions with BCR suffix are considered greater than their base version:
    1.89.0.bcr.1 > 1.89.0
    """

    def __init__(self, version: str) -> None:
        """Parse a version string like '1.89.0' or '1.89.0.bcr.1'."""
        self.original = version

        # Split into base and BCR parts
        if ".bcr." in version:
            parts = version.split(".bcr.")
            self.base = parts[0]
            self.bcr = int(parts[1])
        else:
            self.base = version
            self.bcr = None

        # Parse base version (major.minor.patch)
        base_parts = self.base.split(".")
        self.major = int(base_parts[0]) if len(base_parts) > 0 else 0
        self.minor = int(base_parts[1]) if len(base_parts) > 1 else 0
        self.patch = int(base_parts[2]) if len(base_parts) > 2 else 0

    def without_bcr(self) -> "Semver":
        """Return a new Semver object without BCR suffix."""
        return Semver(self.base)

    def __str__(self) -> str:
        return self.original

    def __repr__(self) -> str:
        return f"Semver('{self.original}')"

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Semver):
            return NotImplemented
        return (self.major, self.minor, self.patch, self.bcr) == (
            other.major,
            other.minor,
            other.patch,
            other.bcr,
        )

    def __lt__(self, other: object) -> bool:
        if not isinstance(other, Semver):
            return NotImplemented

        # Compare base version first
        base_cmp = (self.major, self.minor, self.patch)
        other_base_cmp = (other.major, other.minor, other.patch)

        if base_cmp != other_base_cmp:
            return base_cmp < other_base_cmp

        # If base versions are equal, compare BCR
        # None (no BCR) < any BCR number
        if self.bcr is None and other.bcr is None:
            return False
        if self.bcr is None:
            return True  # 1.89.0 < 1.89.0.bcr.1
        if other.bcr is None:
            return False  # 1.89.0.bcr.1 > 1.89.0
        return self.bcr < other.bcr

    def __le__(self, other: object) -> bool:
        return self == other or self < other

    def __gt__(self, other: object) -> bool:
        return not self <= other

    def __ge__(self, other: object) -> bool:
        return not self < other


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description=__doc__)

    parser.add_argument("version", type=str, help="The version of boost to add.")
    parser.add_argument("--verbose", action="store_true", help="Enable verbose logging for debugging.")

    return parser.parse_args()


def find_closest_version(target_version: str, available_versions: list[str]) -> str:
    """Find the closest existing version to copy from.

    For BCR versions (X.Y.Z.bcr.N):
    - First tries to find the latest BCR version of the same base release (X.Y.Z.bcr.M where M < N)
    - If not found, tries the base version (X.Y.Z)
    - Falls back to closest lower version

    Examples:
    - 1.89.0.bcr.1 -> prefers 1.89.0
    - 1.89.0.bcr.2 -> prefers 1.89.0.bcr.1, then 1.89.0
    """
    if not available_versions:
        raise ValueError("available_versions cannot be empty.")

    target = Semver(target_version)
    available_sorted = sorted(available_versions, key=lambda v: Semver(v))

    # Check if target is a BCR version
    if target.bcr is not None:
        # Find all BCR versions of the same base release
        same_base_bcr = [v for v in available_versions if v.startswith(target.base + ".bcr.") and Semver(v) < target]

        if same_base_bcr:
            # Return the latest BCR version of the same base
            return sorted(same_base_bcr, key=lambda v: Semver(v))[-1]

        # If no BCR versions, try the base version
        if target.base in available_versions:
            return target.base

    # Try to find the closest lower version
    lower = [v for v in available_sorted if Semver(v) < target]
    if lower:
        return lower[-1]

    # No lower version found - cannot copy from a newer version!
    raise ValueError(
        f"Cannot find an older version to copy from for {target_version}. "
        f"Available versions: {', '.join(available_sorted)}. "
        f"Cannot copy from a newer version to an older version."
    )


def update_version_in_content(content: str, old_version: str, new_version: str) -> str:
    """Update version strings in content.

    Updates:
    - Module version = "old" -> version = "new"
    - boost-{old} tags -> boost-{new}
    - ALL boost.* dependency versions -> new_version (ensures consistency)
    - Common dependencies -> DEPENDENCY_VERSIONS
    """
    # Replace version = "old"
    content = re.sub(
        rf'(version\s*=\s*["\']){re.escape(old_version)}(["\'])',
        rf"\g<1>{new_version}\g<2>",
        content,
    )

    # Replace boost-old tags
    content = content.replace(f"boost-{old_version}", f"boost-{new_version}")

    # Update ALL boost.* dependency versions to new_version
    # This ensures all boost dependencies are consistently at the target version
    # Handles both single-line and multi-line bazel_dep declarations
    # Matches: bazel_dep(name = "boost.XXX", version = "ANY_VERSION")
    content = re.sub(
        r'(bazel_dep\([^)]*name\s*=\s*"boost\.[^"]*"[^)]*version\s*=\s*")[^"]*(")',
        rf"\g<1>{new_version}\g<2>",
        content,
        flags=re.DOTALL,
    )

    # Update common dependencies to desired versions
    for dep_name, dep_version in DEPENDENCY_VERSIONS.items():
        # Match bazel_dep with this name and update its version
        # Handles both formats: bazel_dep(name = "X", version = "Y") and bazel_dep(name="X", version="Y")
        content = re.sub(
            rf'(bazel_dep\(\s*name\s*=\s*["\']' + re.escape(dep_name) + r'["\'].*?version\s*=\s*["\'])[^"\']*(["\'])',
            rf"\g<1>{dep_version}\g<2>",
            content,
        )

    if "compatibility_level" in content:
        content = re.sub(r"(compatibility_level\s*=\s*)\d+", rf"\g<1>{COMPATIBILITY_LEVEL}", content)

    return content


def update_source_json(content: str, new_version: str) -> str:
    """Update source.json content with new version."""
    # Extract base version (remove .bcr.X suffix)
    base_version = new_version.split(".bcr.")[0]

    # Update URL
    content = re.sub(r"boost-[\d.]+\.tar\.gz", f"boost-{base_version}.tar.gz", content)

    # Clear integrity
    content = re.sub(r'"integrity":\s*"[^"]*"', '"integrity": ""', content)

    # Update strip_prefix
    content = re.sub(r'boost-[\d.]+(?=")', f"boost-{base_version}", content)

    return content


def update_boost_meta_source_json(new_version: str) -> str:
    """Generate source.json for boost meta-module with correct URL and strip_prefix."""
    # Extract base version (remove .bcr.X suffix)
    base_version = new_version.split(".bcr.")[0]

    # The boost meta-module uses the boostorg/boost repo
    # URL pattern: https://github.com/boostorg/boost/archive/refs/tags/boost-{version}.tar.gz
    # strip_prefix: boost-boost-{version} (because archive extracts to boost-{tag} where tag is boost-{version})

    source_json = {
        "strip_prefix": f"boost-boost-{base_version}",
        "url": f"https://github.com/boostorg/boost/archive/refs/tags/boost-{base_version}.tar.gz",
        "overlay": {
            "BUILD.bazel": "sha256-PLACEHOLDER",
            "MODULE.bazel": "sha256-PLACEHOLDER",
        },
    }

    return json.dumps(source_json, indent=4) + "\n"


def has_any_files(directory: Path) -> bool:
    """Check if a directory tree contains any files (not just directories).

    Returns:
        True if at least one file exists in the tree, False if only directories
    """
    for item in directory.rglob("*"):
        if item.is_file():
            return True
    return False


def run_buildifier(module_paths: list[Path]) -> None:
    """Run buildifier to format and lint Bazel files in a directory.

    Args:
        module_paths: Directories to run buildifier on
    """
    subprocess.run(
        [
            "buildifier",
            "-lint=fix",
            "-mode=fix",
            "-warnings=all",
            "-r",
        ]
        + [str(path) for path in module_paths],
        capture_output=True,
        text=True,
        check=True,
    )


def run_buildifier_check(module_paths: list[Path], fix: bool = False) -> None:
    """Run buildifier in check mode on module directories.

    Args:
        module_paths: List of module version directories to check
        fix: If True, run buildifier in fix mode first to auto-fix issues

    Raises:
        subprocess.CalledProcessError: If buildifier finds issues
    """
    if not module_paths:
        return

    # Run buildifier in fix mode first if requested
    if fix:
        run_buildifier(module_paths)

    # Now run in check mode to verify
    logging.info("Running buildifier checks on %s modules...", len(module_paths))

    result = subprocess.run(
        [
            "buildifier",
            "-lint=warn",
            "-mode=check",
            "-warnings=all",
            "-r",
        ]
        + [str(path) for path in module_paths],
        stderr=subprocess.STDOUT,
        stdout=subprocess.PIPE,
        text=True,
        check=False,
    )

    if result.returncode:
        logging.error("Buildifier checks failed!")
        logging.error("%s", result.stdout)


def copy_and_update_directory(source_path: Path, target_path: Path, old_version: str, new_version: str) -> None:
    """Copy a version directory and update only specific version-related files.

    This preserves manual edits in BUILD.bazel, patches, and other files.
    Updates: All MODULE.bazel files (including in subdirs), source.json, presubmit.yml
    """
    # Clean up if target exists but contains only empty directories
    if target_path.exists():
        if not has_any_files(target_path):
            logging.debug("Removing empty directory tree: %s", target_path)
            shutil.rmtree(target_path)

    logging.debug("Copying from: %s to %s", source_path.name, target_path.name)
    shutil.copytree(source_path, target_path)

    # Update main MODULE.bazel, source.json, and presubmit.yml
    main_files_to_update = [
        target_path / "MODULE.bazel",
        target_path / "source.json",
        target_path / "presubmit.yml",
    ]

    for file_path in main_files_to_update:
        if file_path.exists() and file_path.is_file():
            try:
                content = file_path.read_text()

                if file_path.name == "source.json":
                    content = update_source_json(content, new_version)
                else:
                    content = update_version_in_content(content, old_version, new_version)

                if file_path.name == "MODULE.bazel":
                    content = ensure_meta_module_dep_exists_in_content(content, new_version)

                file_path.write_text(content, encoding="utf-8")
            except Exception as e:
                logging.warning("Could not update %s: %s", file_path, e)

    # Find and update ALL MODULE.bazel files in subdirectories (except overlay which is handled separately)
    # This catches additional MODULE.bazel files that may reference other boost modules
    for module_file in target_path.rglob("**/MODULE.bazel"):
        # Skip the main MODULE.bazel (already updated) and overlay/MODULE.bazel (handled separately)
        if module_file == target_path / "MODULE.bazel":
            continue
        if module_file == target_path / "overlay" / "MODULE.bazel":
            continue

        if module_file.is_file():
            try:
                content = module_file.read_text()
                content = update_version_in_content(content, old_version, new_version)
                module_file.write_text(content, encoding="utf-8")
                logging.debug("Updated %s", module_file.relative_to(target_path))
            except Exception as e:
                logging.warning("Could not update %s: %s", module_file, e)

    # Copy overlay/MODULE.bazel from main MODULE.bazel if it doesn't exist
    overlay_module = target_path / "overlay" / "MODULE.bazel"
    main_module = target_path / "MODULE.bazel"
    if overlay_module.exists():
        if overlay_module.is_symlink():
            logging.debug("Converting overlay/MODULE.bazel from symlink to copy")
        else:
            logging.debug("Overwriting existing overlay/MODULE.bazel")
        overlay_module.unlink()
    if main_module.exists():
        logging.debug("Copying MODULE.bazel to overlay/MODULE.bazel")
        shutil.copy2(main_module, overlay_module)
    else:
        logging.debug("Skipping creation of overlay/MODULE.bazel -- MODULE.bazel does not exist")

    run_buildifier([target_path])


def ensure_meta_module_dep_exists_in_content(content: str, version: str) -> str:
    bazel_meta_dep_regex = r'bazel_dep\s*\(\s*name\s*=\s*"boost"'
    if re.search(bazel_meta_dep_regex, content, flags=re.DOTALL):
        # The boost meta-module is already present as a dependency.
        return content

    # Insert a bazel_dep on the boost meta-module above the first dep that is found. This should be
    # alpha-sorted as-is because boost modules only depend on other boost modules.
    content_lines = content.splitlines(keepends=True)
    boost_meta_dep_str = f'bazel_dep(name = "boost", version = "{version}")\n'
    for i, line in enumerate(content_lines):
        if line.startswith("bazel_dep"):
            content_lines.insert(i, boost_meta_dep_str)
            return "".join(content_lines)

    # If this module didn't have any deps just insert our boost meta-module dep at the end.
    if content.endswith("\n"):
        return content + boost_meta_dep_str
    return content + "\n" + boost_meta_dep_str


def generate_meta_module_files(version: str, modules_dir: Path, boost_modules: list[str]) -> None:
    """Generate both main MODULE.bazel and overlay files for the boost meta-module.

    Args:
        version: The boost versIion to generate
        modules_dir: Path to the modules directory
        boost_modules: List of boost.* module names to include (already sorted)
    """
    boost_dir = modules_dir / "boost"
    version_dir = boost_dir / version

    if not boost_modules:
        raise ValueError("No boost.* modules provided for meta-module generation")

    # Generate main MODULE.bazel using template
    module_header = MODULE_TEMPLATE.format(version=version, compatibility_level=COMPATIBILITY_LEVEL)

    # Add bazel_dep for each boost module
    deps = [f'bazel_dep(name = "{module}", version = "{version}", repo_name = None)' for module in boost_modules]

    module_content = module_header + "\n".join(deps) + "\n"

    # Write main MODULE.bazel
    main_module_file = version_dir / "MODULE.bazel"
    main_module_file.write_text(module_content, encoding="utf-8")
    logging.debug("Generated MODULE.bazel (%s dependencies)", len(boost_modules))

    # Create overlay directory
    overlay_dir = version_dir / "overlay"
    overlay_dir.mkdir(parents=True, exist_ok=True)

    # Create bazelignore
    bazelignore = overlay_dir / ".bazelignore"
    bazelignore.write_text(BAZEL_IGNORE, encoding="utf-8")

    # Copy main MODULE.bazel to overlay
    overlay_module_file = overlay_dir / "MODULE.bazel"
    if overlay_module_file.exists() or overlay_module_file.is_symlink():
        overlay_module_file.unlink()
    shutil.copy2(main_module_file, overlay_module_file)
    logging.debug("Copied MODULE.bazel to overlay/MODULE.bazel")

    overlay_build_file = overlay_dir / "BUILD.bazel"
    overlay_build_file.write_text(BUILD_CONTENT, encoding="utf-8")

    # Run buildifier to format all generated Bazel files
    run_buildifier([version_dir])


def update_integrity(module: str, version: str, registry_root: Path) -> None:
    """Run bazel update_integrity for a module."""
    subprocess.run(
        [
            "bazel",
            "run",
            "//tools:update_integrity",
            "--",
            module,
            f"--version={version}",
        ],
        capture_output=True,
        text=True,
        cwd=registry_root,
        check=True,
    )


def find_repo_root() -> Path:
    """Locate the Bazel-Central-Registry repository root."""
    if "BUILD_WORKSPACE_DIRECTORY" in os.environ:
        return Path(os.environ["BUILD_WORKSPACE_DIRECTORY"])

    return Path(__file__).parent.parent.parent


def get_boost_modules(modules_dir: Path) -> list[str]:
    """Get all boost.* modules by reading their metadata.json files.

    Returns:
        List of module names (e.g., ["boost.algorithm", "boost.asio", ...])
    """
    boost_modules = []

    for module_dir in modules_dir.iterdir():
        if not module_dir.is_dir():
            continue
        if not module_dir.name.startswith("boost."):
            continue

        # Check if metadata.json exists and has versions
        metadata_file = module_dir / "metadata.json"
        if metadata_file.exists():
            try:
                with open(metadata_file, "r", encoding="utf-8") as f:
                    metadata = json.load(f)
                    # Only include if module has versions tracked
                    if metadata.get("versions"):
                        boost_modules.append(module_dir.name)
            except Exception as e:
                logging.warning("Could not read metadata for %s: %s", module_dir.name, e)

    return sorted(boost_modules)


def get_module_versions(module_path: Path) -> list[str]:
    """Get available versions for a module from its metadata.json.

    Returns:
        List of version strings from metadata.json, or empty list if not found
    """
    metadata_file = module_path / "metadata.json"
    if not metadata_file.exists():
        logging.warning("No metadata.json for %s", module_path.name)
        return []

    try:
        with open(metadata_file, "r", encoding="utf-8") as f:
            metadata = json.load(f)
            return metadata.get("versions", [])
    except Exception as e:
        logging.warning("Could not read metadata for %s: %s", module_path.name, e)
        return []


def main() -> None:
    """Main entry point for adding a new Boost version."""
    args = parse_args()

    # Check if buildifier is available
    if not shutil.which("buildifier"):
        logging.error("buildifier not found in PATH!")
        logging.error("Please install buildifier: https://github.com/bazelbuild/buildtools/releases")
        sys.exit(1)

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(levelname)s: %(message)s",
    )

    registry_root = find_repo_root()
    modules_dir = registry_root / "modules"
    boost_dir = modules_dir / "boost"

    logging.info("Adding Boost version %s", args.version)

    # Delete existing version if it exists (clean slate)
    target_path = boost_dir / args.version
    if target_path.exists():
        logging.debug("boost meta-module %s already exists. Deleting", args.version)
        shutil.rmtree(target_path)

    # Create directory structure
    target_path.mkdir(parents=True, exist_ok=True)

    # Generate source.json with correct URL and strip_prefix for boost meta-module
    (target_path / "source.json").write_text(update_boost_meta_source_json(args.version), encoding="utf-8")

    # Generate presubmit.yml for boost meta-module
    (target_path / "presubmit.yml").write_text(PRESUBMIT_CONTENT, encoding="utf-8")

    # Get all boost.* modules from metadata.json files
    boost_modules = get_boost_modules(modules_dir)

    logging.info("Found %s boost.* modules (from metadata.json)", len(boost_modules))

    modules_with_version = {}
    newly_created_paths = []
    needs_manual_creation = []

    # Get base version for comparison (remove .bcr.X suffix)
    base_version = args.version.split(".bcr.")[0]

    # Check all modules and copy over previous versions where necessary
    for module in boost_modules:
        # Check if this module is discontinued
        if module in LAST_AVAILABLE_VERSIONS:
            last_available = LAST_AVAILABLE_VERSIONS[module]
            # Compare base versions (ignore BCR suffixes)
            if Semver(base_version) > Semver(last_available).without_bcr():
                logging.debug("Skipping %s (discontinued after %s)", module, last_available)
                continue

        module_path = modules_dir / module
        module_versions = get_module_versions(module_path)
        tgt_path = module_path / args.version

        # Check if version already exists (either in metadata.json or as directory)
        if args.version in module_versions:
            # Module already has this version in metadata.json
            logging.debug("Retaining existing version: %s (in metadata.json)", module)
            modules_with_version[module] = False
            continue

        if tgt_path.exists() and has_any_files(tgt_path):
            # Directory exists with files but not in metadata.json yet
            logging.debug("Retaining existing version: %s (directory exists)", module)
            modules_with_version[module] = False
            continue

        # Need to create this version
        try:
            source_ver = find_closest_version(args.version, module_versions)
        except ValueError as e:
            logging.error("Cannot create %s version %s: %s", module, args.version, e)
            needs_manual_creation.append(module)
            continue

        src_path = module_path / source_ver

        logging.debug("Creating %s version %s from %s", module, args.version, source_ver)
        copy_and_update_directory(src_path, tgt_path, source_ver, args.version)
        modules_with_version[module] = True
        newly_created_paths.append(tgt_path)

    # Run buildifier checks on all newly created modules
    if newly_created_paths:
        run_buildifier_check(newly_created_paths, fix=True)

    # Update integrity for all boost.* modules that have this version
    logging.info(
        "Updating integrity for %s modules...",
        len([v for v in modules_with_version.values() if v]),
    )

    for module in modules_with_version:
        logging.info("Updating integrity: %s", module)
        update_integrity(module, args.version, registry_root)

    if needs_manual_creation:
        logging.error("The following modules need manual creation: %s", needs_manual_creation)
        sys.exit(1)

    # Generate boost meta-module with explicit list of modules
    # This list excludes discontinued modules and only includes verified modules
    logging.info("Generating boost meta-module...")
    generate_meta_module_files(args.version, modules_dir, sorted(modules_with_version.keys()))

    # Run buildifier check on boost meta-module
    run_buildifier_check([boost_dir / args.version], fix=True)

    # Update integrity for boost meta-module
    logging.info("Updating integrity for boost meta-module...")
    update_integrity("boost", args.version, registry_root)

    logging.info("Successfully added Boost version %s", args.version)


if __name__ == "__main__":
    main()
