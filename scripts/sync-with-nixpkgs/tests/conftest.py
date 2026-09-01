import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))


@pytest.fixture
def trees(tmp_path):
    """A corepkgs and a nixpkgs root, with helpers to populate them."""

    corepkgs = tmp_path / "corepkgs"
    nixpkgs = tmp_path / "nixpkgs"
    corepkgs.mkdir()
    nixpkgs.mkdir()

    class Trees:
        root = corepkgs
        upstream = nixpkgs

        @staticmethod
        def _write(base, relative, text):
            path = base / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding="utf-8")
            return path

        def local(self, relative, text):
            return self._write(corepkgs, relative, text)

        def remote(self, relative, text):
            return self._write(nixpkgs, relative, text)

        def both(self, local_relative, remote_relative, local_text, remote_text):
            self.local(local_relative, local_text)
            self.remote(remote_relative, remote_text)

        @staticmethod
        def upstream_path(package):
            """Where PATH_MAPPINGS expects this package to live in nixpkgs."""
            return f"pkgs/by-name/{package[:2].lower()}/{package}/package.nix"

        def pair(self, local_text, remote_text, package="curl"):
            """A package present in both trees; returns its patch target."""
            self.both(
                f"pkgs/{package}/default.nix",
                self.upstream_path(package),
                local_text,
                remote_text,
            )
            return f"pkgs/{package}.patch"

        def repoint(self, text, package="curl"):
            """Replace just the nixpkgs side of a paired package."""
            return self.remote(self.upstream_path(package), text)

    return Trees()
