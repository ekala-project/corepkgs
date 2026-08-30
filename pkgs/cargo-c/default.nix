{
  lib,
  rustPlatform,
  fetchurl,
  pkg-config,
  curl,
  openssl,
  stdenv,
  libiconv,
}:

let
  # this version may need to be updated along with package version
  cargoVersion = "0.94.0";
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "cargo-c";
  version = "0.10.20";

  src = fetchurl {
    name = "cargo-c-${finalAttrs.version}.tar.gz";
    url = "https://static.crates.io/crates/cargo-c/cargo-c-${finalAttrs.version}+cargo-${cargoVersion}.crate";
    hash = "sha256-XpU6fqIUNdo6WExh/LdlCpp6KQpaiNO7BaWxSTtKIWA=";
  };

  sourceRoot = "cargo-c-${finalAttrs.version}+cargo-${cargoVersion}";

  cargoHash = "sha256-fthbfBl4zReX72RzHcJtV2F46C4xP4J4YHd4qXY1oDs=";

  nativeBuildInputs = [
    pkg-config
    (lib.getDev curl)
  ];

  buildInputs = [
    openssl
    curl
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    libiconv
  ];

  # Ensure that we are avoiding build of the curl vendored in curl-sys
  doInstallCheck = stdenv.hostPlatform.libc == "glibc";
  installCheckPhase = ''
    runHook preInstallCheck

    ldd "$out/bin/cargo-cbuild" | grep libcurl.so

    runHook postInstallCheck
  '';

  meta = {
    description = "Cargo subcommand to build and install C-ABI compatible dynamic and static libraries";
    homepage = "https://github.com/lu-zero/cargo-c";
    changelog = "https://github.com/lu-zero/cargo-c/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
  };
})
