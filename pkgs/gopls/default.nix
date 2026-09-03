# gopls — official Go language server
{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "gopls";
  version = "0.23.0";

  src = fetchFromGitHub {
    owner = "golang";
    repo = "tools";
    tag = "gopls/v${finalAttrs.version}";
    hash = "sha256-GTRZ0tS2a7Cx4qRf6PfxhkGVPYRoLYOmE+W/2x9Pttk=";
  };

  modRoot = "gopls";
  vendorHash = "sha256-rvm33C3z3T6moeEQ4C7aG+dT8ROqmpBFehIpwGFZMrU=";

  ldflags = [ "-X main.version=v${finalAttrs.version}" ];

  subPackages = [ "." ];

  meta = {
    description = "Official language server for the Go language";
    homepage = "https://github.com/golang/tools/tree/master/gopls";
    license = lib.licenses.bsd3;
    mainProgram = "gopls";
  };
})
