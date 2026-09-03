# gleam — Statically typed language for the Erlang VM
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  erlang,
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

  doCheck = false;

  meta = {
    description = "Statically typed language for the Erlang VM";
    homepage = "https://gleam.run/";
    license = lib.licenses.asl20;
    mainProgram = "gleam";
  };
})
