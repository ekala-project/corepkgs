from syncnix import normalize


class TestDropMetaBindings:
    def test_drops_single_line_binding(self):
        text = "meta = {\n  maintainers = [ lib.maintainers.foo ];\n  license = mit;\n};\n"
        assert normalize.drop_meta_bindings(text) == "meta = {\n  license = mit;\n};\n"

    def test_drops_multi_line_list(self):
        text = (
            "meta = {\n"
            "  maintainers = with lib.maintainers; [\n"
            "    foo\n"
            "    bar\n"
            "  ];\n"
            "  license = mit;\n"
            "};\n"
        )
        assert normalize.drop_meta_bindings(text) == "meta = {\n  license = mit;\n};\n"

    def test_drops_teams_and_non_team_maintainers(self):
        text = (
            "  teams = [ lib.teams.gnome ];\n"
            "  nonTeamMaintainers = [ lib.maintainers.foo ];\n"
            "  license = mit;\n"
        )
        assert normalize.drop_meta_bindings(text) == "  license = mit;\n"

    def test_drops_dotted_form(self):
        text = "meta.maintainers = [ lib.maintainers.foo ];\nmeta.license = mit;\n"
        assert normalize.drop_meta_bindings(text) == "meta.license = mit;\n"

    def test_leaves_similar_names_alone(self):
        text = "  maintainersPosition = null;\n"
        assert normalize.drop_meta_bindings(text) == text

    def test_leaves_unrelated_content_untouched(self):
        text = "{ lib }:\n{\n  pname = \"curl\";\n}\n"
        assert normalize.drop_meta_bindings(text) == text


class TestRewritePaths:
    def test_rewrites_os_specific_linux(self):
        assert normalize.rewrite_paths("../os-specific/linux/foo.nix") == "./foo.nix"

    def test_specific_perl_rule_precedes_general(self):
        assert (
            normalize.rewrite_paths("../development/perl-modules/generic")
            == "./buildPerlPackage.nix"
        )

    def test_perl_patch_files_land_in_patches(self):
        assert (
            normalize.rewrite_paths("../development/perl-modules/fix.patch")
            == "./patches/fix.patch"
        )


class TestRenameVocabulary:
    def test_renames_whole_words_only(self):
        assert normalize.rename_vocabulary("libX11") == "libx11"
        assert normalize.rename_vocabulary("libX11Extra") == "libX11Extra"

    def test_rename_is_unconditional(self):
        # The old implementation only renamed when the target file already used
        # the corepkgs spelling, which made output depend on unrelated content.
        assert normalize.rename_vocabulary("cmakeMinimal") == "cmake.minimal"


class TestUpstream:
    def test_applies_every_stage(self):
        text = "  maintainers = [ x ];\n  src = ../os-specific/linux/f.nix;\n  d = libX11;\n"
        assert normalize.upstream(text) == "  src = ./f.nix;\n  d = libx11;\n"
