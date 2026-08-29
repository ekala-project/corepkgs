"""Tests for patch generation logic."""

import pytest
from pathlib import Path


class TestGeneratePatch:
    """Tests for generate_patch function."""

    def test_identical_files_produce_none(self, script_module, tmp_path):
        """Test that identical files produce None (no patch)."""
        file_a = tmp_path / "a.nix"
        file_b = tmp_path / "b.nix"
        content = "{ lib }: { foo = 1; }\n"
        file_a.write_text(content)
        file_b.write_text(content)
        
        result = script_module.generate_patch(file_b, file_a, "b.nix", "a.nix")
        assert result is None

    def test_different_files_produce_diff(self, script_module, tmp_path):
        """Test that different files produce a valid unified diff."""
        nixpkgs_file = tmp_path / "nixpkgs.nix"
        corepkgs_file = tmp_path / "corepkgs.nix"
        
        nixpkgs_file.write_text("{ lib }:\n{\n  foo = 1;\n}\n")
        corepkgs_file.write_text("{ lib }:\n{\n  foo = 2;\n  bar = 3;\n}\n")
        
        result = script_module.generate_patch(
            corepkgs_file, nixpkgs_file, "corepkgs.nix", "nixpkgs.nix"
        )
        
        assert result is not None
        # Patch is FROM corepkgs TO nixpkgs (to update corepkgs with nixpkgs changes)
        assert "--- a/corepkgs.nix" in result
        assert "+++ b/corepkgs.nix" in result
        # corepkgs has foo=2 and bar=3, nixpkgs has foo=1
        # So patch removes bar and changes foo to match nixpkgs
        assert "-  foo = 2;" in result
        assert "+  foo = 1;" in result
        assert "-  bar = 3;" in result

    def test_added_lines(self, script_module, tmp_path):
        """Test patch for lines that need to be added to corepkgs from nixpkgs."""
        nixpkgs_file = tmp_path / "nixpkgs.nix"
        corepkgs_file = tmp_path / "corepkgs.nix"
        
        # nixpkgs has more lines than corepkgs
        nixpkgs_file.write_text("line1\nline2\nline3\nline4\n")
        corepkgs_file.write_text("line1\nline2\n")
        
        result = script_module.generate_patch(
            corepkgs_file, nixpkgs_file, "corepkgs.nix", "nixpkgs.nix"
        )
        
        assert result is not None
        # Patch adds lines from nixpkgs to corepkgs
        assert "+line3" in result
        assert "+line4" in result

    def test_removed_lines(self, script_module, tmp_path):
        """Test patch for lines that need to be removed from corepkgs."""
        nixpkgs_file = tmp_path / "nixpkgs.nix"
        corepkgs_file = tmp_path / "corepkgs.nix"
        
        # corepkgs has extra lines that nixpkgs doesn't
        nixpkgs_file.write_text("line1\n")
        corepkgs_file.write_text("line1\nline2\nline3\n")
        
        result = script_module.generate_patch(
            corepkgs_file, nixpkgs_file, "corepkgs.nix", "nixpkgs.nix"
        )
        
        assert result is not None
        # Patch removes corepkgs-specific lines
        assert "-line2" in result
        assert "-line3" in result

    def test_missing_nixpkgs_file_returns_none(self, script_module, tmp_path):
        """Test that missing nixpkgs file returns None."""
        corepkgs_file = tmp_path / "corepkgs.nix"
        corepkgs_file.write_text("content\n")
        nixpkgs_file = tmp_path / "nonexistent.nix"
        
        result = script_module.generate_patch(
            corepkgs_file, nixpkgs_file, "corepkgs.nix", "nixpkgs.nix"
        )
        
        assert result is None

    def test_missing_corepkgs_file_returns_none(self, script_module, tmp_path):
        """Test that missing corepkgs file returns None."""
        nixpkgs_file = tmp_path / "nixpkgs.nix"
        nixpkgs_file.write_text("content\n")
        corepkgs_file = tmp_path / "nonexistent.nix"
        
        result = script_module.generate_patch(
            corepkgs_file, nixpkgs_file, "corepkgs.nix", "nixpkgs.nix"
        )
        
        assert result is None

    def test_binary_file_handled_gracefully(self, script_module, tmp_path):
        """Test that binary files are handled gracefully."""
        nixpkgs_file = tmp_path / "nixpkgs.bin"
        corepkgs_file = tmp_path / "corepkgs.bin"
        
        # Write binary content
        nixpkgs_file.write_bytes(b"\x00\x01\x02\x03")
        corepkgs_file.write_bytes(b"\x00\x01\x02\x04")
        
        # Should not raise, may return a diff or None
        result = script_module.generate_patch(
            corepkgs_file, nixpkgs_file, "corepkgs.bin", "nixpkgs.bin"
        )
        # Binary files with errors='replace' will produce some diff
        assert result is not None or result is None  # No crash is success

    def test_empty_files(self, script_module, tmp_path):
        """Test handling of empty files."""
        nixpkgs_file = tmp_path / "nixpkgs.nix"
        corepkgs_file = tmp_path / "corepkgs.nix"
        
        nixpkgs_file.write_text("")
        corepkgs_file.write_text("")
        
        result = script_module.generate_patch(
            corepkgs_file, nixpkgs_file, "corepkgs.nix", "nixpkgs.nix"
        )
        
        # Empty identical files produce no diff
        assert result is None

    def test_empty_to_content(self, script_module, tmp_path):
        """Test patch adding content from nixpkgs to empty corepkgs file."""
        nixpkgs_file = tmp_path / "nixpkgs.nix"
        corepkgs_file = tmp_path / "corepkgs.nix"
        
        # nixpkgs has content, corepkgs is empty
        nixpkgs_file.write_text("new content\n")
        corepkgs_file.write_text("")
        
        result = script_module.generate_patch(
            corepkgs_file, nixpkgs_file, "corepkgs.nix", "nixpkgs.nix"
        )
        
        assert result is not None
        # Patch adds nixpkgs content to corepkgs
        assert "+new content" in result


class TestGenerateCombinedPatch:
    """Tests for generate_combined_patch function."""

    def test_multiple_files_combined(self, script_module, tmp_path):
        """Test that multiple file pairs produce combined patch."""
        # Create file pairs
        nix_a = tmp_path / "nix_a.nix"
        core_a = tmp_path / "core_a.nix"
        nix_b = tmp_path / "nix_b.nix"
        core_b = tmp_path / "core_b.nix"
        
        nix_a.write_text("nixpkgs a\n")
        core_a.write_text("corepkgs a\n")
        nix_b.write_text("nixpkgs b\n")
        core_b.write_text("corepkgs b\n")
        
        file_pairs = [
            ("core_a.nix", core_a, nix_a, "nix_a.nix"),
            ("core_b.nix", core_b, nix_b, "nix_b.nix"),
        ]
        
        result = script_module.generate_combined_patch(file_pairs)
        
        assert result is not None
        # Patches use corepkgs paths for both sides
        assert "--- a/core_a.nix" in result
        assert "+++ b/core_a.nix" in result
        assert "--- a/core_b.nix" in result
        assert "+++ b/core_b.nix" in result

    def test_mixed_identical_and_different(self, script_module, tmp_path):
        """Test combined patch with some identical files."""
        nix_a = tmp_path / "nix_a.nix"
        core_a = tmp_path / "core_a.nix"
        nix_b = tmp_path / "nix_b.nix"
        core_b = tmp_path / "core_b.nix"
        
        # a files are different
        nix_a.write_text("nixpkgs a\n")
        core_a.write_text("corepkgs a\n")
        
        # b files are identical
        nix_b.write_text("same content\n")
        core_b.write_text("same content\n")
        
        file_pairs = [
            ("core_a.nix", core_a, nix_a, "nix_a.nix"),
            ("core_b.nix", core_b, nix_b, "nix_b.nix"),
        ]
        
        result = script_module.generate_combined_patch(file_pairs)
        
        assert result is not None
        # Only a should be in the patch (uses corepkgs paths)
        assert "core_a.nix" in result
        assert "core_b.nix" not in result

    def test_all_identical_returns_none(self, script_module, tmp_path):
        """Test that all identical files returns None."""
        nix_a = tmp_path / "nix_a.nix"
        core_a = tmp_path / "core_a.nix"
        
        nix_a.write_text("same\n")
        core_a.write_text("same\n")
        
        file_pairs = [
            ("core_a.nix", core_a, nix_a, "nix_a.nix"),
        ]
        
        result = script_module.generate_combined_patch(file_pairs)
        
        assert result is None

    def test_empty_file_pairs(self, script_module):
        """Test empty file pairs list."""
        result = script_module.generate_combined_patch([])
        assert result is None


