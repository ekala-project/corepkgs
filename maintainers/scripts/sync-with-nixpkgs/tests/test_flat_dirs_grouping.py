"""Tests for FLAT_DIRS grouping logic."""

import pytest


class TestGetFlatDirSubfolder:
    """Tests for get_flat_dir_subfolder function."""

    def test_pkgs_subfolder(self, script_module):
        """Test pkgs subfolder extraction."""
        result = script_module.get_flat_dir_subfolder("pkgs/curl/default.nix")
        assert result == ("pkgs", "curl")

    def test_pkgs_nested_file(self, script_module):
        """Test pkgs with nested file."""
        result = script_module.get_flat_dir_subfolder("pkgs/gcc/patches/fix.patch")
        assert result == ("pkgs", "gcc")

    def test_build_support_subfolder(self, script_module):
        """Test build-support subfolder extraction."""
        result = script_module.get_flat_dir_subfolder("build-support/fetchgit/default.nix")
        assert result == ("build-support", "fetchgit")

    def test_build_support_builder_sh(self, script_module):
        """Test build-support with builder.sh."""
        result = script_module.get_flat_dir_subfolder("build-support/fetchgit/builder.sh")
        assert result == ("build-support", "fetchgit")

    def test_common_updater_subfolder(self, script_module):
        """Test common-updater subfolder extraction."""
        result = script_module.get_flat_dir_subfolder("common-updater/scripts/update.sh")
        assert result == ("common-updater", "scripts")

    def test_systems_file(self, script_module):
        """Test systems with direct file."""
        result = script_module.get_flat_dir_subfolder("systems/default.nix")
        assert result == ("systems", "default.nix")

    def test_systems_parse(self, script_module):
        """Test systems with parse.nix."""
        result = script_module.get_flat_dir_subfolder("systems/parse.nix")
        assert result == ("systems", "parse.nix")

    def test_non_flat_dir_returns_none(self, script_module):
        """Test that non-flat dir returns None."""
        result = script_module.get_flat_dir_subfolder("python/default.nix")
        assert result is None

    def test_flat_dir_root_returns_none(self, script_module):
        """Test that flat dir root without subfolder returns None."""
        # This shouldn't happen in practice, but test the edge case
        result = script_module.get_flat_dir_subfolder("pkgs")
        assert result is None


class TestGetPatchOutputPath:
    """Tests for get_patch_output_path function."""

    def test_pkgs_patch_path(self, script_module):
        """Test patch path for pkgs package."""
        result = script_module.get_patch_output_path("pkgs/curl/default.nix")
        assert result == "patches/pkgs/curl.patch"

    def test_pkgs_nested_file_same_patch(self, script_module):
        """Test that nested files in same package get same patch."""
        result1 = script_module.get_patch_output_path("pkgs/curl/default.nix")
        result2 = script_module.get_patch_output_path("pkgs/curl/update.sh")
        assert result1 == result2 == "patches/pkgs/curl.patch"

    def test_build_support_patch_path(self, script_module):
        """Test patch path for build-support."""
        result = script_module.get_patch_output_path("build-support/fetchgit/default.nix")
        assert result == "patches/build-support/fetchgit.patch"

    def test_systems_patch_path(self, script_module):
        """Test patch path for systems."""
        result = script_module.get_patch_output_path("systems/default.nix")
        assert result == "patches/systems/default.nix.patch"

    def test_systems_parse_patch_path(self, script_module):
        """Test patch path for systems/parse.nix."""
        result = script_module.get_patch_output_path("systems/parse.nix")
        assert result == "patches/systems/parse.nix.patch"

    def test_python_patch_path(self, script_module):
        """Test patch path for python (non-flat)."""
        result = script_module.get_patch_output_path("python/default.nix")
        assert result == "patches/python/default.nix.patch"

    def test_python_hooks_patch_path(self, script_module):
        """Test patch path for python/hooks (non-flat)."""
        result = script_module.get_patch_output_path("python/hooks/setup-hook.sh")
        assert result == "patches/python/hooks/setup-hook.sh.patch"

    def test_perl_patch_path(self, script_module):
        """Test patch path for perl (non-flat)."""
        result = script_module.get_patch_output_path("perl/perl-packages.nix")
        assert result == "patches/perl/perl-packages.nix.patch"


class TestGroupFilesByPatch:
    """Tests for group_files_by_patch function."""

    def test_flat_dir_files_grouped(self, script_module):
        """Test that files in same flat dir subfolder are grouped."""
        files = [
            "pkgs/curl/default.nix",
            "pkgs/curl/update.sh",
            "pkgs/curl/patches/fix.patch",
        ]
        
        result = script_module.group_files_by_patch(files)
        
        assert "patches/pkgs/curl.patch" in result
        assert len(result["patches/pkgs/curl.patch"]) == 3
        assert set(result["patches/pkgs/curl.patch"]) == set(files)

    def test_different_packages_separate_patches(self, script_module):
        """Test that different packages get separate patches."""
        files = [
            "pkgs/curl/default.nix",
            "pkgs/wget/default.nix",
        ]
        
        result = script_module.group_files_by_patch(files)
        
        assert "patches/pkgs/curl.patch" in result
        assert "patches/pkgs/wget.patch" in result
        assert len(result) == 2

    def test_non_flat_dir_separate_patches(self, script_module):
        """Test that non-flat dir files get individual patches."""
        files = [
            "python/default.nix",
            "python/hooks/setup-hook.sh",
        ]
        
        result = script_module.group_files_by_patch(files)
        
        assert "patches/python/default.nix.patch" in result
        assert "patches/python/hooks/setup-hook.sh.patch" in result
        assert len(result) == 2

    def test_mixed_flat_and_non_flat(self, script_module):
        """Test mixed flat and non-flat directories."""
        files = [
            "pkgs/curl/default.nix",
            "pkgs/curl/update.sh",
            "python/default.nix",
        ]
        
        result = script_module.group_files_by_patch(files)
        
        assert "patches/pkgs/curl.patch" in result
        assert len(result["patches/pkgs/curl.patch"]) == 2
        assert "patches/python/default.nix.patch" in result
        assert len(result["patches/python/default.nix.patch"]) == 1

    def test_empty_files_list(self, script_module):
        """Test empty files list."""
        result = script_module.group_files_by_patch([])
        assert result == {}




