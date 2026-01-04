"""Integration tests for the complete sync workflow."""

import subprocess
import sys
from pathlib import Path

import pytest


class TestCollectCorepkgsFiles:
    """Tests for collect_corepkgs_files function."""

    def test_collects_regular_files(self, script_module, mock_corepkgs):
        """Test that regular files are collected."""
        files = script_module.collect_corepkgs_files(mock_corepkgs)
        
        assert "pkgs/curl/default.nix" in files
        assert "pkgs/curl/update.sh" in files
        assert "build-support/fetchgit/default.nix" in files

    def test_ignores_ignored_dirs(self, script_module, mock_corepkgs):
        """Test that ignored directories are skipped."""
        files = script_module.collect_corepkgs_files(mock_corepkgs)
        
        # docs should be ignored
        assert not any("docs/" in f for f in files)
        
        # pkgs-many should be ignored
        assert not any("pkgs-many/" in f for f in files)

    def test_ignores_ignored_files(self, script_module, mock_corepkgs):
        """Test that ignored files are skipped."""
        files = script_module.collect_corepkgs_files(mock_corepkgs)
        
        assert "README.md" not in files
        assert "flake.nix" not in files

    def test_ignores_hidden_files(self, script_module, mock_corepkgs):
        """Test that hidden files/dirs are skipped."""
        # Create a hidden file
        (mock_corepkgs / ".hidden").write_text("hidden\n")
        (mock_corepkgs / ".hidden-dir").mkdir()
        (mock_corepkgs / ".hidden-dir" / "file.nix").write_text("{ }\n")
        
        files = script_module.collect_corepkgs_files(mock_corepkgs)
        
        assert ".hidden" not in files
        assert not any(".hidden-dir" in f for f in files)

    def test_files_are_sorted(self, script_module, mock_corepkgs):
        """Test that collected files are sorted."""
        files = script_module.collect_corepkgs_files(mock_corepkgs)
        
        assert files == sorted(files)


class TestEndToEnd:
    """End-to-end integration tests."""

    def test_generates_patches_for_different_files(
        self, script_module, mock_corepkgs, mock_nixpkgs, tmp_path
    ):
        """Test that patches are generated for files that differ."""
        output_dir = tmp_path / "output"
        output_dir.mkdir()
        
        # Run the main logic manually (not via CLI)
        files = script_module.collect_corepkgs_files(mock_corepkgs)
        file_groups = script_module.group_files_by_patch(files)
        
        patches_generated = 0
        
        for patch_path, group_files in file_groups.items():
            file_pairs = []
            
            for corepkgs_rel_path in group_files:
                corepkgs_file = mock_corepkgs / corepkgs_rel_path
                nixpkgs_path = script_module.resolve_nixpkgs_path(
                    corepkgs_rel_path, mock_nixpkgs
                )
                
                if nixpkgs_path is None:
                    continue
                
                nixpkgs_rel_path = str(nixpkgs_path.relative_to(mock_nixpkgs))
                file_pairs.append((
                    corepkgs_rel_path, corepkgs_file, nixpkgs_path, nixpkgs_rel_path
                ))
            
            if not file_pairs:
                continue
            
            patch_content = script_module.generate_combined_patch(file_pairs)
            
            if patch_content:
                patches_generated += 1
                # Write the patch
                full_path = output_dir / patch_path.replace("patches/", "", 1)
                full_path.parent.mkdir(parents=True, exist_ok=True)
                full_path.write_text(patch_content)
        
        # Should have at least some patches
        assert patches_generated > 0
        
        # Check that curl patch exists (files differ)
        curl_patch = output_dir / "pkgs" / "curl.patch"
        assert curl_patch.exists()
        content = curl_patch.read_text()
        assert "corepkgs version" in content or "nixpkgs version" in content

    def test_identical_files_no_patch(
        self, script_module, mock_corepkgs, mock_nixpkgs, tmp_path
    ):
        """Test that identical files don't produce patches."""
        # systems/default.nix is identical in both
        corepkgs_file = mock_corepkgs / "systems" / "default.nix"
        nixpkgs_path = script_module.resolve_nixpkgs_path(
            "systems/default.nix", mock_nixpkgs
        )
        
        assert nixpkgs_path is not None
        
        # Content is identical
        assert corepkgs_file.read_text() == nixpkgs_path.read_text()
        
        patch = script_module.generate_patch(
            corepkgs_file, nixpkgs_path, "systems/default.nix", str(nixpkgs_path.relative_to(mock_nixpkgs))
        )
        
        assert patch is None

    def test_missing_files_tracked(self, script_module, mock_corepkgs, mock_nixpkgs):
        """Test that files missing in nixpkgs are tracked."""
        # pkgs/curl/update.sh doesn't exist in mock_nixpkgs
        nixpkgs_path = script_module.resolve_nixpkgs_path(
            "pkgs/curl/update.sh", mock_nixpkgs
        )
        
        # Should return None since file doesn't exist
        assert nixpkgs_path is None

    def test_patch_directory_structure(
        self, script_module, mock_corepkgs, mock_nixpkgs, tmp_path
    ):
        """Test that patch output directory structure is correct."""
        output_dir = tmp_path / "patches"
        output_dir.mkdir()
        
        # Simulate writing a few patches
        (output_dir / "pkgs").mkdir()
        (output_dir / "pkgs" / "curl.patch").write_text("patch content\n")
        
        (output_dir / "build-support").mkdir()
        (output_dir / "build-support" / "fetchgit.patch").write_text("patch content\n")
        
        (output_dir / "python").mkdir()
        (output_dir / "python" / "default.nix.patch").write_text("patch content\n")
        
        # Verify structure
        assert (output_dir / "pkgs" / "curl.patch").exists()
        assert (output_dir / "build-support" / "fetchgit.patch").exists()
        assert (output_dir / "python" / "default.nix.patch").exists()


class TestCLI:
    """Tests for command-line interface."""

    def test_dry_run_no_files_written(self, mock_corepkgs, mock_nixpkgs, tmp_path):
        """Test that dry-run mode doesn't write files."""
        output_dir = tmp_path / "output"
        
        # Run script with --dry-run
        script_path = Path(__file__).parent.parent / "script.py"
        
        result = subprocess.run(
            [
                sys.executable,
                str(script_path),
                "--corepkgs", str(mock_corepkgs),
                "--nixpkgs", str(mock_nixpkgs),
                "--output", str(output_dir),
                "--dry-run",
            ],
            capture_output=True,
            text=True,
        )
        
        # Should succeed
        assert result.returncode == 0
        
        # Output directory should not be created (or be empty)
        if output_dir.exists():
            # Should only have the missing-in-nixpkgs.txt if anything
            files = list(output_dir.rglob("*.patch"))
            assert len(files) == 0

    def test_verbose_output(self, mock_corepkgs, mock_nixpkgs, tmp_path):
        """Test that verbose mode produces extra output."""
        output_dir = tmp_path / "output"
        output_dir.mkdir()
        
        script_path = Path(__file__).parent.parent / "script.py"
        
        result = subprocess.run(
            [
                sys.executable,
                str(script_path),
                "--corepkgs", str(mock_corepkgs),
                "--nixpkgs", str(mock_nixpkgs),
                "--output", str(output_dir),
                "--verbose",
                "--dry-run",
            ],
            capture_output=True,
            text=True,
        )
        
        assert result.returncode == 0
        # Verbose should show paths
        assert "Corepkgs root:" in result.stdout
        assert "Nixpkgs root:" in result.stdout

    def test_missing_corepkgs_error(self, tmp_path):
        """Test error when corepkgs directory doesn't exist."""
        script_path = Path(__file__).parent.parent / "script.py"
        
        result = subprocess.run(
            [
                sys.executable,
                str(script_path),
                "--corepkgs", str(tmp_path / "nonexistent"),
                "--nixpkgs", str(tmp_path),
            ],
            capture_output=True,
            text=True,
        )
        
        assert result.returncode != 0
        assert "Error" in result.stderr

    def test_missing_nixpkgs_error(self, mock_corepkgs, tmp_path):
        """Test error when nixpkgs directory doesn't exist."""
        script_path = Path(__file__).parent.parent / "script.py"
        
        result = subprocess.run(
            [
                sys.executable,
                str(script_path),
                "--corepkgs", str(mock_corepkgs),
                "--nixpkgs", str(tmp_path / "nonexistent"),
            ],
            capture_output=True,
            text=True,
        )
        
        assert result.returncode != 0
        assert "Error" in result.stderr


class TestMissingFilesReport:
    """Tests for missing files report generation."""

    def test_missing_files_reported(
        self, script_module, mock_corepkgs, mock_nixpkgs, tmp_path
    ):
        """Test that missing files are reported."""
        files = script_module.collect_corepkgs_files(mock_corepkgs)
        
        missing = []
        for f in files:
            if script_module.resolve_nixpkgs_path(f, mock_nixpkgs) is None:
                missing.append(f)
        
        # Should have some missing files (e.g., update.sh)
        assert len(missing) > 0
        assert "pkgs/curl/update.sh" in missing

    def test_missing_report_format(self, tmp_path):
        """Test the format of missing files report."""
        report_path = tmp_path / "missing-in-nixpkgs.txt"
        
        missing_files = [
            "pkgs/curl/update.sh",
            "pkgs/foo/default.nix",
            "python/custom.nix",
        ]
        
        # Simulate writing the report
        with open(report_path, 'w') as f:
            f.write("# Files in corepkgs that have no corresponding file in nixpkgs\n")
            f.write("# Generated by sync-with-nixpkgs script\n\n")
            for file_path in sorted(missing_files):
                f.write(f"{file_path}\n")
        
        content = report_path.read_text()
        
        assert "# Files in corepkgs" in content
        assert "pkgs/curl/update.sh" in content
        assert "pkgs/foo/default.nix" in content




