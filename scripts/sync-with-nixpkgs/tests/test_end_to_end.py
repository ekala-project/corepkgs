from syncnix import cli, config, survey


def _generate(trees, *extra):
    return cli.main(
        ["--corepkgs", str(trees.root), "--nixpkgs", str(trees.upstream), "generate", *extra]
    )


def _accept(trees, *targets):
    return cli.main(
        ["--corepkgs", str(trees.root), "--nixpkgs", str(trees.upstream), "accept", *targets]
    )


def _patches(trees):
    return trees.root / config.PATCHES_DIR


class TestSurvey:
    def test_identical_files_produce_no_patch(self, trees):
        trees.both(
            "pkgs/curl/default.nix", "pkgs/by-name/cu/curl/package.nix", "same\n", "same\n"
        )
        result = survey.run(trees.root, trees.upstream)
        assert result.patches == {}
        assert result.identical == 1

    def test_differing_files_produce_one_grouped_patch(self, trees):
        trees.both("pkgs/curl/default.nix", "pkgs/by-name/cu/curl/package.nix", "a\n", "b\n")
        trees.both("pkgs/curl/extra.nix", "pkgs/by-name/cu/curl/extra.nix", "c\n", "d\n")
        result = survey.run(trees.root, trees.upstream)
        assert list(result.patches) == ["pkgs/curl.patch"]
        assert "extra.nix" in result.patches["pkgs/curl.patch"]

    def test_unmapped_file_is_reported_not_diffed(self, trees):
        trees.local("unclaimed/thing.nix", "x\n")
        result = survey.run(trees.root, trees.upstream)
        assert result.unmapped == ["unclaimed/thing.nix"]
        assert result.patches == {}

    def test_file_absent_upstream_is_reported_as_missing(self, trees):
        trees.local("pkgs/only-here/default.nix", "x\n")
        result = survey.run(trees.root, trees.upstream)
        assert result.missing == ["pkgs/only-here/default.nix"]

    def test_markdown_is_never_compared(self, trees):
        trees.both(
            "pkgs/curl/README.md", "pkgs/by-name/cu/curl/README.md", "ours\n", "theirs\n"
        )
        result = survey.run(trees.root, trees.upstream)
        assert result.patches == {}
        assert result.unmapped == []
        assert result.missing == []

    def test_ignored_tree_is_not_walked(self, trees):
        trees.local("scripts/whatever.py", "x\n")
        result = survey.run(trees.root, trees.upstream)
        assert result.unmapped == []
        assert result.missing == []


class TestOpaqueFiles:
    def test_patch_file_contents_never_reach_the_output(self, trees):
        trees.both("pkgs/curl/default.nix", "pkgs/by-name/cu/curl/package.nix", "a\n", "b\n")
        trees.both(
            "pkgs/curl/fix.patch",
            "pkgs/by-name/cu/curl/fix.patch",
            "--- a/upstream.c\n+++ b/upstream.c\n@@ -1 +1 @@\n-old\n+new\n",
            "--- a/upstream.c\n+++ b/upstream.c\n@@ -1 +1 @@\n-old\n+DIFFERENT\n",
        )
        result = survey.run(trees.root, trees.upstream)
        body = result.patches["pkgs/curl.patch"]

        assert "DIFFERENT" not in body
        assert "upstream.c" not in body
        assert "pkgs/curl/fix.patch <- pkgs/by-name/cu/curl/fix.patch" in body
        assert result.opaque_differs == ["pkgs/curl/fix.patch"]

    def test_identical_patch_file_is_silent(self, trees):
        trees.both("pkgs/curl/fix.patch", "pkgs/by-name/cu/curl/fix.patch", "same\n", "same\n")
        result = survey.run(trees.root, trees.upstream)
        assert result.patches == {}
        assert result.opaque_differs == []


class TestBaselineWorkflow:
    def _diverge(self, trees):
        trees.both("pkgs/curl/default.nix", "pkgs/by-name/cu/curl/package.nix", "a\n", "b\n")

    def test_generate_writes_patches_and_reports(self, trees, capsys):
        self._diverge(trees)
        assert _generate(trees) == 0
        assert (_patches(trees) / "pkgs" / "curl.patch").is_file()
        assert "new divergence" in capsys.readouterr().out

    def test_strict_fails_on_unaccepted_drift(self, trees):
        self._diverge(trees)
        assert _generate(trees, "--strict") == 1

    def test_accepted_divergence_stops_being_drift(self, trees):
        self._diverge(trees)
        _accept(trees)
        assert _generate(trees, "--strict") == 0

    def test_changed_divergence_resurfaces(self, trees, capsys):
        self._diverge(trees)
        _accept(trees)
        trees.remote("pkgs/by-name/cu/curl/package.nix", "something else\n")
        assert _generate(trees, "--strict") == 1
        assert "changed vs accepted" in capsys.readouterr().out

    def test_resolved_divergence_is_flagged_as_stale(self, trees, capsys):
        self._diverge(trees)
        _accept(trees)
        trees.remote("pkgs/by-name/cu/curl/package.nix", "a\n")
        _generate(trees)
        out = capsys.readouterr().out
        assert "resolved, baseline is stale" in out
        assert "pkgs/curl.patch" in out

    def test_accept_can_target_one_patch(self, trees):
        self._diverge(trees)
        trees.both("pkgs/wget/default.nix", "pkgs/by-name/wg/wget/package.nix", "a\n", "b\n")
        _accept(trees, "pkgs/curl.patch")
        assert _generate(trees, "--strict") == 1

    def test_accept_forgets_stale_entries(self, trees):
        self._diverge(trees)
        _accept(trees)
        trees.remote("pkgs/by-name/cu/curl/package.nix", "a\n")
        _accept(trees, "pkgs/curl.patch")
        assert _generate(trees, "--strict") == 0

    def test_dry_run_writes_nothing(self, trees):
        self._diverge(trees)
        _generate(trees, "--dry-run")
        assert not _patches(trees).exists()

    def test_generate_refreshes_stale_patch_files(self, trees):
        self._diverge(trees)
        _generate(trees)
        stale = _patches(trees) / "pkgs" / "stale.patch"
        stale.write_text("leftover\n", encoding="utf-8")
        _generate(trees)
        assert not stale.exists()


class TestReports:
    def test_unmapped_paths_are_written_out(self, trees):
        trees.local("unclaimed/thing.nix", "x\n")
        _generate(trees)
        report = _patches(trees) / config.REPORTS_DIR / "unmapped-paths.txt"
        assert "unclaimed/thing.nix" in report.read_text(encoding="utf-8")

    def test_no_report_is_written_when_nothing_to_say(self, trees):
        trees.both(
            "pkgs/curl/default.nix", "pkgs/by-name/cu/curl/package.nix", "same\n", "same\n"
        )
        _generate(trees)
        assert not (_patches(trees) / config.REPORTS_DIR).exists()


class TestRoots:
    def test_missing_nixpkgs_exits_with_a_message(self, trees, capsys):
        import pytest

        with pytest.raises(SystemExit) as exit_info:
            cli.main(
                ["--corepkgs", str(trees.root), "--nixpkgs", str(trees.root / "nope"), "generate"]
            )
        assert "nixpkgs directory not found" in str(exit_info.value)

    def test_roots_are_validated_before_patches_are_deleted(self, trees):
        self_patches = _patches(trees)
        self_patches.mkdir(parents=True)
        (self_patches / "keep.patch").write_text("kept\n", encoding="utf-8")

        import pytest

        with pytest.raises(SystemExit):
            cli.main(
                ["--corepkgs", str(trees.root), "--nixpkgs", str(trees.root / "nope"), "generate"]
            )
        assert (self_patches / "keep.patch").is_file()
