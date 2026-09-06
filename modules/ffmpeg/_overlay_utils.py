"""Shared helpers for FFmpeg generator scripts.

Provides overlay-directory resolution from a ``--version`` flag so that
all generators use the same convention for locating version-specific
overlay files.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

SCRIPTS_DIR = Path(__file__).parent


def resolve_overlay_dir(version: str | None) -> Path:
    """Return the overlay directory for the given BCR module version.

    When *version* is ``None`` the latest version is read from
    ``metadata.json`` (last entry in the ``versions`` array).
    """
    if version is None:
        metadata_path = SCRIPTS_DIR / "metadata.json"
        try:
            metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
        except FileNotFoundError:
            print(
                f"Error: {metadata_path} not found; pass --version explicitly",
                file=sys.stderr,
            )
            sys.exit(1)
        versions = metadata.get("versions", [])
        if not versions:
            print("Error: no versions listed in metadata.json", file=sys.stderr)
            sys.exit(1)
        version = versions[-1]

    overlay = SCRIPTS_DIR / version / "overlay"
    if not overlay.is_dir():
        print(f"Error: overlay directory not found: {overlay}", file=sys.stderr)
        sys.exit(1)

    print(f"  overlay: {overlay}", file=sys.stderr)
    return overlay


def add_version_arg(parser) -> None:
    """Add a ``--version`` argument to *parser*."""
    parser.add_argument(
        "--version",
        default=None,
        help="BCR module version (e.g. 7.1.1.bcr.beta.5). Defaults to the latest version in metadata.json.",
    )
