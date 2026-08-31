"""Declarative configuration for the nixpkgs sync.

Nothing here executes logic; every entry is data consumed by the other modules.
Keeping it separate means a reviewer can audit *what* is synced without reading
*how* it is synced.
"""

# Where generated patches are written, relative to the corepkgs root.
PATCHES_DIR = "patches"

# Where accepted divergence is recorded, relative to the corepkgs root. Both
# directories are gitignored: they are a local review aid, not repo content.
ACCEPTED_DIR = ".sync-accepted"

# Reports live under the patches directory, prefixed so they never collide with
# a generated patch path.
REPORTS_DIR = "_reports"

# Files whose contents are never diffed. A patch inside a patch is unreadable
# and cannot be applied, so these are reported as a one-line note instead.
OPAQUE_SUFFIXES = (".patch", ".diff")

# corepkgs path prefix -> nixpkgs path prefix. Longest prefix wins.
PATH_MAPPINGS = {
    # keep-sorted start
    "build-support": "pkgs/build-support",
    "build-support/minimal-bootstrap": "pkgs/os-specific/linux/minimal-bootstrap",
    "build-support/minimal-bootstrap/grep": "pkgs/os-specific/linux/minimal-bootstrap/gnugrep",
    "build-support/minimal-bootstrap/m4": "pkgs/os-specific/linux/minimal-bootstrap/gnum4",
    "build-support/minimal-bootstrap/make": "pkgs/os-specific/linux/minimal-bootstrap/gnumake",
    "build-support/minimal-bootstrap/patch": "pkgs/os-specific/linux/minimal-bootstrap/gnupatch",
    "build-support/minimal-bootstrap/sed": "pkgs/os-specific/linux/minimal-bootstrap/gnused",
    "build-support/minimal-bootstrap/tar": "pkgs/os-specific/linux/minimal-bootstrap/gnutar",
    "common-updater": "pkgs/common-updater",
    "pkgs": "pkgs/by-name",
    "pkgs/automake": "pkgs/development/tools/misc/automake",
    "pkgs/bash": "pkgs/shells/bash",
    "pkgs/binutils": "pkgs/development/tools/misc/binutils",
    "pkgs/boost": "pkgs/development/libraries/boost",
    "pkgs/dotnet": "pkgs/development/compilers/dotnet",
    "pkgs/gcc": "pkgs/development/compilers/gcc",
    "pkgs/glibc": "pkgs/development/libraries/glibc",
    "pkgs/gobject-introspection": "pkgs/development/libraries/gobject-introspection",
    "pkgs/javaPackages/openjdk": "pkgs/development/compilers/openjdk",
    "pkgs/linux": "pkgs/os-specific/linux",
    "pkgs/linux/default.nix": "pkgs/top-level/linux-kernels.nix",
    "pkgs/linux/kernel/kernel-config.nix": "nixos/modules/system/boot/kernel_config.nix",
    "pkgs/linux/pkgs": "pkgs/os-specific/linux",
    "pkgs/llvm": "pkgs/development/compilers/llvm",
    "pkgs/m4": "pkgs/by-name/gn/gnum4",
    "pkgs/make": "pkgs/by-name/gn/gnumake",
    "pkgs/nix": "pkgs/tools/package-management/nix",
    "pkgs/openssh": "pkgs/tools/networking/openssh",
    "pkgs/perl": "pkgs/development/interpreters/perl",
    "pkgs/rust": "pkgs/development/compilers/rust",
    "pkgs/sed": "pkgs/tools/text/gnused",
    "pkgs/systemd": "pkgs/os-specific/linux/systemd",
    "pkgs/texlive": "pkgs/tools/typesetting/tex/texlive",
    "pkgs/xorg": "pkgs/servers/x11/xorg",
    "python": "pkgs/development/interpreters/python",
    "python/pkgs": "pkgs/development/python-modules",
    "release.nix": "pkgs/top-level/release.nix",
    "stdenv": "pkgs/stdenv",
    "stdenv/config.nix": "pkgs/top-level/config.nix",
    "stdenv/impure.nix": "pkgs/top-level/impure.nix",
    "stdenv/pure.nix": "pkgs/top-level/default.nix",
    "stdenv/release/lib.nix": "pkgs/top-level/release-lib.nix",
    "stdenv/splice.nix": "pkgs/top-level/splice.nix",
    "stdenv/stage.nix": "pkgs/top-level/stage.nix",
    "stdenv/variants.nix": "pkgs/top-level/variants.nix",
    "systems": "lib/systems",
    "unixtools.nix": "pkgs/top-level/unixtools.nix",
    # keep-sorted end
}

# The nixpkgs prefix that uses the by-name layout (two-letter shard directory
# and `package.nix` rather than `default.nix`).
BY_NAME_PREFIX = "pkgs/by-name"

# Relative-path rewrites applied to nixpkgs content. nixpkgs refers to files by
# their location in its own tree; these express the same reference in corepkgs
# terms. Applied in order, so the specific entries must precede the general one.
PATH_REWRITES = [
    (r"\.\./development/perl-modules/generic", "./buildPerlPackage.nix"),
    (r"\.\./development/perl-modules/([^/]+\.patch)", r"./patches/\1"),
    (r"\.\./development/perl-modules", "./patches"),
    (r"\.\./os-specific/linux/", "./"),
]

# Alias files read at run time to build the rewrite vocabulary. corepkgs already
# records how it spells upstream names; deriving from these means the sync tool
# cannot drift from the aliases the package set actually defines.
ALIAS_FILES = (
    "stdenv/aliases.nix",
    "python/aliases.nix",
)

# Aliases deliberately not used as rewrites. Most of `aliases.nix` mirrors
# nixpkgs' own aliases, so both trees already write the same name and rewriting
# would invent a diff rather than remove one. Measured against every paired
# file: each of these did more harm than good.
ALIAS_EXCLUSIONS = {
    # keep-sorted start
    "SDL",  # nixpkgs aliases it too, so both trees already write SDL
    "SDL2",  # nixpkgs aliases it too
    "clj",  # nixpkgs aliases it too
    "man",  # too generic: matches `bintools ? man` and `man unshare` in prose
    "ncurses5",  # nixpkgs aliases it too
    "r",  # too generic: matches `jq -r` and `-r | --relocatable`
    "su",  # nixpkgs aliases it too
    "xxHash",  # nixpkgs aliases it too
    # keep-sorted end
}

# Renames that are not package aliases, so no `aliases.nix` entry can express
# them. Applied after the alias-derived rewrites.
EXTRA_VOCABULARY = [
    # keep-sorted start
    (r"\bdocbook_xsl\b", "docbook-xsl-nons"),
    (r"\bdocbook_xsl_ns\b", "docbook-xsl-ns"),
    (r"\bgnumakeBoot\b", "makeBoot"),
    (r"\bgnutarBoot\b", "tarBoot"),
    (r"\blibX11\b", "libx11"),
    (r"\bnixpkgsArgs\b", "pkgsArgs"),
    # keep-sorted end
]

# `meta` bindings dropped from incoming nixpkgs content. corepkgs is curated as
# a set and does not carry these, so importing them would be noise in every
# single patch.
DROPPED_META_BINDINGS = (
    "maintainers",
    "nonTeamMaintainers",
    "teams",
)

# Directories never compared, relative to the corepkgs root.
IGNORE_DIRS = [
    # keep-sorted start
    ".github",
    "ci",  # corepkgs' own evaluation jobs
    "dev-shell",  # corepkgs-only
    "docs",
    "patches",  # generated by this tool
    "perl",  # too many changes, update manually
    "pkgs-many",
    "pkgs/lndir",  # our minimal implementation
    "scripts",
    "stdenv/cygwin",
    "stdenv/darwin",
    "stdenv/freebsd",
    "stdenv/linux/bootstrap-files",
    # keep-sorted end
]

# Individual files never compared, matched as exact paths from the corepkgs root.
IGNORE_FILES = [
    # keep-sorted start
    ".gitignore",
    "AGENTS.md",
    "CLAUDE.md",
    "LICENSE",
    "README.md",
    "default.nix",
    "flake.lock",
    "flake.nix",
    "lib.nix",
    "pins.nix",
    "stdenv/README.md",
    "stdenv/aliases.nix",  # we have our own aliases
    "top-level.nix",
    # keep-sorted end
]

# Under these prefixes every file in a subdirectory is collected into a single
# patch named after that subdirectory, so one package reviews as one patch.
GROUPED_DIRS = [
    # keep-sorted start
    "build-support",
    "common-updater",
    "os-specific/linux",
    "pkgs",
    "systems",
    # keep-sorted end
]
