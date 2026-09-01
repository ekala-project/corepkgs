import pytest

from syncnix import paths


@pytest.mark.parametrize(
    "path,expected",
    [
        # "pkgs/gcc" must beat the generic "pkgs" -> by-name mapping.
        ("pkgs/gcc/default.nix", "pkgs/development/compilers/gcc/default.nix"),
        ("pkgs/curl/default.nix", "pkgs/by-name/cu/curl/package.nix"),
        ("pkgs/curl/fix.patch", "pkgs/by-name/cu/curl/fix.patch"),
        ("pkgs/curl", "pkgs/by-name/cu/curl/package.nix"),
        # corepkgs renamed these, so the mapping names the upstream shard
        # directly; the default.nix -> package.nix rename must still apply.
        ("pkgs/m4/default.nix", "pkgs/by-name/gn/gnum4/package.nix"),
        ("pkgs/make/default.nix", "pkgs/by-name/gn/gnumake/package.nix"),
        ("pkgs/sed/default.nix", "pkgs/tools/text/gnused/default.nix"),
        ("stdenv/pure.nix", "pkgs/top-level/default.nix"),
        ("stdenv/generic/setup.sh", "pkgs/stdenv/generic/setup.sh"),
        # A one-character name has no shard, and nothing maps ekaos.
        ("pkgs/z/default.nix", None),
        ("unclaimed/thing.nix", None),
    ],
)
def test_resolve(path, expected):
    assert paths.resolve(path) == expected


def test_by_name_shard_is_lowercased():
    assert paths.resolve("pkgs/ZopfliPng/default.nix").startswith("pkgs/by-name/zo/")


@pytest.mark.parametrize(
    "path,ignored",
    [
        ("top-level.nix", True),
        ("scripts", True),
        ("scripts/sync-with-nixpkgs/sync.py", True),
        ("README.md", True),
        ("build-support/go/README.md", True),
        ("pkgs/texlive/UPGRADING.md", True),
        # A file sharing an ignored file's name deeper in the tree is not it.
        ("pkgs/curl/default.nix", False),
        ("pkgs/foo/README.md.nix", False),
        ("pkgs/md/default.nix", False),
        # "config" is ignored; a prefix match must still need a separator.
        ("configuration.nix", False),
    ],
)
def test_is_ignored(path, ignored):
    assert paths.is_ignored(path) is ignored


@pytest.mark.parametrize(
    "path,opaque",
    [("pkgs/curl/fix.patch", True), ("pkgs/curl/fix.diff", True), ("pkgs/curl/default.nix", False)],
)
def test_is_opaque(path, opaque):
    assert paths.is_opaque(path) is opaque


@pytest.mark.parametrize(
    "path,target",
    [
        # Everything under a grouped directory shares one patch per package.
        ("pkgs/curl/default.nix", "pkgs/curl.patch"),
        ("pkgs/curl/fix.patch", "pkgs/curl.patch"),
        ("build-support/fetchgit/builder.sh", "build-support/fetchgit.patch"),
        ("stdenv/generic/setup.sh", "stdenv/generic/setup.sh.patch"),
    ],
)
def test_patch_target(path, target):
    assert paths.patch_target(path) == target


@pytest.mark.parametrize(
    "declared,path,expected",
    [
        (["pkgs/foo/only.nix"], "pkgs/foo/only.nix", True),
        (["pkgs/foo/only.nix"], "pkgs/foo/other.nix", False),
        (["pkgs/foo"], "pkgs/foo", True),
        (["pkgs/foo"], "pkgs/foo/deep/thing.nix", True),
        # A prefix match must still need a separator.
        (["pkgs/foo"], "pkgs/foobar/default.nix", False),
    ],
)
def test_is_local_only(monkeypatch, declared, path, expected):
    monkeypatch.setattr(paths.config, "LOCAL_ONLY", declared)
    assert paths.is_local_only(path) is expected
