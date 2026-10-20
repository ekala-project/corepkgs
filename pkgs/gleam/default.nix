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
  version = "1.19.2";

  src = fetchFromGitHub {
    owner = "gleam-lang";
    repo = "gleam";
    tag = "v${finalAttrs.version}";
    hash = "sha256-L7M1/nGDiB4D+yX1cjQ7mqNQ7YuC1BctLXEvnNjPz7A=";
  };

  cargoHash = "sha256-ZyxYe7O+XDcSuWGBACv3F8FNmdCfHwVUrwx34E1a5es=";

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
