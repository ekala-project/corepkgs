from syncnix import paths


class TestResolve:
    def test_longest_prefix_wins(self):
        # "pkgs/gcc" must beat the generic "pkgs" -> by-name mapping.
        assert paths.resolve("pkgs/gcc/default.nix") == (
            "pkgs/development/compilers/gcc/default.nix"
        )

    def test_by_name_shards_and_renames_entry_point(self):
        assert paths.resolve("pkgs/curl/default.nix") == "pkgs/by-name/cu/curl/package.nix"

    def test_by_name_keeps_non_entry_files(self):
        assert paths.resolve("pkgs/curl/fix.patch") == "pkgs/by-name/cu/curl/fix.patch"

    def test_by_name_bare_package_implies_entry_point(self):
        assert paths.resolve("pkgs/curl") == "pkgs/by-name/cu/curl/package.nix"

    def test_by_name_shard_is_lowercased(self):
        assert paths.resolve("pkgs/ZopfliPng/default.nix").startswith("pkgs/by-name/zo/")

    def test_single_character_package_has_no_shard(self):
        assert paths.resolve("pkgs/z/default.nix") is None

    def test_exact_file_mapping(self):
        assert paths.resolve("stdenv/pure.nix") == "pkgs/top-level/default.nix"

    def test_directory_mapping_passes_remainder_through(self):
        assert paths.resolve("stdenv/generic/setup.sh") == "pkgs/stdenv/generic/setup.sh"

    def test_unmapped_path_returns_none(self):
        assert paths.resolve("ekaos/modules/thing.nix") is None


class TestIgnore:
    def test_ignores_exact_file(self):
        assert paths.is_ignored("top-level.nix")

    def test_does_not_ignore_same_name_deeper(self):
        assert not paths.is_ignored("pkgs/curl/default.nix")

    def test_ignores_directory_and_contents(self):
        assert paths.is_ignored("scripts")
        assert paths.is_ignored("scripts/sync-with-nixpkgs/sync.py")

    def test_prefix_match_requires_separator(self):
        # "config" is ignored; "configuration.nix" must not be.
        assert not paths.is_ignored("configuration.nix")


class TestOpaque:
    def test_patch_and_diff_are_opaque(self):
        assert paths.is_opaque("pkgs/curl/fix.patch")
        assert paths.is_opaque("pkgs/curl/fix.diff")

    def test_nix_is_not_opaque(self):
        assert not paths.is_opaque("pkgs/curl/default.nix")


class TestPatchTarget:
    def test_grouped_directory_collapses_to_subdirectory(self):
        assert paths.patch_target("pkgs/curl/default.nix") == "pkgs/curl.patch"
        assert paths.patch_target("pkgs/curl/fix.patch") == "pkgs/curl.patch"

    def test_grouped_directory_groups_nested_files_together(self):
        assert paths.patch_target("build-support/fetchgit/builder.sh") == (
            "build-support/fetchgit.patch"
        )

    def test_ungrouped_path_mirrors_itself(self):
        assert paths.patch_target("stdenv/generic/setup.sh") == "stdenv/generic/setup.sh.patch"
