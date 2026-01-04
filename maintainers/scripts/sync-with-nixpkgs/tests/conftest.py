"""Pytest configuration and fixtures for sync-with-nixpkgs tests."""

import sys
from pathlib import Path

import pytest

# Add parent directory to path so we can import script module
SCRIPT_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(SCRIPT_DIR))


@pytest.fixture
def script_module():
    """Import and return the script module for testing."""
    import script
    return script


@pytest.fixture
def mock_corepkgs(tmp_path):
    """
    Create a minimal corepkgs-like directory structure.
    
    Structure:
        corepkgs/
            pkgs/
                curl/
                    default.nix
                    update.sh
                gcc/
                    default.nix
            build-support/
                fetchgit/
                    default.nix
                    builder.sh
            systems/
                default.nix
                parse.nix
            python/
                default.nix
                hooks/
                    setup-hook.sh
            README.md
            flake.nix
            docs/
                guide.md
    """
    corepkgs = tmp_path / "corepkgs"
    corepkgs.mkdir()
    
    # pkgs/curl
    (corepkgs / "pkgs" / "curl").mkdir(parents=True)
    (corepkgs / "pkgs" / "curl" / "default.nix").write_text(
        '{ stdenv }:\nstdenv.mkDerivation {\n  pname = "curl";\n  # corepkgs version\n}\n'
    )
    (corepkgs / "pkgs" / "curl" / "update.sh").write_text("#!/bin/sh\necho update\n")
    
    # pkgs/gcc (has specific mapping)
    (corepkgs / "pkgs" / "gcc").mkdir(parents=True)
    (corepkgs / "pkgs" / "gcc" / "default.nix").write_text(
        '{ stdenv }:\nstdenv.mkDerivation {\n  pname = "gcc";\n}\n'
    )
    
    # build-support/fetchgit
    (corepkgs / "build-support" / "fetchgit").mkdir(parents=True)
    (corepkgs / "build-support" / "fetchgit" / "default.nix").write_text(
        '{ lib }:\nargs: lib.fetchgit args\n'
    )
    (corepkgs / "build-support" / "fetchgit" / "builder.sh").write_text(
        '#!/bin/bash\necho building\n'
    )
    
    # systems
    (corepkgs / "systems").mkdir(parents=True)
    (corepkgs / "systems" / "default.nix").write_text('{ lib }: {}\n')
    (corepkgs / "systems" / "parse.nix").write_text('{ lib }: { parse = x: x; }\n')
    
    # python
    (corepkgs / "python" / "hooks").mkdir(parents=True)
    (corepkgs / "python" / "default.nix").write_text('{ callPackage }: {}\n')
    (corepkgs / "python" / "hooks" / "setup-hook.sh").write_text('# setup hook\n')
    
    # Files that should be ignored
    (corepkgs / "README.md").write_text("# Corepkgs\n")
    (corepkgs / "flake.nix").write_text("{ }\n")
    
    # Directory that should be ignored
    (corepkgs / "docs").mkdir(parents=True)
    (corepkgs / "docs" / "guide.md").write_text("# Guide\n")
    
    # pkgs-many should be ignored
    (corepkgs / "pkgs-many" / "test").mkdir(parents=True)
    (corepkgs / "pkgs-many" / "test" / "default.nix").write_text("{ }: {}\n")
    
    return corepkgs


@pytest.fixture
def mock_nixpkgs(tmp_path):
    """
    Create a minimal nixpkgs-like directory structure matching the corepkgs fixture.
    
    Structure:
        nixpkgs/
            pkgs/
                by-name/
                    cu/
                        curl/
                            package.nix
                development/
                    compilers/
                        gcc/
                            default.nix
                build-support/
                    fetchgit/
                        default.nix
                        builder.sh
                interpreters/
                    python/
                        default.nix
                        hooks/
                            setup-hook.sh
            lib/
                systems/
                    default.nix
                    parse.nix
    """
    nixpkgs = tmp_path / "nixpkgs"
    nixpkgs.mkdir()
    
    # pkgs/by-name/cu/curl (note: package.nix, not default.nix)
    (nixpkgs / "pkgs" / "by-name" / "cu" / "curl").mkdir(parents=True)
    (nixpkgs / "pkgs" / "by-name" / "cu" / "curl" / "package.nix").write_text(
        '{ stdenv }:\nstdenv.mkDerivation {\n  pname = "curl";\n  # nixpkgs version\n}\n'
    )
    
    # pkgs/development/compilers/gcc
    (nixpkgs / "pkgs" / "development" / "compilers" / "gcc").mkdir(parents=True)
    (nixpkgs / "pkgs" / "development" / "compilers" / "gcc" / "default.nix").write_text(
        '{ stdenv }:\nstdenv.mkDerivation {\n  pname = "gcc";\n  # identical\n}\n'
    )
    
    # pkgs/build-support/fetchgit
    (nixpkgs / "pkgs" / "build-support" / "fetchgit").mkdir(parents=True)
    (nixpkgs / "pkgs" / "build-support" / "fetchgit" / "default.nix").write_text(
        '{ lib }:\nargs: lib.fetchgit args\n'
    )
    (nixpkgs / "pkgs" / "build-support" / "fetchgit" / "builder.sh").write_text(
        '#!/bin/bash\necho building from nixpkgs\n'
    )
    
    # lib/systems
    (nixpkgs / "lib" / "systems").mkdir(parents=True)
    (nixpkgs / "lib" / "systems" / "default.nix").write_text('{ lib }: {}\n')
    (nixpkgs / "lib" / "systems" / "parse.nix").write_text('{ lib }: { parse = x: x; }\n')
    
    # pkgs/development/interpreters/python
    (nixpkgs / "pkgs" / "development" / "interpreters" / "python" / "hooks").mkdir(parents=True)
    (nixpkgs / "pkgs" / "development" / "interpreters" / "python" / "default.nix").write_text(
        '{ callPackage }: {}\n'
    )
    (nixpkgs / "pkgs" / "development" / "interpreters" / "python" / "hooks" / "setup-hook.sh").write_text(
        '# setup hook from nixpkgs\n'
    )
    
    return nixpkgs


@pytest.fixture
def patches_dir(tmp_path):
    """Create an empty patches directory."""
    patches = tmp_path / "patches"
    patches.mkdir()
    return patches

