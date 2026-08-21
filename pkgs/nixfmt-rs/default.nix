{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage rec {
  pname = "nixfmt-rs";
  version = "0.5.1";

  src = fetchFromGitHub {
    owner = "Mic92";
    repo = pname;
    rev = version;
    sha256 = "sha256-Gapz+ra0dyGHfY028QTbVVoGwu0yXaQOgKcarzX1nYo=";
  };

  cargoHash = "sha256-SN/IXbJpAW9kLVn7y4K4oI3DcTX8ekwWWJVTn+7oNhY=";

  doCheck = false;

  meta = with lib; {
    description = "A from-scratch Rust reimplementation of nixfmt that produces byte-identical output to the Haskell original.";
    homepage = "https://github.com/Mic92/nixfmt-rs";
    license = licenses.mpl20;
    mainProgram = "nixfmt";
  };
}
