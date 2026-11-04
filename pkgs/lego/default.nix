{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "lego";
  version = "5.6.0";

  src = fetchFromGitHub {
    owner = "go-acme";
    repo = "lego";
    tag = "v${finalAttrs.version}";
    hash = "sha256-YC6rrsRjlKYllv60mWFMlTNp8OgPGDA4Wi9/ALknkRg=";
  };

  vendorHash = "sha256-S7aJVA1YvgUB9q+hCuwQCOFdDrNI/uQ3v5n6uiHIT/4=";

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
