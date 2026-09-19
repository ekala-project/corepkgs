# gleam — Statically typed language for the Erlang VM
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  erlang,
  git,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "gleam";
  version = "1.18.1";

  src = fetchFromGitHub {
    owner = "gleam-lang";
    repo = "gleam";
    tag = "v${finalAttrs.version}";
    hash = "sha256-974B+22Lvd7KB9M0yuuxkolLtRmg42NrAX5CIrIc3Ac=";
  };

  cargoHash = "sha256-as+2oyOpGA71oPDGTuZhfPccr8AjsUZJFtnRLYRxFOI=";

  nativeBuildInputs = [
    pkg-config
    erlang
  ];

  nativeCheckInputs = [ git ];

  checkFlags = [
    # scans build directory and chokes on .d files from cargo
    "--skip=tests::all_files_have_copyright_notice"
    # requires erlang escriptize which needs network/deps
    "--skip=tests::escript_success_with_dependency"
    # echo tests require bun (JavaScript runtime)
    "--skip=tests::echo::"
  ];

  meta = {
    description = "Statically typed language for the Erlang VM";
    homepage = "https://gleam.run/";
    license = lib.licenses.asl20;
    mainProgram = "gleam";
  };
})
