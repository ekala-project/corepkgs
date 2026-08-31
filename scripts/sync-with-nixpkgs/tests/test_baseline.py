from syncnix import baseline
from syncnix.baseline import Status


class TestClassify:
    def test_absent_on_both_sides_is_not_reported(self):
        assert baseline.classify(None, None) is None

    def test_divergence_without_a_baseline_is_new(self):
        assert baseline.classify("patch", None) is Status.NEW

    def test_matching_baseline_is_unchanged(self):
        assert baseline.classify("patch", "patch") is Status.UNCHANGED

    def test_differing_baseline_is_changed(self):
        assert baseline.classify("new text", "old text") is Status.CHANGED

    def test_baseline_without_divergence_is_resolved(self):
        assert baseline.classify(None, "old text") is Status.RESOLVED


class TestStore:
    def test_round_trips_patch_text(self, tmp_path):
        baseline.accept(tmp_path, "pkgs/curl.patch", "body\n")
        assert baseline.load(tmp_path, "pkgs/curl.patch") == "body\n"

    def test_missing_entry_loads_as_none(self, tmp_path):
        assert baseline.load(tmp_path, "pkgs/curl.patch") is None

    def test_accept_creates_nested_directories(self, tmp_path):
        baseline.accept(tmp_path, "build-support/fetchgit.patch", "body\n")
        assert (tmp_path / "build-support" / "fetchgit.patch").is_file()

    def test_accept_overwrites_previous_text(self, tmp_path):
        baseline.accept(tmp_path, "t.patch", "first\n")
        baseline.accept(tmp_path, "t.patch", "second\n")
        assert baseline.load(tmp_path, "t.patch") == "second\n"

    def test_forget_removes_and_reports(self, tmp_path):
        baseline.accept(tmp_path, "t.patch", "body\n")
        assert baseline.forget(tmp_path, "t.patch") is True
        assert baseline.forget(tmp_path, "t.patch") is False

    def test_recorded_lists_targets_relative_to_the_store(self, tmp_path):
        baseline.accept(tmp_path, "pkgs/curl.patch", "a\n")
        baseline.accept(tmp_path, "build-support/fetchgit.patch", "b\n")
        assert baseline.recorded(tmp_path) == ["build-support/fetchgit.patch", "pkgs/curl.patch"]

    def test_recorded_is_empty_when_never_used(self, tmp_path):
        assert baseline.recorded(tmp_path / "absent") == []
