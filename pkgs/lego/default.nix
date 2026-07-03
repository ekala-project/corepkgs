{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "lego";
  version = "4.21.0";

  src = fetchFromGitHub {
    owner = "go-acme";
    repo = "lego";
    rev = "v${finalAttrs.version}";
    hash = "sha256-3dSvQfkBNh8Bt10nv4xGplv4iY3gWvDu2EDN6UovSdc=";
  };

  vendorHash = "sha256-teA6fnKl4ATePOYL/zuemyiVy9jgsxikqmuQJwwA8wE=";

  doCheck = false;

  subPackages = [ "cmd/lego" ];

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
