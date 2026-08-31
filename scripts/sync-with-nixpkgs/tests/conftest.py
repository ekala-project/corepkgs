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

    return Trees()
