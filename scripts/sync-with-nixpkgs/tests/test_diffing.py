import subprocess

import pytest

from syncnix import diffing


def _apply(tmp_path, relative, original, patch):
    """Write `original`, apply `patch` with git, return the result."""
    subprocess.run(["git", "init", "-q"], cwd=tmp_path, check=True)
    target = tmp_path / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(original, encoding="utf-8")

    patch_file = tmp_path / "change.patch"
    patch_file.write_text(patch, encoding="utf-8")

    subprocess.run(
        ["git", "apply", "-p1", str(patch_file)], cwd=tmp_path, check=True, capture_output=True
    )
    return target.read_text(encoding="utf-8")


class TestCompare:
    def test_identical_after_normalisation_yields_no_diff(self):
        local = "{\n  license = mit;\n}\n"
        upstream = "{\n  maintainers = [ x ];\n  license = mit;\n}\n"
        assert diffing.compare("f.nix", "u.nix", local, upstream, []).diff is None

    def test_real_difference_produces_a_diff(self):
        result = diffing.compare(
            "f.nix", "u.nix", "version = \"1\";\n", "version = \"2\";\n", []
        )
        assert result.diff is not None
        assert "-version = \"1\";" in result.diff
        assert "+version = \"2\";" in result.diff

    def test_headers_use_the_corepkgs_path(self):
        result = diffing.compare("pkgs/curl/default.nix", "pkgs/by-name/cu/curl/package.nix",
                                 "a\n", "b\n", [])
        assert "--- a/pkgs/curl/default.nix" in result.diff
        assert "+++ b/pkgs/curl/default.nix" in result.diff

    def test_upstream_only_noise_never_appears_as_an_addition(self):
        local = "{\n  license = mit;\n}\n"
        upstream = "{\n  teams = [ lib.teams.gnome ];\n  license = asl20;\n}\n"
        diff = diffing.compare("f.nix", "u.nix", local, upstream, []).diff
        assert "teams" not in diff
        assert "+  license = asl20;" in diff


class TestAppliability:
    """The property the previous implementation could not hold.

    Because only the upstream side is normalised, the diff's old side is the
    real file and the patch applies verbatim.
    """

    def test_patch_applies_cleanly(self, tmp_path):
        local = "line one\nline two\nline three\nline four\nline five\n"
        upstream = "line one\nline two\nCHANGED\nline four\nline five\n"
        patch = diffing.compare("pkg/default.nix", "u.nix", local, upstream, []).diff
        assert _apply(tmp_path, "pkg/default.nix", local, patch) == upstream

    def test_patch_applies_when_upstream_noise_was_stripped(self, tmp_path):
        local = "a = 1;\nb = 2;\nc = 3;\nd = 4;\ne = 5;\n"
        upstream = "a = 1;\nb = 2;\nmaintainers = [ x ];\nc = 99;\nd = 4;\ne = 5;\n"
        patch = diffing.compare("pkg/default.nix", "u.nix", local, upstream, []).diff
        assert _apply(tmp_path, "pkg/default.nix", local, patch) == (
            "a = 1;\nb = 2;\nc = 99;\nd = 4;\ne = 5;\n"
        )

    def test_multiple_distant_hunks_apply(self, tmp_path):
        local = "".join(f"line {n}\n" for n in range(40))
        upstream = local.replace("line 2\n", "TOP\n").replace("line 37\n", "BOTTOM\n")
        patch = diffing.compare("pkg/default.nix", "u.nix", local, upstream, []).diff
        assert _apply(tmp_path, "pkg/default.nix", local, patch) == upstream


class TestOpaqueFiles:
    def test_identical_opaque_file_is_not_reported(self):
        comparison = diffing.compare_opaque("p/fix.patch", "u/fix.patch", differs=False)
        assert diffing.render("p.patch", [comparison]) is None

    def test_differing_opaque_file_becomes_a_note(self):
        comparison = diffing.compare_opaque("p/fix.patch", "u/fix.patch", differs=True)
        rendered = diffing.render("p.patch", [comparison])
        assert "p/fix.patch <- u/fix.patch" in rendered
        # The note replaces the content entirely: no diff markers at all.
        assert "@@" not in rendered
        assert not any(line.startswith(("+", "-")) for line in rendered.splitlines())


class TestRender:
    def test_returns_none_when_nothing_diverges(self):
        assert diffing.render("t.patch", []) is None
        assert diffing.render("t.patch", [diffing.Comparison("f", "u")]) is None

    def test_notes_precede_diffs_so_the_diff_stays_contiguous(self):
        rendered = diffing.render(
            "t.patch",
            [
                diffing.compare_opaque("p/fix.patch", "u/fix.patch", differs=True),
                diffing.compare("p/default.nix", "u.nix", "a\n", "b\n", []),
            ],
        )
        assert rendered.index("fix.patch") < rendered.index("--- a/p/default.nix")

    def test_header_lines_are_comments(self, tmp_path):
        rendered = diffing.render(
            "t.patch",
            [
                diffing.compare_opaque("p/fix.patch", "u/fix.patch", differs=True),
                diffing.compare("p/default.nix", "u.nix", "a\nb\nc\n", "a\nX\nc\n", []),
            ],
        )
        header = rendered.split("--- ")[0].splitlines()
        assert all(line.startswith("#") for line in header)
        # A patch carrying notes still applies.
        assert _apply(tmp_path, "p/default.nix", "a\nb\nc\n", rendered) == "a\nX\nc\n"


class TestChangedLines:
    def test_counts_additions_and_removals(self):
        patch = diffing.render(
            "t.patch", [diffing.compare("p/f.nix", "u.nix", "a\nb\nc\n", "a\nX\nc\n", [])]
        )
        assert diffing.changed_lines(patch) == 2

    def test_ignores_the_comment_header_and_file_markers(self):
        patch = diffing.render(
            "t.patch",
            [
                diffing.compare_opaque("p/fix.patch", "u/fix.patch", differs=True),
                diffing.compare("p/f.nix", "u.nix", "a\nb\nc\n", "a\nX\nc\n", []),
            ],
        )
        # Header notes and the ---/+++ pair are structure, not change.
        assert diffing.changed_lines(patch) == 2

    def test_note_only_patch_counts_nothing(self):
        patch = diffing.render(
            "t.patch", [diffing.compare_opaque("p/fix.patch", "u/fix.patch", differs=True)]
        )
        assert diffing.changed_lines(patch) == 0

    def test_counts_content_that_looks_like_a_file_marker(self):
        # A removed source line of "--" renders as "---"; it is a change, not a header.
        local = "a\n--\nc\n"
        upstream = "a\n++\nc\n"
        patch = diffing.render("t.patch", [diffing.compare("p/f.nix", "u.nix", local, upstream, [])])
        assert "----" not in patch  # sanity: the removal really is a bare "---"
        assert diffing.changed_lines(patch) == 2

    def test_no_newline_marker_is_not_a_change(self):
        patch = diffing.render(
            "t.patch", [diffing.compare("p/f.nix", "u.nix", "a\nb\nc", "a\nb\nX", [])]
        )
        assert "\\ No newline at end of file" in patch
        assert diffing.changed_lines(patch) == 2

    def test_totals_across_several_hunks(self):
        local = "".join(f"line {n}\n" for n in range(40))
        upstream = local.replace("line 2\n", "TOP\n").replace("line 37\n", "BOTTOM\n")
        patch = diffing.render("t.patch", [diffing.compare("p/f.nix", "u.nix", local, upstream, [])])
        assert diffing.changed_lines(patch) == 4


def nix(*lines):
    """A minimal attribute set, one binding per line."""
    return "{\n" + "".join(f"  {line}\n" for line in lines) + "}\n"


def _patch(local, upstream):
    return diffing.render("t.patch", [diffing.compare("p/f.nix", "u.nix", local, upstream, [])])


def _substantive(local, upstream):
    return diffing.compare("p/f.nix", "u.nix", local, upstream, []).substantive


def _cases(*rows):
    """Turn `(id, local, upstream)` rows into parametrize arguments."""
    return {"argvalues": [row[1:] for row in rows], "ids": [row[0] for row in rows]}


REC = """stdenv.mkDerivation rec {
  pname = "a";
  version = "1.0";
  postInstall = "echo ${pname}";
  meta.mainProgram = pname;
}
"""

FINAL = """stdenv.mkDerivation (finalAttrs: {
  pname = "a";
  version = "2.0";
  postInstall = "echo ${finalAttrs.pname}";
  meta.mainProgram = finalAttrs.pname;
})
"""

PASSTHRU_TESTS = """{
  pname = "a";
  passthru.tests = {
    version = testers.testVersion {
      package = finalAttrs.finalPackage;
    };
  };
}
"""

# Pairs that say the same thing two ways. None of these may reach `patches/`.
EQUIVALENT = _cases(
    ("version bump", nix('version = "1.0";'), nix('version = "2.0";')),
    (
        "version and hash together",
        nix('version = "1.0";', 'hash = "sha256-a=";'),
        nix('version = "2.0";', 'hash = "sha256-b=";'),
    ),
    ("bump behind a trailing comment", nix('version = "1.0"; # pinned'), nix('version = "2.0"; # pinned')),
    (
        "passthru.tests written differently",
        nix('pname = "a";', "passthru.tests = { inherit (nixosTests) podman; };"),
        PASSTHRU_TESTS,
    ),
    (
        "identifiers.cpeParts only upstream",
        '{\n  meta = {\n    mainProgram = "a";\n  };\n}\n',
        '{\n  meta = {\n    mainProgram = "a";\n'
        '    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "a_project" v;\n  };\n}\n',
    ),
    ("testers/nixosTests argument", "{\n  lib,\n  nixosTests,\n}:\n", "{\n  lib,\n  testers,\n}:\n"),
    # The lambda header, its closing paren and every self-reference move together.
    ("rec rewritten as finalAttrs", REC, FINAL),
    ("finalAttrs rewritten as rec", FINAL, REC),
    ("rev renamed to tag", nix('rev = "v1.0";'), nix('tag = "v1.0";')),
    ("tag renamed to rev", nix('tag = "v1.0";'), nix('rev = "v1.0";')),
    # Neither value is a literal the tool would blank, so the rename has to be
    # handled independently of the value.
    ("rev/tag with an unquoted value", nix("rev = version;"), nix("tag = version;")),
    ("hash renamed to sha256", nix('hash = "a";'), nix('sha256 = "b";')),
    ("sha256/hash unquoted", nix("sha256 = lib.fakeHash;"), nix("hash = lib.fakeHash;")),
    # Build flags routinely appear on one side alone, so the whole binding goes;
    # blanking a value cannot hide a line with no counterpart.
    ("build flag on one side only", nix('pname = "a";'), nix('pname = "a";', "__structuredAttrs = true;")),
    ("flipped build flag", nix("strictDeps = true;"), nix("strictDeps = false;")),
    ("enableParallelBuilding dropped", nix("enableParallelBuilding = true;"), "{\n}\n"),
    ("enableParallelInstalling dropped", nix("enableParallelInstalling = true;"), "{\n}\n"),
    ("doCheck flipped", nix("doCheck = true;"), nix("doCheck = false;")),
    ("doCheck on one side only", nix('pname = "a";', "doCheck = false;"), nix('pname = "a";')),
    # An update script is dropped when porting, and its helper argument goes
    # with it -- both spellings, and whether or not corepkgs kept one.
    (
        "update script added upstream",
        nix('pname = "a";'),
        nix('pname = "a";', "passthru.updateScript = nix-update-script { };"),
    ),
    (
        "update script inside passthru",
        nix('pname = "a";'),
        nix('pname = "a";', "updateScript = gitUpdater { };"),
    ),
    (
        "update script helper argument",
        "{\n  lib,\n}:\n",
        "{\n  lib,\n  nix-update-script,\n}:\n",
    ),
    # Naming a binding covers its leaves: `identifiers.cpeParts.vendor` is part
    # of `identifiers.cpeParts`, and a `passthru.tests` entry part of the tests.
    (
        "cpe sub-attribute on one side only",
        nix('pname = "a";'),
        nix('pname = "a";', 'identifiers.cpeParts.vendor = "x.org";'),
    ),
    (
        "named test under passthru.tests",
        nix('pname = "a";'),
        nix('pname = "a";', "passthru.tests.version = testers.testVersion { };"),
    ),
    # Where a file breathes is formatting, not design.
    ("blank line inserted", nix("a = 1;", "b = 2;"), "{\n  a = 1;\n\n  b = 2;\n}\n"),
    ("whitespace-only line", nix("a = 1;"), "{\n  a = 1;\n   \n}\n"),
    ("comment reworded", nix("# corepkgs wording", "a = 1;"), nix("# nixpkgs wording", "a = 1;")),
    ("comment on one side only", nix("# explanation", "a = 1;"), nix("a = 1;")),
    ("cross: host != build", nix("x = stdenv.hostPlatform != stdenv.buildPlatform;"), nix("x = stdenv.isCross;")),
    ("cross: build != host", nix("x = stdenv.buildPlatform != stdenv.hostPlatform;"), nix("x = stdenv.isCross;")),
    ("cross: destructured", nix("x = hostPlatform != buildPlatform;"), nix("x = stdenv.isCross;")),
    ("cross: host == build", nix("x = stdenv.hostPlatform == stdenv.buildPlatform;"), nix("x = !stdenv.isCross;")),
    ("cross: build == host", nix("x = stdenv.buildPlatform == stdenv.hostPlatform;"), nix("x = !stdenv.isCross;")),
)

# Pairs that genuinely differ. Each is a way the reductions could go too far.
DISTINCT = _cases(
    (
        "a real change beside a bump",
        nix('version = "1.0";', 'pname = "a";'),
        nix('version = "2.0";', 'pname = "b";'),
    ),
    # Blanking a value keeps its line, so an attribute with no counterpart on
    # the other side still shows. Nothing moved here; something appeared.
    ("attribute added upstream", nix('pname = "a";'), nix('pname = "a";', 'hash = "sha256-b=";')),
    # `doCheckTarget` merely starts with `doCheck`; only a dotted suffix counts.
    ("longer name sharing a prefix", nix('pname = "a";'), nix('pname = "a";', "doCheckTarget = true;")),
    ("attribute removed upstream", nix('pname = "a";', 'hash = "sha256-b=";'), nix('pname = "a";')),
    (
        "version traded for hash",
        nix('version = "1.0";', 'pname = "a";'),
        nix('pname = "a";', 'hash = "sha256-b=";'),
    ),
    ("a real change beside the rec rewrite", REC, FINAL.replace('pname = "a"', 'pname = "b"')),
    # Both are hashes, but they hash different things.
    ("cargoHash vs vendorHash", nix('cargoHash = "a";'), nix('vendorHash = "a";')),
    ("rev vs version", nix('rev = "a";'), nix('version = "a";')),
    ("a longer name sharing the prefix", nix("strictDeps = true;"), nix("strictDepsFoo = true;")),
    ("doInstallCheck is not doCheck", nix("doInstallCheck = true;"), "{\n}\n"),
    ("blank lines do not hide a change", nix("a = 1;"), "{\n\n  a = 2;\n\n}\n"),
    ("a comment does not hide a change", nix("# same note", "a = 1;"), nix("# same note", "a = 2;")),
    # Only a line that *starts* with `#` is a comment, so no quote parsing is
    # needed and a URL fragment stays part of the code.
    ("a hash inside a string", nix('url = "https://x/a#frag";'), nix('url = "https://x/b#frag";')),
    # != is cross, == is not-cross; collapsing them would invert a condition.
    (
        "the two cross senses",
        nix("x = stdenv.hostPlatform != stdenv.buildPlatform;"),
        nix("x = !stdenv.isCross;"),
    ),
)


class TestSubstantive:
    """Whether a difference survives `normalize.significant` on both sides."""

    @pytest.mark.parametrize("local,upstream", **EQUIVALENT)
    def test_equivalent_spellings_are_not_substantive(self, local, upstream):
        assert not _substantive(local, upstream)

    @pytest.mark.parametrize("local,upstream", **DISTINCT)
    def test_real_differences_are_substantive(self, local, upstream):
        assert _substantive(local, upstream)

    def test_a_differing_patch_file_is(self):
        assert diffing.compare_opaque("p/fix.patch", "u/fix.patch", differs=True).substantive
        assert not diffing.compare_opaque("p/fix.patch", "u/fix.patch", differs=False).substantive


class TestChanged:
    def test_yields_sign_and_content_without_the_marker(self):
        changes = list(diffing.changed(_patch("a\nb\nc\n", "a\nX\nc\n")))
        assert changes == [("-", "b"), ("+", "X")]
