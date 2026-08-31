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
