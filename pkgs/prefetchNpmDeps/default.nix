# prefetch-npm-deps: CLI tool for computing the npm dependency hash used by
# `fetchNpmDeps`. The Rust sources are vendored here, as they are in nixpkgs.
{
  lib,
  rustPlatform,
  makeWrapper,
  pkg-config,
  curl,
  gnutar,
  gzip,
}:

rustPlatform.buildRustPackage {
  pname = "prefetch-npm-deps";
  version = (lib.importTOML ./Cargo.toml).package.version;

  src = lib.cleanSourceWith {
    src = ./.;
    filter =
      name: _type:
      let
        base = baseNameOf name;
      in
      base != "default.nix" && base != "target";
  };

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [
    makeWrapper
    pkg-config
  ];

  buildInputs = [ curl ];

  postInstall = ''
    wrapProgram "$out/bin/prefetch-npm-deps" --prefix PATH : ${
      lib.makeBinPath [
        gnutar
        gzip
      ]
    }
  '';

  meta = {
    description = "Prefetch dependencies from npm (for use with `fetchNpmDeps`)";
    mainProgram = "prefetch-npm-deps";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
