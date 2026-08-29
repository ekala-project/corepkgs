"""Tests for path resolution logic."""

import pytest
from pathlib import Path


class TestResolveNixpkgsPath:
    """Tests for resolve_nixpkgs_path function."""

    def test_direct_mapping_systems(self, script_module, mock_nixpkgs):
        """Test direct PATH_MAPPINGS lookup for systems."""
        result = script_module.resolve_nixpkgs_path("systems/default.nix", mock_nixpkgs)
        assert result is not None
        assert result == mock_nixpkgs / "lib" / "systems" / "default.nix"

    def test_direct_mapping_systems_parse(self, script_module, mock_nixpkgs):
        """Test systems/parse.nix mapping."""
        result = script_module.resolve_nixpkgs_path("systems/parse.nix", mock_nixpkgs)
        assert result is not None
        assert result == mock_nixpkgs / "lib" / "systems" / "parse.nix"

    def test_specific_override_gcc(self, script_module, mock_nixpkgs):
        """Test specific package override for gcc."""
        result = script_module.resolve_nixpkgs_path("pkgs/gcc/default.nix", mock_nixpkgs)
        assert result is not None
        assert result == mock_nixpkgs / "pkgs" / "development" / "compilers" / "gcc" / "default.nix"

    def test_by_name_prefix_extraction(self, script_module, mock_nixpkgs):
        """Test by-name 2-char prefix extraction and default.nix -> package.nix rename."""
        result = script_module.resolve_nixpkgs_path("pkgs/curl/default.nix", mock_nixpkgs)
        assert result is not None
        assert result == mock_nixpkgs / "pkgs" / "by-name" / "cu" / "curl" / "package.nix"

    def test_build_support_mapping(self, script_module, mock_nixpkgs):
        """Test build-support directory mapping."""
        result = script_module.resolve_nixpkgs_path(
            "build-support/fetchgit/default.nix", mock_nixpkgs
        )
        assert result is not None
        assert result == mock_nixpkgs / "pkgs" / "build-support" / "fetchgit" / "default.nix"

    def test_build_support_non_nix_file(self, script_module, mock_nixpkgs):
        """Test build-support mapping for non-.nix files."""
        result = script_module.resolve_nixpkgs_path(
            "build-support/fetchgit/builder.sh", mock_nixpkgs
        )
        assert result is not None
        assert result == mock_nixpkgs / "pkgs" / "build-support" / "fetchgit" / "builder.sh"

    def test_python_mapping(self, script_module, mock_nixpkgs):
        """Test python directory mapping."""
        result = script_module.resolve_nixpkgs_path("python/default.nix", mock_nixpkgs)
        assert result is not None
        assert result == mock_nixpkgs / "pkgs" / "development" / "interpreters" / "python" / "default.nix"

    def test_python_hooks_mapping(self, script_module, mock_nixpkgs):
        """Test python/hooks nested mapping."""
        result = script_module.resolve_nixpkgs_path("python/hooks/setup-hook.sh", mock_nixpkgs)
        assert result is not None
        assert result == mock_nixpkgs / "pkgs" / "development" / "interpreters" / "python" / "hooks" / "setup-hook.sh"

    def test_nonexistent_file_returns_none(self, script_module, mock_nixpkgs):
        """Test that non-existent file returns None."""
        result = script_module.resolve_nixpkgs_path("pkgs/nonexistent/default.nix", mock_nixpkgs)
        assert result is None

    def test_no_mapping_returns_none(self, script_module, mock_nixpkgs):
        """Test that file with no mapping returns None."""
        result = script_module.resolve_nixpkgs_path("some/random/path.nix", mock_nixpkgs)
        assert result is None

    def test_longest_prefix_wins(self, script_module, mock_nixpkgs):
        """Test that most specific (longest) mapping prefix wins."""
        # pkgs/gcc has a specific mapping that should override pkgs -> pkgs/by-name
        result = script_module.resolve_nixpkgs_path("pkgs/gcc/default.nix", mock_nixpkgs)
        assert result is not None
        # Should use pkgs/gcc mapping, not pkgs mapping
        assert "development/compilers/gcc" in str(result)
        assert "by-name" not in str(result)


class TestByNamePrefixExtraction:
    """Tests specifically for by-name prefix extraction edge cases."""

    def test_short_package_name(self, script_module, tmp_path):
        """Test package name shorter than 2 chars."""
        nixpkgs = tmp_path / "nixpkgs"
        (nixpkgs / "pkgs" / "by-name" / "a" / "a").mkdir(parents=True)
        (nixpkgs / "pkgs" / "by-name" / "a" / "a" / "package.nix").write_text("{ }: {}\n")
        
        # Package name "a" has only 1 char, prefix should still work
        result = script_module.resolve_nixpkgs_path("pkgs/a/default.nix", nixpkgs)
        # Will return None because 2-char prefix can't be extracted from 1-char name
        assert result is None

    def test_uppercase_package_name_lowercased(self, script_module, tmp_path):
        """Test that package name prefix is lowercased."""
        nixpkgs = tmp_path / "nixpkgs"
        (nixpkgs / "pkgs" / "by-name" / "my" / "MyPackage").mkdir(parents=True)
        (nixpkgs / "pkgs" / "by-name" / "my" / "MyPackage" / "package.nix").write_text("{ }: {}\n")
        
        result = script_module.resolve_nixpkgs_path("pkgs/MyPackage/default.nix", nixpkgs)
        assert result is not None
        assert "my/MyPackage" in str(result)

    def test_nested_file_in_package(self, script_module, tmp_path):
        """Test nested file within a by-name package."""
        nixpkgs = tmp_path / "nixpkgs"
        (nixpkgs / "pkgs" / "by-name" / "te" / "test-pkg" / "patches").mkdir(parents=True)
        (nixpkgs / "pkgs" / "by-name" / "te" / "test-pkg" / "package.nix").write_text("{ }: {}\n")
        (nixpkgs / "pkgs" / "by-name" / "te" / "test-pkg" / "patches" / "fix.patch").write_text("patch\n")
        
        result = script_module.resolve_nixpkgs_path("pkgs/test-pkg/patches/fix.patch", nixpkgs)
        assert result is not None
        assert result == nixpkgs / "pkgs" / "by-name" / "te" / "test-pkg" / "patches" / "fix.patch"




