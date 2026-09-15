# jq — mkEkaPackage variant using the nushell builder
#
# This is a translation of default.nix from stdenv.mkDerivation (bash)
# to mkEkaPackage (nushell). Phase strings use nushell syntax.
{
  mkEkaPackage,
  fetchurl,
  lib,
  onigurumaSupport ? true,
}:

mkEkaPackage (finalAttrs: {
  pname = "jq";
  version = "1.8.2";

  # Note: do not use fetchpatch or fetchFromGitHub to keep this package available in __bootPackages
  src = fetchurl {
    url = "https://github.com/jqlang/jq/releases/download/jq-${finalAttrs.version}/jq-${finalAttrs.version}.tar.gz";
    hash = "sha256-cbjW6PX+gfbG0NEQ44kiUfbOdu0JWr0xXibm4Rk6868=";
  };

  outputs = [
    "bin"
    "doc"
    "man"
    "dev"
    "out"
  ];

  commands = scope: {
    inherit (scope) removeReferencesTo bison;
    autoreconfHook = scope.autoreconfHook;
  };

  libraries =
    scope:
    {
    }
    // lib.optionalAttrs onigurumaSupport {
      inherit (scope) oniguruma;
    };

  configureFlags = [
    "--bindir=\${bin}/bin"
    "--sbindir=\${bin}/bin"
    "--datadir=\${doc}/share"
    "--mandir=\${man}/share/man"
  ]
  ++ lib.optional (!onigurumaSupport) "--with-oniguruma=no";

  # Upstream script that writes the version that's eventually compiled
  # and printed in `jq --help` relies on a .git directory which our src
  # doesn't keep.
  preConfigure = ''
    "#!/bin/sh" | save scripts/version
    $"echo ($env.__attrs.version)" | save --append scripts/version
    ^chmod +x scripts/version
  '';

  # paranoid mode: make sure we never use vendored version of oniguruma
  # Note: it must be run after automake, or automake will complain
  preBuild = ''
    rm -rf ./vendor/oniguruma
  '';

  # jq binary includes the whole `configureFlags` in:
  # https://github.com/jqlang/jq/commit/583e4a27188a2db097dd043dd203b9c106bba100
  # Strip unnecessary dependencies here to reduce closure size and break the
  # dependency cycle: $dev also refers to $bin via propagated-build-outputs
  postFixup = ''
    ^remove-references-to -t $env.dev -t $env.man -t $env.doc $"($env.bin)/bin/jq"
  '';

  meta = {
    description = "Lightweight and flexible command-line JSON processor";
    homepage = "https://jqlang.github.io/jq/";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "jq";
  };
})
