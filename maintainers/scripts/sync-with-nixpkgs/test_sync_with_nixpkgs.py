#!/usr/bin/env nix-shell
#!nix-shell -p "python3.withPackages (p: with p; [ pytest ])" -i python3
"""Tests for sync-with-nixpkgs.py"""

import tempfile
from pathlib import Path
from contextlib import contextmanager
import sys

# Add the scripts directory to the path so we can import the module
scripts_dir = Path(__file__).parent.resolve()
sys.path.insert(0, str(scripts_dir))

import importlib.util
spec = importlib.util.spec_from_file_location("sync_with_nixpkgs", scripts_dir / "sync-with-nixpkgs.py")
sync_with_nixpkgs = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync_with_nixpkgs)


# ============================================================================
# Test Infrastructure Helpers
# ============================================================================

@contextmanager
def config_context(**kwargs):
    """Context manager to temporarily modify module configuration."""
    originals = {}
    try:
        for key, value in kwargs.items():
            attr = getattr(sync_with_nixpkgs, key)
            originals[key] = attr.copy() if isinstance(attr, (list, dict)) else attr
            if isinstance(attr, list):
                if isinstance(value, list):
                    attr[:] = value
                elif value not in attr:
                    attr.append(value)
            elif isinstance(attr, dict):
                if isinstance(value, dict):
                    attr.update(value)
                else:
                    attr[value] = kwargs.get(f"{key}_value", "pkgs/" + value)
            else:
                setattr(sync_with_nixpkgs, key, value)
        yield
    finally:
        for key, original in originals.items():
            attr = getattr(sync_with_nixpkgs, key)
            if isinstance(attr, list):
                attr[:] = original
            elif isinstance(attr, dict):
                attr.clear()
                attr.update(original)
            else:
                setattr(sync_with_nixpkgs, key, original)


def setup_dirs(tmpdir, corepkgs_structure=None, nixpkgs_structure=None):
    """Helper to set up corepkgs and nixpkgs directory structures."""
    corepkgs = Path(tmpdir) / "corepkgs"
    nixpkgs = Path(tmpdir) / "nixpkgs"
    
    def create_structure(base, structure):
        if structure:
            if isinstance(structure, dict):
                # First pass: create all directories
                dirs_to_create = set()
                for path, content in structure.items():
                    full_path = base / path
                    dirs_to_create.add(full_path.parent)
                    if content is None:  # Directory marker
                        dirs_to_create.add(full_path)
                for dir_path in dirs_to_create:
                    dir_path.mkdir(parents=True, exist_ok=True)
                # Second pass: create files
                for path, content in structure.items():
                    full_path = base / path
                    if content is not None:
                        full_path.parent.mkdir(parents=True, exist_ok=True)
                        full_path.write_text(content)
            else:
                for path in structure:
                    full_path = base / path
                    full_path.mkdir(parents=True, exist_ok=True)
    
    create_structure(corepkgs, corepkgs_structure)
    create_structure(nixpkgs, nixpkgs_structure)
    return corepkgs, nixpkgs


def run_check_new_files(corepkgs, nixpkgs, **config):
    """Run check_new_files with given configuration."""
    stats = sync_with_nixpkgs.DiffStats()
    with config_context(**config):
        sync_with_nixpkgs.check_new_files(corepkgs, nixpkgs, stats)
    return stats


# ============================================================================
# Tests
# ============================================================================

class TestShouldIgnore:
    def test_ignore_directory(self):
        assert sync_with_nixpkgs.should_ignore("docs/file.md")
        assert sync_with_nixpkgs.should_ignore("patches/file.patch")
        assert sync_with_nixpkgs.should_ignore("maintainers/file.nix")
        assert sync_with_nixpkgs.should_ignore("docs")
    
    def test_ignore_file(self):
        assert sync_with_nixpkgs.should_ignore("README.md")
        assert sync_with_nixpkgs.should_ignore("default.nix")
    
    def test_dont_ignore_normal_file(self):
        assert not sync_with_nixpkgs.should_ignore("build-support/cc-wrapper/setup-hook.sh")
        assert not sync_with_nixpkgs.should_ignore("pkgs/llvm/package.nix")


class TestShouldIgnoreNewFilesDir:
    def test_ignore_pattern_subdir_name(self):
        assert not sync_with_nixpkgs.should_ignore_new_files_dir("build-support", "some-subdir")
    
    def test_ignore_pattern_exact_subdir_match(self):
        with config_context(CHECK_NEW_FILES_IGNORE_NEW_DIRS=["some-subdir"]):
            assert sync_with_nixpkgs.should_ignore_new_files_dir("build-support", "some-subdir")
    
    def test_ignore_pattern_full_path(self):
        with config_context(CHECK_NEW_FILES_IGNORE_NEW_DIRS=["build-support/specific-subdir"]):
            assert sync_with_nixpkgs.should_ignore_new_files_dir("build-support", "specific-subdir")
    
    def test_dont_ignore_normal_subdir(self):
        assert not sync_with_nixpkgs.should_ignore_new_files_dir("common-updater", "scripts")


class TestMapPath:
    def test_exact_match(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            nixpkgs = Path(tmpdir) / "nixpkgs"
            nixpkgs.mkdir()
            (nixpkgs / "test.nix").write_text("test")
            assert sync_with_nixpkgs.map_path("test.nix", nixpkgs) == nixpkgs / "test.nix"
    
    def test_path_mapping(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            nixpkgs = Path(tmpdir) / "nixpkgs"
            test_file = nixpkgs / "pkgs" / "build-support" / "default.nix"
            test_file.parent.mkdir(parents=True)
            test_file.write_text("test")
            with config_context(PATH_MAPPINGS={"build-support": "pkgs/build-support"}):
                assert sync_with_nixpkgs.map_path("build-support/default.nix", nixpkgs) == test_file
    
    def test_pkgs_by_name_mapping(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            corepkgs = Path(tmpdir) / "corepkgs"
            nixpkgs = Path(tmpdir) / "nixpkgs"
            by_name_file = nixpkgs / "pkgs" / "by-name" / "ll" / "llvm" / "package.nix"
            by_name_file.parent.mkdir(parents=True)
            by_name_file.write_text("test")
            assert sync_with_nixpkgs.map_path("pkgs/llvm/default.nix", nixpkgs) == by_name_file
    
    def test_not_found(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            nixpkgs = Path(tmpdir) / "nixpkgs"
            nixpkgs.mkdir()
            assert sync_with_nixpkgs.map_path("nonexistent.nix", nixpkgs) is None


class TestReverseMapPath:
    def test_exact_match(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            corepkgs = Path(tmpdir) / "corepkgs"
            corepkgs.mkdir()
            (corepkgs / "test.nix").write_text("test")
            assert sync_with_nixpkgs.reverse_map_path("test.nix", corepkgs) == "test.nix"
    
    def test_pkgs_by_name_reverse_mapping(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            corepkgs = Path(tmpdir) / "corepkgs"
            test_file = corepkgs / "pkgs" / "llvm" / "default.nix"
            test_file.parent.mkdir(parents=True)
            test_file.write_text("test")
            assert sync_with_nixpkgs.reverse_map_path("pkgs/by-name/ll/llvm/package.nix", corepkgs) == "pkgs/llvm/default.nix"
    
    def test_path_mapping_reverse(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            corepkgs = Path(tmpdir) / "corepkgs"
            test_file = corepkgs / "build-support" / "default.nix"
            test_file.parent.mkdir(parents=True)
            test_file.write_text("test")
            with config_context(PATH_MAPPINGS={"build-support": "pkgs/build-support"}):
                assert sync_with_nixpkgs.reverse_map_path("pkgs/build-support/default.nix", corepkgs) == "build-support/default.nix"


class TestFilesIdentical:
    def test_identical_files(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            file1, file2 = Path(tmpdir) / "file1.txt", Path(tmpdir) / "file2.txt"
            file1.write_text("same content")
            file2.write_text("same content")
            assert sync_with_nixpkgs.files_identical(file1, file2)
    
    def test_different_files(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            file1, file2 = Path(tmpdir) / "file1.txt", Path(tmpdir) / "file2.txt"
            file1.write_text("content 1")
            file2.write_text("content 2")
            assert not sync_with_nixpkgs.files_identical(file1, file2)
    
    def test_nonexistent_file(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            file1 = Path(tmpdir) / "file1.txt"
            file2 = Path(tmpdir) / "nonexistent.txt"
            file1.write_text("content")
            assert not sync_with_nixpkgs.files_identical(file1, file2)


class TestGetDirectoryPath:
    def test_root_file(self):
        assert sync_with_nixpkgs.get_directory_path("file.nix") == "."
    
    def test_nested_file(self):
        assert sync_with_nixpkgs.get_directory_path("build-support/cc-wrapper/default.nix") == "build-support/cc-wrapper"
    
    def test_deeply_nested_file(self):
        assert sync_with_nixpkgs.get_directory_path("a/b/c/d/file.nix") == "a/b/c/d"


class TestExtractRelativePath:
    def test_path_starts_with_base(self):
        assert sync_with_nixpkgs.extract_relative_path("/base/path/to/file", "/base/path") == "to/file"
    
    def test_path_doesnt_start_with_base(self):
        assert sync_with_nixpkgs.extract_relative_path("/other/path/file", "/base/path") == "file"
    
    def test_filename_only(self):
        assert sync_with_nixpkgs.extract_relative_path("file.nix", "/base") == "file.nix"


class TestReplaceDiffPath:
    def test_replace_with_timestamp(self):
        line = "--- a/build-support/cc-wrapper/default.nix\t2024-01-01 00:00:00"
        result = sync_with_nixpkgs.replace_diff_path(line, "--- a", "/tmp/corepkgs/", "build-support/cc-wrapper")
        assert "--- a/build-support/cc-wrapper/default.nix" in result
        assert "\t2024-01-01 00:00:00" in result
    
    def test_replace_without_timestamp(self):
        line = "+++ b/build-support/cc-wrapper/default.nix"
        result = sync_with_nixpkgs.replace_diff_path(line, "+++ b", "/tmp/nixpkgs/", "build-support/cc-wrapper")
        assert "+++ b/build-support/cc-wrapper/default.nix" in result
    
    def test_root_directory(self):
        line = "--- a/file.nix"
        result = sync_with_nixpkgs.replace_diff_path(line, "--- a", "/tmp/corepkgs/", ".")
        assert "--- a/file.nix" in result


class TestDiffStats:
    def test_default_values(self):
        stats = sync_with_nixpkgs.DiffStats()
        assert stats.processed == 0
        assert stats.found == 0
        assert stats.different == 0
        assert stats.ignored == 0
        assert stats.not_found == 0
        assert stats.new_files == 0
        assert stats.not_found_list == []
        assert stats.new_files_list == []
        assert stats.directories_with_diffs == {}
    
    def test_increment_stats(self):
        stats = sync_with_nixpkgs.DiffStats()
        stats.processed += 1
        stats.found += 1
        stats.different += 1
        assert stats.processed == 1
        assert stats.found == 1
        assert stats.different == 1


class TestMapPathUsingMappings:
    def test_exact_match(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            nixpkgs = Path(tmpdir) / "nixpkgs"
            (nixpkgs / "pkgs" / "build-support").mkdir(parents=True)
            with config_context(PATH_MAPPINGS={"build-support": "pkgs/build-support"}):
                assert sync_with_nixpkgs.map_path_using_mappings("build-support", nixpkgs, check_file=False) == nixpkgs / "pkgs" / "build-support"
    
    def test_prefix_match(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            nixpkgs = Path(tmpdir) / "nixpkgs"
            (nixpkgs / "pkgs" / "build-support" / "cc-wrapper").mkdir(parents=True)
            with config_context(PATH_MAPPINGS={"build-support": "pkgs/build-support"}):
                assert sync_with_nixpkgs.map_path_using_mappings("build-support/cc-wrapper", nixpkgs, check_file=False) == nixpkgs / "pkgs" / "build-support" / "cc-wrapper"
    
    def test_no_match(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            nixpkgs = Path(tmpdir) / "nixpkgs"
            nixpkgs.mkdir()
            assert sync_with_nixpkgs.map_path_using_mappings("nonexistent/path", nixpkgs, check_file=False) is None


class TestCheckNewFiles:
    def test_ignore_new_directories_but_check_files(self):
        """When directory is ignored: skip top-level files and new dirs, but check existing subdirs."""
        with tempfile.TemporaryDirectory() as tmpdir:
            corepkgs, nixpkgs = setup_dirs(
                tmpdir,
                {"build-support/bintools-wrapper/default.nix": "existing"},
                {
                    "pkgs/build-support/some-new-directory/file.nix": "new dir file",
                    "pkgs/build-support/some-new-file.nix": "new file",
                    "pkgs/build-support/bintools-wrapper/new-file.nix": "new file in existing dir",
                }
            )
            stats = run_check_new_files(
                corepkgs, nixpkgs,
                CHECK_NEW_FILES=["build-support"],
                PATH_MAPPINGS={"build-support": "pkgs/build-support"},
                CHECK_NEW_FILES_IGNORE_NEW_DIRS=["build-support"]
            )
            assert "build-support/some-new-directory/file.nix" not in stats.new_files_list
            assert "build-support/some-new-file.nix" not in stats.new_files_list
            assert "build-support/bintools-wrapper/new-file.nix" in stats.new_files_list
    
    def test_recursive_check_in_existing_subdirectories(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            corepkgs, nixpkgs = setup_dirs(
                tmpdir,
                {"build-support/bintools-wrapper/nested/existing.nix": "existing"},
                {"pkgs/build-support/bintools-wrapper/nested/new-nested-file.nix": "new nested"}
            )
            stats = run_check_new_files(
                corepkgs, nixpkgs,
                CHECK_NEW_FILES=["build-support"],
                PATH_MAPPINGS={"build-support": "pkgs/build-support"}
            )
            assert "build-support/bintools-wrapper/nested/new-nested-file.nix" in stats.new_files_list
    
    def test_check_new_files_when_not_ignored(self):
        """When NOT ignored: check new dirs, top-level files, and existing subdirs."""
        with tempfile.TemporaryDirectory() as tmpdir:
            corepkgs, nixpkgs = setup_dirs(
                tmpdir,
                {"build-support/bintools-wrapper/default.nix": "existing"},
                {
                    "pkgs/build-support/some-new-directory/file.nix": "new dir file",
                    "pkgs/build-support/some-new-file.nix": "new file",
                    "pkgs/build-support/bintools-wrapper": None,  # Ensure directory exists
                    "pkgs/build-support/bintools-wrapper/new-file.nix": "new file in existing dir",
                    "pkgs/build-support/bintools-wrapper/new-subdir/subdir-file.nix": "new subdir file",
                }
            )
            stats = run_check_new_files(
                corepkgs, nixpkgs,
                CHECK_NEW_FILES=["build-support"],
                PATH_MAPPINGS={"build-support": "pkgs/build-support"},
                CHECK_NEW_FILES_IGNORE_NEW_DIRS=[]  # Explicitly not ignored
            )
            assert "build-support/some-new-directory/file.nix" in stats.new_files_list
            assert "build-support/some-new-file.nix" in stats.new_files_list
            assert "build-support/bintools-wrapper/new-file.nix" in stats.new_files_list
            assert "build-support/bintools-wrapper/new-subdir/subdir-file.nix" in stats.new_files_list
    
    def test_deeply_nested_new_directories(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            corepkgs, nixpkgs = setup_dirs(
                tmpdir,
                {"build-support/cc-wrapper/default.nix": "existing"},
                {
                    "pkgs/build-support/cc-wrapper/new-deep/level1/file1.nix": "level1",
                    "pkgs/build-support/cc-wrapper/new-deep/level1/level2/file2.nix": "level2",
                    "pkgs/build-support/cc-wrapper/new-deep/level1/level2/level3/deep-file.nix": "deep",
                }
            )
            stats = run_check_new_files(
                corepkgs, nixpkgs,
                CHECK_NEW_FILES=["build-support"],
                PATH_MAPPINGS={"build-support": "pkgs/build-support"}
            )
            assert "build-support/cc-wrapper/new-deep/level1/file1.nix" in stats.new_files_list
            assert "build-support/cc-wrapper/new-deep/level1/level2/file2.nix" in stats.new_files_list
            assert "build-support/cc-wrapper/new-deep/level1/level2/level3/deep-file.nix" in stats.new_files_list
    
    def test_multiple_new_directories_at_same_level(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            nixpkgs_structure = {f"pkgs/build-support/new-dir{i}/file.nix": f"content-{i}" for i in range(1, 4)}
            nixpkgs_structure.update({f"pkgs/build-support/new-dir{i}/subdir/subfile.nix": f"sub-{i}" for i in range(1, 4)})
            corepkgs, nixpkgs = setup_dirs(
                tmpdir,
                {"build-support/existing-dir/file.nix": "existing"},
                nixpkgs_structure
            )
            stats = run_check_new_files(
                corepkgs, nixpkgs,
                CHECK_NEW_FILES=["build-support"],
                PATH_MAPPINGS={"build-support": "pkgs/build-support"},
                CHECK_NEW_FILES_IGNORE_NEW_DIRS=[]  # Explicitly not ignored
            )
            for i in range(1, 4):
                assert f"build-support/new-dir{i}/file.nix" in stats.new_files_list
                assert f"build-support/new-dir{i}/subdir/subfile.nix" in stats.new_files_list
    
    def test_mixed_new_files_and_directories(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            corepkgs, nixpkgs = setup_dirs(
                tmpdir,
                {
                    "build-support/dir1/subdir1/existing.nix": "existing",
                    "build-support/dir2/existing.nix": "existing",
                },
                {
                    "pkgs/build-support/top-level.nix": "top",
                    "pkgs/build-support/new-top-dir/file.nix": "new-top",
                    "pkgs/build-support/dir1": None,  # Ensure directory exists
                    "pkgs/build-support/dir1/new-file.nix": "new",
                    "pkgs/build-support/dir1/new-subdir/file.nix": "new-subdir",
                    "pkgs/build-support/dir1/subdir1": None,  # Ensure directory exists
                    "pkgs/build-support/dir1/subdir1/new-file.nix": "new-subdir1",
                    "pkgs/build-support/dir1/subdir1/new-nested/nested-file.nix": "nested",
                }
            )
            stats = run_check_new_files(
                corepkgs, nixpkgs,
                CHECK_NEW_FILES=["build-support"],
                PATH_MAPPINGS={"build-support": "pkgs/build-support"},
                CHECK_NEW_FILES_IGNORE_NEW_DIRS=[]  # Explicitly not ignored
            )
            assert "build-support/new-top-dir/file.nix" in stats.new_files_list
            assert "build-support/dir1/new-file.nix" in stats.new_files_list
            assert "build-support/dir1/new-subdir/file.nix" in stats.new_files_list
            assert "build-support/dir1/subdir1/new-file.nix" in stats.new_files_list
            assert "build-support/dir1/subdir1/new-nested/nested-file.nix" in stats.new_files_list
    
    def test_ignore_pattern_with_nested_structure(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            corepkgs, nixpkgs = setup_dirs(
                tmpdir,
                {
                    "build-support/ignored-subdir/existing.nix": "existing",
                    "build-support/normal-subdir/existing.nix": "existing",
                },
                {
                    "pkgs/build-support/ignored-subdir/new-file.nix": "new",
                    "pkgs/build-support/ignored-subdir/new-dir/file.nix": "new-dir",
                    "pkgs/build-support/normal-subdir/new-file.nix": "new",
                    "pkgs/build-support/normal-subdir/new-dir/file.nix": "new-dir",
                }
            )
            stats = run_check_new_files(
                corepkgs, nixpkgs,
                CHECK_NEW_FILES=["build-support"],
                PATH_MAPPINGS={"build-support": "pkgs/build-support"},
                CHECK_NEW_FILES_IGNORE_NEW_DIRS=["build-support", "ignored-subdir"]
            )
            assert "build-support/ignored-subdir/new-dir/file.nix" not in stats.new_files_list
            assert "build-support/normal-subdir/new-file.nix" in stats.new_files_list
            assert "build-support/normal-subdir/new-dir/file.nix" in stats.new_files_list
    
    def test_complex_path_mapping_scenario(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            corepkgs, nixpkgs = setup_dirs(
                tmpdir,
                {"build-support/wrapper/nested/existing.nix": "existing"},
                {
                    "pkgs/build-support/wrapper/nested/new-file.nix": "new",
                    "pkgs/build-support/wrapper/nested/new-sub/file.nix": "sub",
                    "pkgs/build-support/wrapper/new-wrapper-dir/file.nix": "wrapper-dir",
                    "pkgs/build-support/wrapper/new-wrapper-file.nix": "wrapper-file",
                }
            )
            stats = run_check_new_files(
                corepkgs, nixpkgs,
                CHECK_NEW_FILES=["build-support"],
                PATH_MAPPINGS={"build-support": "pkgs/build-support"}
            )
            assert "build-support/wrapper/nested/new-file.nix" in stats.new_files_list
            assert "build-support/wrapper/nested/new-sub/file.nix" in stats.new_files_list
            assert "build-support/wrapper/new-wrapper-dir/file.nix" in stats.new_files_list
            assert "build-support/wrapper/new-wrapper-file.nix" in stats.new_files_list
    
    def test_recursive_with_multiple_existing_dirs(self):
        with tempfile.TemporaryDirectory() as tmpdir:
            corepkgs, nixpkgs = setup_dirs(
                tmpdir,
                {
                    "build-support/dir1/sub1/deep1": None,
                    "build-support/dir2/sub2": None,
                },
                {
                    "pkgs/build-support/dir1/new-file1.nix": "file1",
                    "pkgs/build-support/dir1/new-dir1/file.nix": "dir1",
                    "pkgs/build-support/dir1/sub1/new-file2.nix": "file2",
                    "pkgs/build-support/dir1/sub1/new-dir2/file.nix": "dir2",
                    "pkgs/build-support/dir1/sub1/deep1/new-file3.nix": "file3",
                    "pkgs/build-support/dir1/sub1/deep1/new-dir3/file.nix": "dir3",
                    "pkgs/build-support/dir2/new-file4.nix": "file4",
                    "pkgs/build-support/dir2/sub2/new-file5.nix": "file5",
                }
            )
            stats = run_check_new_files(
                corepkgs, nixpkgs,
                CHECK_NEW_FILES=["build-support"],
                PATH_MAPPINGS={"build-support": "pkgs/build-support"}
            )
            assert "build-support/dir1/new-file1.nix" in stats.new_files_list
            assert "build-support/dir1/new-dir1/file.nix" in stats.new_files_list
            assert "build-support/dir1/sub1/new-file2.nix" in stats.new_files_list
            assert "build-support/dir1/sub1/new-dir2/file.nix" in stats.new_files_list
            assert "build-support/dir1/sub1/deep1/new-file3.nix" in stats.new_files_list
            assert "build-support/dir1/sub1/deep1/new-dir3/file.nix" in stats.new_files_list
            assert "build-support/dir2/new-file4.nix" in stats.new_files_list
            assert "build-support/dir2/sub2/new-file5.nix" in stats.new_files_list
    
    def test_ignore_top_level_files_when_directory_ignored(self):
        """Top-level files skipped when directory ignored, but existing subdirs still checked."""
        with tempfile.TemporaryDirectory() as tmpdir:
            corepkgs, nixpkgs = setup_dirs(
                tmpdir,
                {"os-specific/windows/mingw-w64/existing.nix": "existing"},
                {
                    "pkgs/os-specific/top-level-file.nix": "top-level",
                    "pkgs/os-specific/windows/mingw-w64/headers.nix": "headers",
                }
            )
            stats = run_check_new_files(
                corepkgs, nixpkgs,
                CHECK_NEW_FILES=["os-specific"],
                PATH_MAPPINGS={"os-specific": "pkgs/os-specific"},
                CHECK_NEW_FILES_IGNORE_NEW_DIRS=["os-specific"]
            )
            assert "os-specific/top-level-file.nix" not in stats.new_files_list
            assert "os-specific/windows/mingw-w64/headers.nix" in stats.new_files_list
    
    def test_check_new_files_only_if_in_path_mappings(self):
        """CHECK_NEW_FILES only works if directory is in PATH_MAPPINGS."""
        with tempfile.TemporaryDirectory() as tmpdir:
            corepkgs, nixpkgs = setup_dirs(
                tmpdir,
                {"some-dir/existing.nix": "existing"},
                {"pkgs/some-dir/new-file.nix": "new"}
            )
            stats = run_check_new_files(
                corepkgs, nixpkgs,
                CHECK_NEW_FILES=["some-dir"]
                # Note: NOT adding to PATH_MAPPINGS
            )
            assert "some-dir/new-file.nix" not in stats.new_files_list
            assert stats.new_files == 0
    
    def test_check_new_files_works_when_in_path_mappings(self):
        """CHECK_NEW_FILES works correctly when directory is in PATH_MAPPINGS."""
        with tempfile.TemporaryDirectory() as tmpdir:
            corepkgs, nixpkgs = setup_dirs(
                tmpdir,
                {"build-support/existing-dir/existing.nix": "existing"},
                {"pkgs/build-support/existing-dir/new-file.nix": "new"}
            )
            stats = run_check_new_files(
                corepkgs, nixpkgs,
                CHECK_NEW_FILES=["build-support"],
                PATH_MAPPINGS={"build-support": "pkgs/build-support"}
            )
            assert "build-support/existing-dir/new-file.nix" in stats.new_files_list
            assert stats.new_files >= 1


if __name__ == "__main__":
    import pytest
    pytest.main([__file__, "-v"])
