# rust-analyzer — Language server for Rust (unwrapped)
{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  cmake,
  libiconv,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "rust-analyzer-unwrapped";
  version = "2026-11-23";

  cargoHash = "sha256-cHPXHEzpv7/2FvXBpqGeOU2KGVrDLJl/Jp1TO/dgcKw=";

  src = fetchFromGitHub {
    owner = "rust-lang";
    repo = "rust-analyzer";
    tag = finalAttrs.version;
    hash = "sha256-hZfnhkmliBbx1rw19SpSMNXJ+BxdhAeYy2L3/Iz33q4=";
  };

  cargoBuildFlags = [
    "--bin"
    "rust-analyzer"
    "--bin"
    "rust-analyzer-proc-macro-srv"
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [
    libiconv
  ];

  # Tests require rustfmt +stable toolchain and real Rust sysroot
  dontCargoCheck = true;

  env.CFG_RELEASE = finalAttrs.version;

  meta = {
    description = "Language server for the Rust language";
    homepage = "https://rust-analyzer.github.io";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "rust-analyzer";
    platforms = lib.platforms.all;
  };
})
