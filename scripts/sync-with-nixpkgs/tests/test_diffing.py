import subprocess

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


def _patch(local, upstream):
    return diffing.render("t.patch", [diffing.compare("p/f.nix", "u.nix", local, upstream, [])])


def _substantive(local, upstream):
    return diffing.compare("p/f.nix", "u.nix", local, upstream, []).substantive


class TestSubstantive:
    """Whether a difference survives `normalize.significant` on both sides."""

    def test_version_bump_alone_is_not(self):
        assert not _substantive('{\n  version = "1.0";\n}\n', '{\n  version = "2.0";\n}\n')

    def test_version_and_hash_together_are_not(self):
        assert not _substantive(
            '{\n  version = "1.0";\n  hash = "sha256-a=";\n}\n',
            '{\n  version = "2.0";\n  hash = "sha256-b=";\n}\n',
        )

    def test_trailing_comment_does_not_hide_a_bump(self):
        assert not _substantive(
            '{\n  version = "1.0"; # pinned\n}\n', '{\n  version = "2.0"; # pinned\n}\n'
        )

    def test_any_other_changed_line_is(self):
        assert _substantive(
            '{\n  version = "1.0";\n  pname = "a";\n}\n',
            '{\n  version = "2.0";\n  pname = "b";\n}\n',
        )

    def test_added_attribute_is(self):
        # Blanking a value keeps its line, so an attribute with no counterpart
        # on the other side still shows. Nothing moved here; something appeared.
        assert _substantive('{\n  pname = "a";\n}\n', '{\n  pname = "a";\n  hash = "sha256-b=";\n}\n')

    def test_removed_attribute_is(self):
        assert _substantive('{\n  pname = "a";\n  hash = "sha256-b=";\n}\n', '{\n  pname = "a";\n}\n')

    def test_version_traded_for_hash_is(self):
        assert _substantive(
            '{\n  version = "1.0";\n  pname = "a";\n}\n',
            '{\n  pname = "a";\n  hash = "sha256-b=";\n}\n',
        )

    def test_a_passthru_tests_difference_is_not(self):
        local = '{\n  pname = "a";\n  passthru.tests = { inherit (nixosTests) podman; };\n}\n'
        upstream = (
            '{\n  pname = "a";\n  passthru.tests = {\n'
            "    version = testers.testVersion {\n"
            "      package = finalAttrs.finalPackage;\n"
            "    };\n  };\n}\n"
        )
        assert not _substantive(local, upstream)

    def test_a_cpe_parts_removal_is_not(self):
        local = '{\n  meta = {\n    mainProgram = "a";\n  };\n}\n'
        upstream = (
            '{\n  meta = {\n    mainProgram = "a";\n'
            '    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "a_project" v;\n  };\n}\n'
        )
        assert not _substantive(local, upstream)

    def test_a_test_argument_rename_is_not(self):
        assert not _substantive("{\n  lib,\n  nixosTests,\n}:\n", "{\n  lib,\n  testers,\n}:\n")

    def test_a_differing_patch_file_is(self):
        assert diffing.compare_opaque("p/fix.patch", "u/fix.patch", differs=True).substantive
        assert not diffing.compare_opaque("p/fix.patch", "u/fix.patch", differs=False).substantive


class TestChanged:
    def test_yields_sign_and_content_without_the_marker(self):
        changes = list(diffing.changed(_patch("a\nb\nc\n", "a\nX\nc\n")))
        assert changes == [("-", "b"), ("+", "X")]
