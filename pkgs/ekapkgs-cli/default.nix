{
  lib,
  rustPlatform,
  fetchFromGitHub,
  protobuf,
  pkg-config,
  makeWrapper,
  fuse3,
  sqlite,
  zstd,
  nix,
  iets,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ekapkgs-cli";
  version = "0.1.0-unstable-2026-11-14";

  src = fetchFromGitHub {
    owner = "ekala-project";
    repo = "ekapkgs-cli";
    rev = "af843b471a4f9f75418cc907b178484eb51bc2a0";
    hash = "sha256-vLus5QJi2NRQBXwNcrkkFeDGql0VxgK2dIVGhhO9SEE=";
  };

  cargoHash = "sha256-2F4KF6hxgSOCj4nuJxPfKjbshfPEqyVDRSp55/viaRc=";

  cargoBuildFlags = [
    "-p"
    "ekapkgs"
    "-p"
    "ekapkgs-serve"
  ];
  cargoTestFlags = finalAttrs.cargoBuildFlags;

  nativeBuildInputs = [
    protobuf
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    fuse3
    sqlite
    zstd
  ];

  env = {
    LIBSQLITE3_SYS_USE_PKG_CONFIG = "1";
    ZSTD_SYS_USE_PKG_CONFIG = "1";
  };

  # Both binaries shell out to `nix`; the client also prefers `iets`, which
  # evaluates the commands it implements and hands the rest to the `nix`
  # next to it on PATH.
  postFixup = ''
    wrapProgram $out/bin/ekapkgs \
      --prefix PATH : ${
        lib.makeBinPath [
          nix
          iets
        ]
      }
    wrapProgram $out/bin/ekapkgs-serve \
      --prefix PATH : ${lib.makeBinPath [ nix ]}
  '';

  meta = {
    description = "Nix CLI wrapper and binary cache server with a negotiated binary cache protocol";
    homepage = "https://github.com/ekala-project/ekapkgs-cli";
    license = lib.licenses.mpl20;
    platforms = lib.platforms.linux;
    mainProgram = "ekapkgs";
  };
})
