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
    "build-support/make-fonts-conf/make-fonts-conf.xsl": "pkgs/development/libraries/fontconfig/make-fonts-conf.xsl",
    "build-support/minimal-bootstrap": "pkgs/os-specific/linux/minimal-bootstrap",
    "build-support/minimal-bootstrap/grep": "pkgs/os-specific/linux/minimal-bootstrap/gnugrep",
    "build-support/minimal-bootstrap/m4": "pkgs/os-specific/linux/minimal-bootstrap/gnum4",
    "build-support/minimal-bootstrap/make": "pkgs/os-specific/linux/minimal-bootstrap/gnumake",
    "build-support/minimal-bootstrap/patch": "pkgs/os-specific/linux/minimal-bootstrap/gnupatch",
    "build-support/minimal-bootstrap/sed": "pkgs/os-specific/linux/minimal-bootstrap/gnused",
    "build-support/minimal-bootstrap/tar": "pkgs/os-specific/linux/minimal-bootstrap/gnutar",
    "build-support/setup-hooks/add-bin-to-path.sh": "pkgs/by-name/ad/addBinToPathHook/add-bin-to-path.sh",
    "build-support/setup-hooks/auto-patchelf.sh": "pkgs/by-name/au/autoPatchelfHook/auto-patchelf.sh",
    "build-support/setup-hooks/autoreconf.sh": "pkgs/by-name/au/autoreconfHook/autoreconf.sh",
    "build-support/setup-hooks/die.sh": "pkgs/by-name/di/dieHook/die.sh",
    "build-support/setup-hooks/fix-darwin-dylib-names.sh": "pkgs/by-name/fi/fixDarwinDylibNames/fix-darwin-dylib-names.sh",
    "build-support/setup-hooks/gog-unpack.sh": "pkgs/by-name/go/gogUnpackHook/gog-unpack.sh",
    "build-support/setup-hooks/set-java-classpath.sh": "pkgs/by-name/se/setJavaClassPath/set-java-classpath.sh",
    "build-support/setup-hooks/strip-java-archives.sh": "pkgs/by-name/st/stripJavaArchivesHook/strip-java-archives.sh",
    "common-updater": "pkgs/common-updater",
    "haskell": "pkgs/development/haskell-modules",
    "pkgs": "pkgs/by-name",
    "pkgs/OVMF": "pkgs/applications/virtualization/OVMF",
    "pkgs/R": "pkgs/by-name/r/R",
    "pkgs/acl": "pkgs/development/libraries/acl",
    "pkgs/arm-trusted-firmware": "pkgs/misc/arm-trusted-firmware",
    "pkgs/automake": "pkgs/development/tools/misc/automake",
    "pkgs/bash": "pkgs/shells/bash",
    "pkgs/binlore": "pkgs/development/tools/analysis/binlore",
    "pkgs/binutils": "pkgs/development/tools/misc/binutils",
    "pkgs/boost": "pkgs/development/libraries/boost",
    "pkgs/buildRubyGem": "pkgs/development/ruby-modules/gem",
    "pkgs/bundlerApp": "pkgs/development/ruby-modules",
    "pkgs/busybox": "pkgs/os-specific/linux/busybox",
    "pkgs/bzip2": "pkgs/tools/compression/bzip2",
    "pkgs/cargo-pgrx": "pkgs/development/tools/rust/cargo-pgrx",
    "pkgs/common-updater-scripts": "pkgs/common-updater",
    "pkgs/crystal": "pkgs/development/compilers/crystal",
    "pkgs/dbus": "pkgs/by-name/ma/makeDBusConf",
    "pkgs/defaultGemConfig": "pkgs/development/ruby-modules/gem-config",
    "pkgs/deno/fetchers.nix": "pkgs/by-name/sp/spacetimedb/fetchers.nix",
    "pkgs/docbook-xsl": "pkgs/data/sgml+xml/stylesheets/xslt/docbook-xsl",
    "pkgs/dotnet": "pkgs/development/compilers/dotnet",
    "pkgs/doxygen/doxmlparser.nix": "pkgs/development/python-modules/doxmlparser/default.nix",
    "pkgs/expect": "pkgs/development/tcl-modules/by-name/ex/expect_5",
    "pkgs/fetchDebianPatch": "pkgs/build-support/fetchdebianpatch",
    "pkgs/fetchYarnDeps": "pkgs/build-support/node/fetch-yarn-deps",
    "pkgs/fetchgit": "pkgs/build-support/fetchgit",
    "pkgs/fetchhg": "pkgs/build-support/fetchhg",
    "pkgs/fetchpatch": "pkgs/build-support/fetchpatch",
    "pkgs/fetchsvn": "pkgs/build-support/fetchsvn",
    "pkgs/fetchurl": "pkgs/build-support/fetchurl",
    "pkgs/fetchzip": "pkgs/build-support/fetchzip",
    "pkgs/file": "pkgs/tools/misc/file",
    "pkgs/findutils": "pkgs/tools/misc/findutils",
    "pkgs/fontconfig": "pkgs/development/libraries/fontconfig",
    "pkgs/formats": "pkgs/pkgs-lib",
    "pkgs/gawk": "pkgs/tools/text/gawk",
    "pkgs/gcc": "pkgs/development/compilers/gcc",
    "pkgs/gcc/patches/14/libsanitizer-fix-with-glibc-2.42.patch": "pkgs/development/compilers/gcc/patches/13/libsanitizer-fix-with-glibc-2.42.patch",
    "pkgs/gettext": "pkgs/development/libraries/gettext",
    "pkgs/glibc": "pkgs/development/libraries/glibc",
    "pkgs/gnome": "pkgs/desktops/gnome",
    "pkgs/gnupg": "pkgs/tools/security/gnupg",
    "pkgs/gobject-introspection": "pkgs/development/libraries/gobject-introspection",
    "pkgs/grep": "pkgs/by-name/gn/gnugrep",
    "pkgs/gtk": "pkgs/by-name/gt/gtk2",
    "pkgs/gtk/patches": "pkgs/by-name/gt/gtk3/patches",
    "pkgs/importNpmLock": "pkgs/build-support/node/import-npm-lock",
    "pkgs/iputils": "pkgs/os-specific/linux/iputils",
    "pkgs/javaPackages/openjdk": "pkgs/development/compilers/openjdk",
    "pkgs/julia": "pkgs/development/compilers/julia",
    "pkgs/kmod": "pkgs/os-specific/linux/kmod",
    "pkgs/kustomize": "pkgs/development/tools/kustomize",
    "pkgs/libbpf": "pkgs/os-specific/linux/libbpf",
    "pkgs/libidn2": "pkgs/development/libraries/libidn2",
    "pkgs/libinput": "pkgs/development/libraries/libinput",
    "pkgs/libliftoff": "pkgs/development/libraries/libliftoff",
    "pkgs/libunistring": "pkgs/development/libraries/libunistring",
    "pkgs/libva": "pkgs/development/libraries/libva",
    "pkgs/libxcrypt": "pkgs/development/libraries/libxcrypt",
    "pkgs/libxml2": "pkgs/development/libraries/libxml2",
    "pkgs/linux": "pkgs/os-specific/linux",
    "pkgs/linux-support": "pkgs/os-specific/linux",
    "pkgs/linux-support/pkgs": "pkgs/os-specific/linux",
    "pkgs/linux-support/pkgs/chipsec": "pkgs/by-name/ch/chipsec",
    "pkgs/linux-support/pkgs/drbd": "pkgs/by-name/dr/drbd",
    "pkgs/linux-support/pkgs/i7z": "pkgs/by-name/i7/i7z",
    "pkgs/linux-support/pkgs/sgx/sdk/cppmicroservices-no-mtime.patch": "pkgs/os-specific/linux/sgx/psw/cppmicroservices-no-mtime.patch",
    "pkgs/linux-support/pkgs/wpa_supplicant": "pkgs/by-name/wp/wpa_supplicant",
    "pkgs/linux/default.nix": "pkgs/top-level/linux-kernels.nix",
    "pkgs/linux/kernel/kernel-config.nix": "nixos/modules/system/boot/kernel_config.nix",
    "pkgs/linux/pkgs": "pkgs/os-specific/linux",
    "pkgs/llvm": "pkgs/development/compilers/llvm",
    "pkgs/lvm2": "pkgs/os-specific/linux/lvm2",
    "pkgs/m4": "pkgs/by-name/gn/gnum4",
    "pkgs/make": "pkgs/by-name/gn/gnumake",
    "pkgs/maturin": "pkgs/by-name/ma/maturin",
    "pkgs/mdadm/fix-hardcoded-mapdir.patch": "pkgs/by-name/md/mdadm4/fix-hardcoded-mapdir.patch",
    "pkgs/mesa": "pkgs/development/libraries/mesa",
    "pkgs/moreutils": "pkgs/tools/misc/moreutils",
    "pkgs/net-tools": "pkgs/os-specific/linux/net-tools",
    "pkgs/nettle": "pkgs/development/libraries/nettle",
    "pkgs/nftables": "pkgs/os-specific/linux/nftables",
    "pkgs/nginx": "pkgs/servers/http/nginx",
    "pkgs/ngtcp2": "pkgs/development/libraries/ngtcp2",
    "pkgs/nix": "pkgs/tools/package-management/nix",
    "pkgs/nix-prefetch-scripts": "pkgs/tools/package-management/nix-prefetch-scripts",
    "pkgs/openblas": "pkgs/development/libraries/science/math/openblas",
    "pkgs/openssh": "pkgs/tools/networking/openssh",
    "pkgs/patch": "pkgs/by-name/gn/gnupatch",
    "pkgs/patchelf/setup-hook.sh": "pkgs/development/tools/misc/patchelf/setup-hook.sh",
    "pkgs/patchutils": "pkgs/tools/text/patchutils",
    "pkgs/perl": "pkgs/development/interpreters/perl",
    "pkgs/pnpmFixupStateDb": "pkgs/by-name/pn/pnpm-fixup-state-db",
    "pkgs/poppler": "pkgs/development/libraries/poppler",
    "pkgs/postgresql": "pkgs/servers/sql/postgresql",
    "pkgs/prefetchNpmDeps": "pkgs/build-support/node/prefetch-npm-deps",
    "pkgs/procps-ng": "pkgs/os-specific/linux/procps-ng",
    "pkgs/readline": "pkgs/development/libraries/readline",
    "pkgs/rpm": "pkgs/tools/package-management/rpm",
    "pkgs/rust": "pkgs/development/compilers/rust",
    "pkgs/rust-bindgen/wrapper.sh": "pkgs/development/tools/rust/bindgen/wrapper.sh",
    "pkgs/rustup": "pkgs/development/tools/rust/rustup",
    "pkgs/rustup-toolchain-install-master": "pkgs/development/tools/rust/rustup-toolchain-install-master",
    "pkgs/sed": "pkgs/tools/text/gnused",
    "pkgs/silver-searcher/bash-completion.patch": "pkgs/by-name/si/silver-searcher-ng/bash-completion.patch",
    "pkgs/sqlite": "pkgs/development/libraries/sqlite",
    "pkgs/substitute": "pkgs/build-support/substitute",
    "pkgs/subversion": "pkgs/applications/version-management/subversion",
    "pkgs/system-sendmail": "pkgs/servers/mail/system-sendmail",
    "pkgs/systemd": "pkgs/os-specific/linux/systemd",
    "pkgs/tar": "pkgs/by-name/gn/gnutar",
    "pkgs/texlive": "pkgs/tools/typesetting/tex/texlive",
    "pkgs/tpm2-tss": "pkgs/development/libraries/tpm2-tss",
    "pkgs/treefmt/modules/default.nix": "pkgs/by-name/tr/treefmt/modules/default.nix",
    "pkgs/uboot": "pkgs/misc/uboot",
    "pkgs/vala": "pkgs/development/compilers/vala",
    "pkgs/xorg": "pkgs/servers/x11/xorg",
    "pkgs/zig": "pkgs/development/compilers/zig",
    "pkgs/zstd": "pkgs/tools/compression/zstd",
    "python": "pkgs/development/interpreters/python",
    "python/cpython/2.7": "pkgs/development/misc/resholve/cpython-2.7",
    "python/cpython/3.7/no-win64-workaround.patch": "pkgs/development/misc/resholve/cpython-2.7/no-win64-workaround.patch",
    "python/hooks/setuptools-rust-hook.sh": "pkgs/development/python-modules/setuptools-rust/setuptools-rust-hook.sh",
    "python/pkgs": "pkgs/development/python-modules",
    "python/pkgs/setuptools": "pkgs/development/misc/resholve/python2-modules/setuptools",
    "python/python2": "pkgs/development/misc/resholve/python2",
    "r": "pkgs/development/r-modules",
    "stdenv": "pkgs/stdenv",
    "stdenv/config.nix": "pkgs/top-level/config.nix",
    "stdenv/generic/meta-types.nix": "lib/meta-types.nix",
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
    "ekaos",
    "examples",
    "integration-tests",
    "patches",  # generated by this tool
    "perl",  # too many changes, update manually
    "pkgs-many",
    "pkgs/lndir",  # our minimal implementation
    "scripts",
    "services",
    "stdenv/cygwin",
    "stdenv/darwin",
    "stdenv/freebsd",
    "stdenv/linux/bootstrap-files",
    # keep-sorted end
]

# Suffixes never compared, wherever they appear. Prose diverges from nixpkgs
# freely and by design, so reviewing it as a patch is pure noise.
IGNORE_SUFFIXES = (".md",)

# Individual files never compared, matched as exact paths from the corepkgs root.
IGNORE_FILES = [
    # keep-sorted start
    ".gitignore",
    "LICENSE",
    "default.nix",
    "flake.lock",
    "flake.nix",
    "haskell/hackage-packages.nix",  # generated from Hackage; diffing it is noise
    "lib.nix",
    "pins.nix",
    "release.nix",
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
    # keep-sorted end
]
