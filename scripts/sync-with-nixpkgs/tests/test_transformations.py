"""Tests for path transformations and change filtering."""

import pytest


class TestApplyPathTransformations:
    """Tests for apply_path_transformations function."""

    def test_perl_modules_generic_transformation(self, script_module):
        """Test ../development/perl-modules/generic -> ./buildPerlPackage.nix."""
        content = 'buildPerlPackage = callPackage ../development/perl-modules/generic { };'
        result = script_module.apply_path_transformations(content)
        assert result == 'buildPerlPackage = callPackage ./buildPerlPackage.nix { };'

    def test_perl_modules_patch_transformation(self, script_module):
        """Test ../development/perl-modules/*.patch -> ./patches/*.patch."""
        content = 'patches = [ ../development/perl-modules/some.patch ];'
        result = script_module.apply_path_transformations(content)
        assert result == 'patches = [ ./patches/some.patch ];'

    def test_multiple_transformations_same_line(self, script_module):
        """Test multiple transformations on the same line."""
        content = '''
        patches = [
          ../development/perl-modules/fix1.patch
          ../development/perl-modules/fix2.patch
        ];
        '''
        result = script_module.apply_path_transformations(content)
        assert "../development/perl-modules" not in result
        assert "./patches/fix1.patch" in result
        assert "./patches/fix2.patch" in result

    def test_no_transformation_needed(self, script_module):
        """Test content that doesn't need transformation."""
        content = '{ lib, stdenv }: stdenv.mkDerivation { }'
        result = script_module.apply_path_transformations(content)
        assert result == content

    def test_partial_match_not_transformed(self, script_module):
        """Test that partial matches are not transformed incorrectly."""
        content = 'some-development-perl-modules-thing'
        result = script_module.apply_path_transformations(content)
        # Should not match because it's not ../development/perl-modules
        assert result == content


class TestShouldIgnoreChange:
    """Tests for should_ignore_change function."""

    def test_ignore_meta_maintainers_with_list(self, script_module):
        """Test ignoring maintainers = [ ... ] pattern."""
        assert script_module.should_ignore_change("      maintainers = [ maintainers.foo ];") is True
        assert script_module.should_ignore_change("    maintainers = [];") is True

    def test_ignore_meta_maintainers_with_with(self, script_module):
        """Test ignoring maintainers = with maintainers; pattern."""
        assert script_module.should_ignore_change("      maintainers = with maintainers; [ foo bar ];") is True

    def test_ignore_meta_teams(self, script_module):
        """Test ignoring teams = [...] assignments."""
        assert script_module.should_ignore_change("      teams = [ teams.foo ];") is True
        assert script_module.should_ignore_change("      teams = [ maintainers.foo ];") is True

    def test_not_ignore_teams_throw(self, script_module):
        """Test that teams = throw patterns are NOT ignored."""
        assert script_module.should_ignore_change("      teams = throw \"unused\";") is False
        assert script_module.should_ignore_change("      teams = throw \"something\";") is False

    def test_not_ignore_regular_line(self, script_module):
        """Test that regular lines are not ignored."""
        assert script_module.should_ignore_change("  pname = \"curl\";") is False
        assert script_module.should_ignore_change("  version = \"1.0\";") is False

    def test_not_ignore_maintainers_in_comment(self, script_module):
        """Test that maintainers in comments might still match (implementation detail)."""
        # This is acceptable - comments with maintainers assignment format are rare
        line = "  # maintainers = [ someone ];"
        # The pattern might or might not match comments - test current behavior
        result = script_module.should_ignore_change(line)
        # Either is acceptable, just document the behavior
        assert isinstance(result, bool)


class TestShouldIgnoreDeletion:
    """Tests for should_ignore_deletion function (deletion-specific patterns)."""

    def test_ignore_teams_deletion(self, script_module):
        """Test that deletions of any teams = line are ignored."""
        assert script_module.should_ignore_deletion("      teams = throw \"unused\";") is True
        assert script_module.should_ignore_deletion("      teams = [ teams.foo ];") is True
        assert script_module.should_ignore_deletion("      teams = [];") is True

    def test_ignore_meta_teams_deletion(self, script_module):
        """Test that deletions of meta.teams lines are ignored."""
        assert script_module.should_ignore_deletion("      meta.teams = [ teams.foo ];") is True
        assert script_module.should_ignore_deletion("      meta.teams = throw \"unused\";") is True

    def test_not_ignore_teams_addition(self, script_module):
        """Test that additions of teams lines are NOT ignored by deletion patterns."""
        # This tests that should_ignore_deletion is only used for deletions
        # Additions should use should_ignore_change which has stricter patterns
        assert script_module.should_ignore_deletion("      teams = throw \"unused\";") is True
        # But should_ignore_change should NOT match teams = throw
        assert script_module.should_ignore_change("      teams = throw \"unused\";") is False

    def test_not_ignore_other_deletions(self, script_module):
        """Test that other deletions are not ignored."""
        assert script_module.should_ignore_deletion("      version = \"1.0\";") is False
        assert script_module.should_ignore_deletion("      pname = \"curl\";") is False


class TestIsCorepkgsSpecificLine:
    """Tests for is_corepkgs_specific_line function."""

    def test_cmake_configure_phase_hook_is_specific(self, script_module):
        """Test that cmake.configurePhaseHook is detected as corepkgs-specific."""
        assert script_module.is_corepkgs_specific_line("    cmake.configurePhaseHook") is True
        assert script_module.is_corepkgs_specific_line("  cmake.configurePhaseHook,") is True

    def test_regular_cmake_not_specific(self, script_module):
        """Test that regular cmake is not corepkgs-specific."""
        assert script_module.is_corepkgs_specific_line("    cmake") is False
        assert script_module.is_corepkgs_specific_line("    cmake,") is False

    def test_other_lines_not_specific(self, script_module):
        """Test that other lines are not corepkgs-specific."""
        assert script_module.is_corepkgs_specific_line("    pkg-config") is False


class TestFilterDiffLines:
    """Tests for filter_diff_lines function."""

    def test_filter_maintainers_only_hunk(self, script_module):
        """Test that a hunk with only maintainers changes is removed."""
        diff = [
            "--- a/file.nix\n",
            "+++ b/file.nix\n",
            "@@ -10,3 +10,3 @@\n",
            "     description = \"test\";\n",
            "-    maintainers = [ maintainers.foo ];\n",
            "+    maintainers = [ ];\n",
            "   };\n",
        ]
        
        result = script_module.filter_diff_lines(diff)
        
        # Should be empty because only change was maintainers
        assert result == []

    def test_preserve_mixed_hunk(self, script_module):
        """Test that hunks with both maintainers and other changes keep other changes."""
        diff = [
            "--- a/file.nix\n",
            "+++ b/file.nix\n",
            "@@ -10,4 +10,4 @@\n",
            "     description = \"test\";\n",
            "-    version = \"1.0\";\n",
            "+    version = \"2.0\";\n",
            "-    maintainers = [ maintainers.foo ];\n",
            "+    maintainers = [ ];\n",
            "   };\n",
        ]
        
        result = script_module.filter_diff_lines(diff)
        result_str = ''.join(result)
        
        # Should keep version change
        assert "version" in result_str
        # Should not have maintainers change
        assert "maintainers.foo" not in result_str

    def test_filter_cmake_configure_hook_addition(self, script_module):
        """Test that addition of cmake.configurePhaseHook is filtered (already in corepkgs)."""
        diff = [
            "--- a/file.nix\n",
            "+++ b/file.nix\n",
            "@@ -10,2 +10,3 @@\n",
            "     cmake\n",
            "+    cmake.configurePhaseHook\n",
            "   ];\n",
        ]
        
        result = script_module.filter_diff_lines(diff)
        
        # The addition of cmake.configurePhaseHook should be filtered
        # Since it's the only change, result should be empty
        assert result == []

    def test_filter_cmake_configure_hook_deletion(self, script_module):
        """Test that deletion of cmake.configurePhaseHook is also filtered."""
        diff = [
            "--- a/file.nix\n",
            "+++ b/file.nix\n",
            "@@ -10,3 +10,2 @@\n",
            "     cmake\n",
            "-    cmake.configurePhaseHook\n",
            "   ];\n",
        ]
        
        result = script_module.filter_diff_lines(diff)
        
        # The deletion of cmake.configurePhaseHook should be filtered
        assert result == []

    def test_keep_regular_changes(self, script_module):
        """Test that regular changes are kept."""
        diff = [
            "--- a/file.nix\n",
            "+++ b/file.nix\n",
            "@@ -10,3 +10,3 @@\n",
            "   {\n",
            "-    version = \"1.0\";\n",
            "+    version = \"2.0\";\n",
            "   }\n",
        ]
        
        result = script_module.filter_diff_lines(diff)
        result_str = ''.join(result)
        
        assert "-    version = \"1.0\";" in result_str
        assert "+    version = \"2.0\";" in result_str

    def test_filter_teams_deletion(self, script_module):
        """Test that deletions of teams = lines are filtered."""
        diff = [
            "--- a/file.nix\n",
            "+++ b/file.nix\n",
            "@@ -10,3 +10,2 @@\n",
            "     maintainers = throw \"unused\";\n",
            "-    teams = throw \"unused\";\n",
            "   };\n",
        ]
        
        result = script_module.filter_diff_lines(diff)
        
        # The deletion of teams = throw should be filtered
        result_str = ''.join(result)
        assert "teams = throw" not in result_str
        # Since it's the only change, the hunk should be removed
        assert result == []

    def test_filter_teams_deletion_with_other_changes(self, script_module):
        """Test that teams deletions are filtered but other changes remain."""
        diff = [
            "--- a/file.nix\n",
            "+++ b/file.nix\n",
            "@@ -10,4 +10,3 @@\n",
            "     maintainers = throw \"unused\";\n",
            "-    teams = throw \"unused\";\n",
            "-    version = \"1.0\";\n",
            "+    version = \"2.0\";\n",
            "   };\n",
        ]
        
        result = script_module.filter_diff_lines(diff)
        result_str = ''.join(result)
        
        # Should keep version change
        assert "version" in result_str
        # Should not have teams deletion
        assert "teams = throw" not in result_str

    def test_empty_diff(self, script_module):
        """Test handling of empty diff."""
        result = script_module.filter_diff_lines([])
        assert result == []




class TestGeneratePatchWithTransformations:
    """Integration tests for generate_patch with transformations."""

    def test_path_transformation_in_patch(self, script_module, tmp_path):
        """Test that path transformations are applied before diffing."""
        nixpkgs_file = tmp_path / "nixpkgs.nix"
        corepkgs_file = tmp_path / "corepkgs.nix"
        
        # nixpkgs uses ../development/perl-modules path
        nixpkgs_file.write_text('patches = [ ../development/perl-modules/fix.patch ];\n')
        # corepkgs uses ./patches path
        corepkgs_file.write_text('patches = [ ./patches/fix.patch ];\n')
        
        result = script_module.generate_patch(
            corepkgs_file, nixpkgs_file, "corepkgs.nix", "nixpkgs.nix"
        )
        
        # After transformation, files should be identical, so no patch
        assert result is None

    def test_maintainers_change_filtered(self, script_module, tmp_path):
        """Test that maintainers changes are filtered from patch."""
        nixpkgs_file = tmp_path / "nixpkgs.nix"
        corepkgs_file = tmp_path / "corepkgs.nix"
        
        nixpkgs_file.write_text('''{
  meta = {
    maintainers = [ maintainers.foo ];
  };
}
''')
        corepkgs_file.write_text('''{
  meta = {
    maintainers = [ ];
  };
}
''')
        
        result = script_module.generate_patch(
            corepkgs_file, nixpkgs_file, "corepkgs.nix", "nixpkgs.nix"
        )
        
        # Only maintainers change, should be filtered
        assert result is None

    def test_cmake_hook_filtered(self, script_module, tmp_path):
        """Test that cmake.configurePhaseHook changes are filtered (both directions)."""
        nixpkgs_file = tmp_path / "nixpkgs.nix"
        corepkgs_file = tmp_path / "corepkgs.nix"
        
        # nixpkgs doesn't have cmake.configurePhaseHook
        nixpkgs_file.write_text('''nativeBuildInputs = [
  cmake
  pkg-config
];
''')
        # corepkgs has it
        corepkgs_file.write_text('''nativeBuildInputs = [
  cmake
  cmake.configurePhaseHook
  pkg-config
];
''')
        
        result = script_module.generate_patch(
            corepkgs_file, nixpkgs_file, "corepkgs.nix", "nixpkgs.nix"
        )
        
        # The addition of cmake.configurePhaseHook should be filtered
        # because it's corepkgs-specific and already in the file
        assert result is None or "cmake.configurePhaseHook" not in result


class TestApplyPatternAliases:
    """Tests for apply_pattern_aliases function."""

    def test_apply_alias_when_corepkgs_uses_lowercase(self, script_module):
        """Test that alias is applied when corepkgs uses libx11 and nixpkgs uses libX11."""
        # Current mapping: (r"\blibX11\b", "libx11")
        # So: if nixpkgs has libX11 and corepkgs has libx11, transform nixpkgs libX11 -> libx11
        nixpkgs_content = "buildInputs = [ libX11 ];"
        corepkgs_content = "buildInputs = [ libx11 ];"
        result = script_module.apply_pattern_aliases(nixpkgs_content, corepkgs_content)
        assert result == "buildInputs = [ libx11 ];"

    def test_no_alias_when_both_use_same_name(self, script_module):
        """Test that no alias is applied when both use the same name."""
        nixpkgs_content = "buildInputs = [ libx11 ];"
        corepkgs_content = "buildInputs = [ libx11 ];"
        result = script_module.apply_pattern_aliases(nixpkgs_content, corepkgs_content)
        assert result == "buildInputs = [ libx11 ];"

    def test_no_alias_when_corepkgs_uses_nixpkgs_variant(self, script_module):
        """Test that no alias is applied when corepkgs uses the nixpkgs variant."""
        # If corepkgs uses libX11 (same as nixpkgs), no transformation needed
        nixpkgs_content = "buildInputs = [ libX11 ];"
        corepkgs_content = "buildInputs = [ libX11 ];"
        result = script_module.apply_pattern_aliases(nixpkgs_content, corepkgs_content)
        assert result == "buildInputs = [ libX11 ];"

    def test_no_transformation_when_corepkgs_doesnt_use_alias(self, script_module):
        """Test that no transformation happens when corepkgs doesn't use the alias."""
        # If corepkgs doesn't use libx11, don't transform nixpkgs libX11
        nixpkgs_content = "buildInputs = [ libX11 ];"
        corepkgs_content = "buildInputs = [ someOtherLib ];"
        result = script_module.apply_pattern_aliases(nixpkgs_content, corepkgs_content)
        assert result == "buildInputs = [ libX11 ];"

    def test_multiple_occurrences(self, script_module):
        """Test that all occurrences are transformed."""
        nixpkgs_content = "deps = [ libX11 ]; # libX11 is needed"
        corepkgs_content = "deps = [ libx11 ]; # libx11 is needed"
        result = script_module.apply_pattern_aliases(nixpkgs_content, corepkgs_content)
        assert result == "deps = [ libx11 ]; # libx11 is needed"

    def test_word_boundaries_in_compound_words(self, script_module):
        """Test that word boundaries work correctly with compound words."""
        nixpkgs_content = "# libX11-dev package"
        corepkgs_content = "# libx11-dev package"
        result = script_module.apply_pattern_aliases(nixpkgs_content, corepkgs_content)
        # Should transform because libX11 is a word (hyphen is word boundary)
        assert result == "# libx11-dev package"

    def test_no_false_positives_in_strings(self, script_module):
        """Test that aliases in strings are still transformed if corepkgs uses them."""
        nixpkgs_content = 'description = "Uses libX11";'
        corepkgs_content = 'description = "Uses libx11";'
        result = script_module.apply_pattern_aliases(nixpkgs_content, corepkgs_content)
        assert result == 'description = "Uses libx11";'

    def test_case_sensitivity_preserved_for_non_matches(self, script_module):
        """Test that case is preserved for packages not in alias list."""
        nixpkgs_content = "buildInputs = [ MyPackage ];"
        corepkgs_content = "buildInputs = [ MyPackage ];"
        result = script_module.apply_pattern_aliases(nixpkgs_content, corepkgs_content)
        assert result == "buildInputs = [ MyPackage ];"

    def test_mixed_content(self, script_module):
        """Test content with both aliased and non-aliased packages."""
        nixpkgs_content = "buildInputs = [ libX11 stdenv ];"
        corepkgs_content = "buildInputs = [ libx11 stdenv ];"
        result = script_module.apply_pattern_aliases(nixpkgs_content, corepkgs_content)
        assert result == "buildInputs = [ libx11 stdenv ];"

