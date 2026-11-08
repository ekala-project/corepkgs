{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "iets";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "numtide";
    repo = "iets";
    tag = "v${finalAttrs.version}";
    hash = "sha256-/dBb7a1vxJwOwxywVNQo3buw8L3PtbNZtOH0aJTGNS4=";
    # fixture .drv files contain nix store paths that break CA derivation resolution
    postFetch = ''
      rm -rf $out/tests/fixtures/drv
    '';
  };

  cargoHash = "sha256-PsMAY7NsHb/OBWWOd6shMJsBLaWtcCwOlWaSzar8pP8=";

  meta = {
    description = "Fast Nix evaluator and remote-build client in Rust";
    homepage = "https://github.com/numtide/iets";
    license = lib.licenses.lgpl21Only;
    mainProgram = "iets";
    platforms = lib.platforms.linux;
  };
})
