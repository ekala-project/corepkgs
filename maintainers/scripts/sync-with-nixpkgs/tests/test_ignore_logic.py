"""Tests for ignore logic (IGNORE_DIRS, IGNORE_FILES, IGNORE_NEW)."""

import pytest


class TestShouldSkipPath:
    """Tests for should_skip_path function."""

    def test_ignore_dirs_github(self, script_module):
        """Test that .github directory is ignored."""
        assert script_module.should_skip_path(".github") is True
        assert script_module.should_skip_path(".github/workflows/ci.yml") is True

    def test_ignore_dirs_docs(self, script_module):
        """Test that docs directory is ignored."""
        assert script_module.should_skip_path("docs") is True
        assert script_module.should_skip_path("docs/README.md") is True
        assert script_module.should_skip_path("docs/guide/intro.md") is True

    def test_ignore_dirs_maintainers(self, script_module):
        """Test that maintainers directory is ignored."""
        assert script_module.should_skip_path("maintainers") is True
        assert script_module.should_skip_path("maintainers/scripts/test.py") is True

    def test_ignore_dirs_pkgs_many(self, script_module):
        """Test that pkgs-many directory is ignored."""
        assert script_module.should_skip_path("pkgs-many") is True
        assert script_module.should_skip_path("pkgs-many/boost/default.nix") is True

    def test_ignore_dirs_patches(self, script_module):
        """Test that patches directory is ignored."""
        assert script_module.should_skip_path("patches") is True
        assert script_module.should_skip_path("patches/pkgs/curl.patch") is True

    def test_ignore_dirs_stdenv_darwin(self, script_module):
        """Test that stdenv/darwin is ignored."""
        assert script_module.should_skip_path("stdenv/darwin") is True
        assert script_module.should_skip_path("stdenv/darwin/default.nix") is True

    def test_ignore_dirs_stdenv_cygwin(self, script_module):
        """Test that stdenv/cygwin is ignored."""
        assert script_module.should_skip_path("stdenv/cygwin") is True

    def test_ignore_dirs_stdenv_freebsd(self, script_module):
        """Test that stdenv/freebsd is ignored."""
        assert script_module.should_skip_path("stdenv/freebsd") is True

    def test_ignore_files_readme(self, script_module):
        """Test that root README.md is ignored."""
        assert script_module.should_skip_path("README.md") is True
        # README.md in subdirectories is NOT ignored (only exact path matches)
        assert script_module.should_skip_path("pkgs/curl/README.md") is False

    def test_ignore_files_license(self, script_module):
        """Test that LICENSE is ignored."""
        assert script_module.should_skip_path("LICENSE") is True

    def test_ignore_files_gitignore(self, script_module):
        """Test that .gitignore is ignored."""
        assert script_module.should_skip_path(".gitignore") is True

    def test_ignore_files_flake_nix(self, script_module):
        """Test that flake.nix is ignored."""
        assert script_module.should_skip_path("flake.nix") is True

    def test_ignore_files_flake_lock(self, script_module):
        """Test that flake.lock is ignored."""
        assert script_module.should_skip_path("flake.lock") is True

    def test_ignore_files_root_default_nix(self, script_module):
        """Test that root default.nix is ignored."""
        assert script_module.should_skip_path("default.nix") is True

    def test_ignore_files_lib_nix(self, script_module):
        """Test that lib.nix is ignored."""
        assert script_module.should_skip_path("lib.nix") is True

    def test_ignore_files_pins_nix(self, script_module):
        """Test that pins.nix is ignored."""
        assert script_module.should_skip_path("pins.nix") is True

    def test_ignore_files_top_level_nix(self, script_module):
        """Test that top-level.nix is ignored."""
        assert script_module.should_skip_path("top-level.nix") is True

    def test_ignore_files_stdenv_aliases(self, script_module):
        """Test that stdenv/aliases.nix is ignored."""
        assert script_module.should_skip_path("stdenv/aliases.nix") is True

    def test_not_ignored_regular_file(self, script_module):
        """Test that regular files are not ignored."""
        assert script_module.should_skip_path("pkgs/curl/default.nix") is False
        assert script_module.should_skip_path("build-support/fetchgit/default.nix") is False
        assert script_module.should_skip_path("systems/parse.nix") is False

    def test_not_ignored_stdenv_linux(self, script_module):
        """Test that stdenv/linux is not ignored."""
        assert script_module.should_skip_path("stdenv/linux") is False
        assert script_module.should_skip_path("stdenv/linux/default.nix") is False


class TestShouldCheckNewFiles:
    """Tests for should_check_new_files function."""

    def test_check_new_build_support(self, script_module):
        """Test that build-support is checked for new files."""
        assert script_module.should_check_new_files("build-support") is True
        assert script_module.should_check_new_files("build-support/fetchgit") is True

    def test_check_new_pkgs(self, script_module):
        """Test that pkgs is checked for new files."""
        assert script_module.should_check_new_files("pkgs") is True
        assert script_module.should_check_new_files("pkgs/curl") is True

    def test_check_new_python(self, script_module):
        """Test that python is checked for new files."""
        assert script_module.should_check_new_files("python") is True
        assert script_module.should_check_new_files("python/hooks") is True

    def test_check_new_systems(self, script_module):
        """Test that systems is checked for new files."""
        assert script_module.should_check_new_files("systems") is True

    def test_ignore_new_perl_patches(self, script_module):
        """Test that perl/patches is NOT checked for new files."""
        assert script_module.should_check_new_files("perl/patches") is False
        assert script_module.should_check_new_files("perl/patches/some.patch") is False

    def test_ignore_new_stdenv(self, script_module):
        """Test that stdenv is NOT checked for new files."""
        assert script_module.should_check_new_files("stdenv") is False
        assert script_module.should_check_new_files("stdenv/linux") is False

    def test_not_in_check_list(self, script_module):
        """Test that directories not in CHECK_NEW_FILES return False."""
        assert script_module.should_check_new_files("perl") is False
        assert script_module.should_check_new_files("config") is False
        assert script_module.should_check_new_files("random/dir") is False


class TestIsFlatDir:
    """Tests for is_flat_dir function."""

    def test_flat_dir_build_support(self, script_module):
        """Test that build-support is a flat dir."""
        assert script_module.is_flat_dir("build-support") is True
        assert script_module.is_flat_dir("build-support/fetchgit") is True
        assert script_module.is_flat_dir("build-support/fetchgit/default.nix") is True

    def test_flat_dir_pkgs(self, script_module):
        """Test that pkgs is a flat dir."""
        assert script_module.is_flat_dir("pkgs") is True
        assert script_module.is_flat_dir("pkgs/curl") is True
        assert script_module.is_flat_dir("pkgs/curl/default.nix") is True

    def test_flat_dir_systems(self, script_module):
        """Test that systems is a flat dir."""
        assert script_module.is_flat_dir("systems") is True
        assert script_module.is_flat_dir("systems/default.nix") is True

    def test_flat_dir_common_updater(self, script_module):
        """Test that common-updater is a flat dir."""
        assert script_module.is_flat_dir("common-updater") is True

    def test_flat_dir_os_specific_linux(self, script_module):
        """Test that os-specific/linux is a flat dir."""
        assert script_module.is_flat_dir("os-specific/linux") is True
        assert script_module.is_flat_dir("os-specific/linux/kernel-headers") is True

    def test_not_flat_dir_python(self, script_module):
        """Test that python is NOT a flat dir."""
        assert script_module.is_flat_dir("python") is False
        assert script_module.is_flat_dir("python/hooks") is False

    def test_not_flat_dir_perl(self, script_module):
        """Test that perl is NOT a flat dir."""
        assert script_module.is_flat_dir("perl") is False

    def test_not_flat_dir_stdenv(self, script_module):
        """Test that stdenv is NOT a flat dir."""
        assert script_module.is_flat_dir("stdenv") is False

