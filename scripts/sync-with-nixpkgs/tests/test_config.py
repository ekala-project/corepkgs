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


def _literal_entries(name: str) -> list[str]:
    body = SOURCE[SOURCE.index(f"{name} = [") : SOURCE.index("]", SOURCE.index(f"{name} = ["))]
    return re.findall(r'^\s*"(.+?)",', body, re.M)


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


class TestLocalOnly:
    def test_no_duplicates(self):
        entries = _literal_entries("LOCAL_ONLY")
        duplicates = {e for e in entries if entries.count(e) > 1}
        assert not duplicates, duplicates

    def test_no_entry_is_covered_by_another(self):
        # A declaration beneath another declaration is dead weight.
        redundant = [
            entry
            for entry in config.LOCAL_ONLY
            for other in config.LOCAL_ONLY
            if entry != other and entry.startswith(other + "/")
        ]
        assert not redundant, redundant

    def test_declarations_are_not_also_ignored(self):
        # Ignoring already stops comparison; declaring on top of it says nothing.
        from syncnix import paths

        overlap = [entry for entry in config.LOCAL_ONLY if paths.is_ignored(entry)]
        assert not overlap, overlap


class TestTrivialPatterns:
    def test_every_pattern_names_the_attribute(self):
        # `key` is what lets -version be matched against +version, not +hash.
        for pattern in config.TRIVIAL_PATTERNS:
            assert "key" in pattern.groupindex, pattern.pattern

    def test_patterns_do_not_match_ordinary_bindings(self):
        for line in ('  pname = "curl";', "  doCheck = true;", '  src = fetchurl { };'):
            assert all(p.match(line) is None for p in config.TRIVIAL_PATTERNS), line


class TestNoisePatterns:
    def test_noise_line_patterns_match_what_they_claim(self):
        for line in ("  testers,", "  nixosTests,", "    cmake.configurePhaseHook",
                     "    meson.configurePhaseHook"):
            assert any(p.match(line) for p in config.NOISE_LINE_PATTERNS), line

    def test_noise_line_patterns_are_anchored(self):
        # A longer name that merely starts the same must not be swallowed.
        for line in ("  testersFoo,", "  cmake", "  configurePhaseHook = x;"):
            assert all(p.match(line) is None for p in config.NOISE_LINE_PATTERNS), line

    def test_noise_bindings_are_dotted_paths(self):
        for name in config.NOISE_BINDINGS:
            assert name and " " not in name


class TestNoiseSubstitutions:
    def test_both_derivation_forms_reduce_alike(self):
        from syncnix import normalize

        rec = "mkDerivation rec {\n  x = pname;\n}\n"
        final = "mkDerivation (finalAttrs: {\n  x = finalAttrs.pname;\n})\n"
        assert normalize.significant(rec) == normalize.significant(final)

    def test_substitutions_are_pattern_replacement_pairs(self):
        for pattern, replacement in config.NOISE_SUBSTITUTIONS:
            assert hasattr(pattern, "sub")
            assert isinstance(replacement, str)


class TestEquivalentKeys:
    def test_canonical_targets_are_not_themselves_aliases(self):
        # A -> B -> C chain would depend on iteration order.
        for canonical in config.EQUIVALENT_KEYS.values():
            assert canonical not in config.EQUIVALENT_KEYS

    def test_every_key_is_one_the_tool_already_treats_as_trivial(self):
        for name in list(config.EQUIVALENT_KEYS) + list(config.EQUIVALENT_KEYS.values()):
            assert any(
                pattern.match(f'  {name} = "x";') for pattern in config.TRIVIAL_PATTERNS
            ), name
