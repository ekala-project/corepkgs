{
  lib,
  rustPlatform,
  fetchFromGitHub,
  testers,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "aardvark-dns";
  version = "1.17.1";

  src = fetchFromGitHub {
    owner = "containers";
    repo = "aardvark-dns";
    tag = "v${finalAttrs.version}";
    hash = "sha256-gd04T+GK/+gCWGMnNfFzCcTBPbjU8e5mWjFf7uvob38=";
  };

  cargoHash = "sha256-19EisvHJZJ1L3f0+pE6wgfChkRoYU8W/iaAppwbjbdQ=";

  passthru.tests = {
    version = testers.testVersion {
      package = finalAttrs.finalPackage;
      command = "aardvark-dns --version";
    };
  };

  meta = {
    changelog = "https://github.com/containers/aardvark-dns/releases/tag/${finalAttrs.src.rev}";
    description = "Authoritative dns server for A/AAAA container records";
    homepage = "https://github.com/containers/aardvark-dns";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    mainProgram = "aardvark-dns";
    maintainers = [ ];
  };
})
