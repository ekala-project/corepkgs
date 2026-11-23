{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "lego";
  version = "5.7.0";

  src = fetchFromGitHub {
    owner = "go-acme";
    repo = "lego";
    tag = "v${finalAttrs.version}";
    hash = "sha256-zCZmP7Rx2wgwy/VyZ3hNLSxc8iRtijJJ+UasiNIo/HY=";
  };

  vendorHash = "sha256-ffaPAl01gDA9MbxyD9SJXb5O07R4iEsY6aZUWEDQKGs=";

  subPackages = [ "." ];

  ldflags = [
    "-s"
    "-w"
    "-X main.version=${finalAttrs.version}"
  ];

  meta = {
    description = "Let's Encrypt client and ACME library written in Go";
    homepage = "https://go-acme.github.io/lego/";
    license = lib.licenses.mit;
    mainProgram = "lego";
    platforms = lib.platforms.all;
  };
})
