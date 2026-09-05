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
  version = "2026-08-03";

  cargoHash = "sha256-QWxF5HvI1W/gVucVe09hEYx5BbX7SThI9FJ0KNnKmuI=";

  src = fetchFromGitHub {
    owner = "rust-lang";
    repo = "rust-analyzer";
    rev = finalAttrs.version;
    hash = "sha256-+HtsUgRhJR1pYz8lhKK4ChfBmZTjwcTmiq0mWBcvrfo=";
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

  doCheck = false;

  env.CFG_RELEASE = finalAttrs.version;

  meta = {
    description = "Language server for the Rust language";
    homepage = "https://rust-analyzer.github.io";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "rust-analyzer";
  };
})
