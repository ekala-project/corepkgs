"""Integrity of the hand-maintained tables in `config`.

These are edited by people and by scripts, and a dict literal silently keeps
the last of two identical keys -- so a duplicate is invisible at run time and
quietly discards a mapping. These tests make it loud instead.
"""

import re
from pathlib import Path

from syncnix import config

SOURCE = Path(config.__file__).read_text(encoding="utf-8")


def _literal_keys(name: str) -> list[str]:
    """Keys as written in the source, duplicates included."""
    body = SOURCE[SOURCE.index(f"{name} = {{") : SOURCE.index("}", SOURCE.index(f"{name} = {{"))]
    return re.findall(r'^\s*"(.+?)":', body, re.M)


class TestPathMappings:
    def test_no_duplicate_keys(self):
        keys = _literal_keys("PATH_MAPPINGS")
        duplicates = {k for k in keys if keys.count(k) > 1}
        assert not duplicates, f"duplicate keys silently drop a mapping: {duplicates}"

    def test_every_key_reaches_the_loaded_dict(self):
        assert len(_literal_keys("PATH_MAPPINGS")) == len(config.PATH_MAPPINGS)

    def test_no_trailing_slashes(self):
        for local, upstream in config.PATH_MAPPINGS.items():
            assert not local.endswith("/") and not upstream.endswith("/")

