{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "lego";
  version = "5.3.1";

  src = fetchFromGitHub {
    owner = "go-acme";
    repo = "lego";
    rev = "v${finalAttrs.version}";
    hash = "sha256-iKghMv6Rd4IKhG8kgm6BoY9RU2wP+tzvAazuGPDbWAI=";
  };

  vendorHash = "sha256-8zc7h8b0odW4Sg0/F1Njyz43q5EiX6EaoUNWaTQatfQ=";

  doCheck = false;

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
    maintainers = [ ];
  };
})
