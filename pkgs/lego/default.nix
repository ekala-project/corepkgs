{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "lego";
  version = "5.5.2";

  src = fetchFromGitHub {
    owner = "go-acme";
    repo = "lego";
    rev = "v${finalAttrs.version}";
    hash = "sha256-OeQ947WTnBPyfQcOS37bleQCjpUYoUJlt0YrG6jsHNg=";
  };

  vendorHash = "sha256-nCeJ3wkBVq4fi0hrTBmFa70HcZl016SD7GF6Xu93GQI=";

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
  };
})
