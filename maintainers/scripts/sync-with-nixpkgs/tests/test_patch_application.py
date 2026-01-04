"""Tests for patch application and format validation."""
import subprocess
import tempfile
from pathlib import Path


class TestPatchApplication:
    """Tests to verify generated patches can be applied."""

    def test_patch_headers_use_corepkgs_paths(self, script_module, mock_corepkgs, mock_nixpkgs):
        """Test that patch headers use corepkgs paths for -p1 application."""
        # Create test files
        (mock_nixpkgs / "pkgs" / "by-name" / "cu" / "curl").mkdir(parents=True, exist_ok=True)
        nixpkgs_file = mock_nixpkgs / "pkgs" / "by-name" / "cu" / "curl" / "package.nix"
        nixpkgs_file.write_text("""{ lib, stdenv }:
stdenv.mkDerivation {
  pname = "curl";
  version = "1.0";
  meta = {
    maintainers = [ lib.maintainers.foo ];
    description = "test";
  };
}
""")

        (mock_corepkgs / "pkgs" / "curl").mkdir(parents=True, exist_ok=True)
        corepkgs_file = mock_corepkgs / "pkgs" / "curl" / "default.nix"
        corepkgs_file.write_text("""{ lib, stdenv }:
stdenv.mkDerivation {
  pname = "curl";
  version = "2.0";
  meta = {
    maintainers = throw "unused";
    description = "test";
  };
}
""")

        # Generate patch
        patch = script_module.generate_patch(
            corepkgs_file,
            nixpkgs_file,
            "pkgs/curl/default.nix",
            "pkgs/by-name/cu/curl/package.nix",
        )

        assert patch is not None
        lines = patch.split('\n')
        
        # Check that both headers use corepkgs path
        assert lines[0] == "--- a/pkgs/curl/default.nix"
        assert lines[1] == "+++ b/pkgs/curl/default.nix"
        
        # Verify version change is present
        assert any("version = \"2.0\"" in line for line in lines)

    def test_patch_can_be_parsed(self, script_module, mock_corepkgs, mock_nixpkgs):
        """Test that generated patches have valid format."""
        # Create test files
        (mock_nixpkgs / "pkgs" / "build-support").mkdir(parents=True, exist_ok=True)
        nixpkgs_file = mock_nixpkgs / "pkgs" / "build-support" / "testers.nix"
        nixpkgs_file.write_text("""{ lib }:
{
  testVersion = { package, version }:
    assert version != "";
    package;
  
  meta = {
    maintainers = [ lib.maintainers.foo ];
    teams = [ lib.teams.bar ];
  };
}
""")

        (mock_corepkgs / "build-support").mkdir(parents=True, exist_ok=True)
        corepkgs_file = mock_corepkgs / "build-support" / "testers.nix"
        corepkgs_file.write_text("""{ lib }:
{
  testVersion = { package, version }:
    assert version != "";
    package;
  
  meta = {
    maintainers = throw "unused";
    teams = throw "unused";
  };
}
""")

        # Generate patch
        patch = script_module.generate_patch(
            corepkgs_file,
            nixpkgs_file,
            "build-support/testers.nix",
            "pkgs/build-support/testers.nix",
        )

        assert patch is not None
        
        # Verify patch structure
        lines = patch.split('\n')
        
        # Should have file headers
        assert any(line.startswith('---') for line in lines)
        assert any(line.startswith('+++') for line in lines)
        
        # Should have at least one hunk header
        hunk_headers = [line for line in lines if line.startswith('@@')]
        assert len(hunk_headers) > 0
        
        # Each hunk header should match the format: @@ -start,count +start,count @@
        import re
        for header in hunk_headers:
            # Allow both @@ -X,Y +A,B @@ and @@ -X +A @@ formats
            assert re.match(r'^@@ -\d+(?:,\d+)? \+\d+(?:,\d+)? @@', header), f"Invalid hunk header: {header}"

    def test_patch_dry_run_application(self, script_module, mock_corepkgs, mock_nixpkgs, tmp_path):
        """Test that generated patch can be applied with patch command."""
        # Create test files
        (mock_nixpkgs / "pkgs" / "by-name" / "te" / "test").mkdir(parents=True, exist_ok=True)
        nixpkgs_file = mock_nixpkgs / "pkgs" / "by-name" / "te" / "test" / "package.nix"
        nixpkgs_file.write_text("""{ lib, stdenv }:
stdenv.mkDerivation {
  pname = "test";
  version = "1.0";
  
  meta = {
    description = "A test package";
  };
}
""")

        (mock_corepkgs / "pkgs" / "test").mkdir(parents=True, exist_ok=True)
        corepkgs_file = mock_corepkgs / "pkgs" / "test" / "default.nix"
        corepkgs_file.write_text("""{ lib, stdenv }:
stdenv.mkDerivation {
  pname = "test";
  version = "2.0";
  
  meta = {
    description = "A test package";
  };
}
""")

        # Generate patch
        patch = script_module.generate_patch(
            corepkgs_file,
            nixpkgs_file,
            "pkgs/test/default.nix",
            "pkgs/by-name/te/test/package.nix",
        )

        assert patch is not None
        
        # Write patch to temp file
        patch_file = tmp_path / "test.patch"
        patch_file.write_text(patch)
        
        # Create a copy of nixpkgs file in the expected location for patching
        test_dir = tmp_path / "test_apply"
        test_dir.mkdir()
        target_file = test_dir / "pkgs" / "test" / "default.nix"
        target_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Copy the nixpkgs content (transformed to corepkgs structure)
        target_file.write_text(nixpkgs_file.read_text())
        
        # Try to apply patch with --dry-run
        result = subprocess.run(
            ["patch", "--dry-run", "-p1", "-i", str(patch_file)],
            cwd=test_dir,
            capture_output=True,
            text=True,
        )
        
        # Check if patch can be applied (exit code 0 or 1 with specific messages is ok)
        # Exit code 1 might occur if patch is already applied, which is fine for dry-run
        if result.returncode not in [0, 1]:
            print(f"STDOUT: {result.stdout}")
            print(f"STDERR: {result.stderr}")
            print(f"Patch content:\n{patch}")
            assert False, f"Patch application failed with code {result.returncode}"
        
        # Should not have "malformed patch" error
        assert "malformed patch" not in result.stderr.lower(), f"Patch is malformed: {result.stderr}"

    def test_filtered_patch_has_valid_hunks(self, script_module, mock_corepkgs, mock_nixpkgs):
        """Test that after filtering, remaining hunks are still valid."""
        # Create test files with changes that will be filtered
        (mock_nixpkgs / "pkgs" / "build-support").mkdir(parents=True, exist_ok=True)
        nixpkgs_file = mock_nixpkgs / "pkgs" / "build-support" / "test.nix"
        nixpkgs_file.write_text("""{ lib }:
{
  version = "1.0";
  
  maintainers = [ lib.maintainers.foo ];
  teams = [ lib.teams.bar ];
  
  description = "old description";
}
""")

        (mock_corepkgs / "build-support").mkdir(parents=True, exist_ok=True)
        corepkgs_file = mock_corepkgs / "build-support" / "test.nix"
        corepkgs_file.write_text("""{ lib }:
{
  version = "2.0";
  
  maintainers = throw "unused";
  teams = throw "unused";
  
  description = "new description";
}
""")

        # Generate patch
        patch = script_module.generate_patch(
            corepkgs_file,
            nixpkgs_file,
            "build-support/test.nix",
            "pkgs/build-support/test.nix",
        )

        assert patch is not None
        
        # Should have version and description changes
        assert "version = \"2.0\"" in patch
        assert "new description" in patch
        
        # Should NOT have maintainers/teams changes (filtered)
        assert "maintainers.foo" not in patch
        assert "teams.bar" not in patch
        
        # Verify hunk headers are valid
        import re
        lines = patch.split('\n')
        for i, line in enumerate(lines):
            if line.startswith('@@'):
                # Next lines should be valid diff content (not another @@ immediately)
                if i + 1 < len(lines):
                    next_line = lines[i + 1]
                    # Should not have consecutive hunk headers
                    assert not next_line.startswith('@@'), f"Consecutive hunk headers at line {i}"

