import re

from syncnix import aliases, config


def block(*lines):
    """Wrap alias lines in the scaffolding a real aliases.nix has."""
    body = "\n".join(lines)
    return f"lib: final: prev:\nwith pkgs;\nmapAliases {{\n  # keep-sorted start\n{body}\n  # keep-sorted end\n}}\n"


class TestParse:
    def test_reads_simple_aliases(self):
        assert aliases.parse(block("  SDL = sdl12-compat;")) == {"SDL": "sdl12-compat"}

    def test_reads_dotted_targets(self):
        parsed = aliases.parse(block("  autoconf269 = autoconf.v2_69;"))
        assert parsed == {"autoconf269": "autoconf.v2_69"}

    def test_ignores_removals(self):
        assert aliases.parse(block('  gone = throw "removed";')) == {}

    def test_ignores_conditionals(self):
        assert aliases.parse(block("  maybe = if x then a else b;")) == {}

    def test_ignores_scaffolding_outside_the_block(self):
        # `inherit (final) pkgs;` and friends sit above the block and are not
        # aliases; reading the whole file would mistake them for some.
        text = "let\n  removeRecurseForDerivations = alias;\nin\n" + block("  SDL = sdl12-compat;")
        assert aliases.parse(text) == {"SDL": "sdl12-compat"}

    def test_file_without_a_block_yields_nothing(self):
        assert aliases.parse("mapAliases { }\n") == {}

    def test_hyphenated_names_are_read(self):
        assert aliases.parse(block("  tcl-8_6 = tcl.v8_6;")) == {"tcl-8_6": "tcl.v8_6"}


class TestLoad:
    def _write(self, root, name, text):
        path = root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    def test_builds_rewrites_from_the_alias_file(self, tmp_path):
        self._write(tmp_path, config.ALIAS_FILES[0], block("  fuse3 = fuse;"))
        vocabulary = aliases.load(tmp_path)
        assert ("fuse3", "fuse") in [(p.pattern.strip("\\b"), r) for p, r in vocabulary]

    def test_excluded_aliases_are_skipped(self, tmp_path):
        excluded = sorted(config.ALIAS_EXCLUSIONS)[0]
        self._write(tmp_path, config.ALIAS_FILES[0], block(f"  {excluded} = something;"))
        assert all(r != "something" for _, r in aliases.load(tmp_path))

    def test_generic_tokens_are_excluded(self, tmp_path):
        # `man` would rewrite `bintools ? man`; `r` would rewrite `jq -r`.
        self._write(tmp_path, config.ALIAS_FILES[0], block("  man = man-db;", "  r = r-lang;"))
        assert [r for _, r in aliases.load(tmp_path) if r in ("man-db", "r-lang")] == []

    def test_extra_vocabulary_is_always_included(self, tmp_path):
        vocabulary = aliases.load(tmp_path)
        assert "pkgsArgs" in [r for _, r in vocabulary]

    def test_missing_alias_file_is_not_an_error(self, tmp_path):
        assert aliases.load(tmp_path) == [
            (re.compile(p), r) for p, r in config.EXTRA_VOCABULARY
        ]

    def test_rewrites_are_word_bounded(self, tmp_path):
        self._write(tmp_path, config.ALIAS_FILES[0], block("  fuse3 = fuse;"))
        pattern = next(p for p, r in aliases.load(tmp_path) if r == "fuse")
        assert pattern.sub("fuse", "fuse3") == "fuse"
        assert pattern.sub("fuse", "fuse30") == "fuse30"
