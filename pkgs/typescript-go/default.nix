{
  lib,
  buildGoModule,
  fetchFromGitHub,
  go,
}:

(buildGoModule.override { go = go.v1_26; }) (finalAttrs: {
  pname = "typescript-go";
  version = "7.0.2";

  src = fetchFromGitHub {
    owner = "microsoft";
    repo = "typescript-go";
    tag = "typescript/v${finalAttrs.version}";
    hash = "sha256-fRejdQSwaxSS2pjHrbJO2CQgZS5lWJmBNEM/TgbJTJ8=";
  };

  vendorHash = "sha256-q6dMb2ab4uZ3GTrcA7v2JzfmOM+ZzBcJN6gKOpLfM/k=";

  ldflags = [
    "-s"
    "-w"
  ];

  env.CGO_ENABLED = 0;

  subPackages = [
    "cmd/tsgo"
  ];

  postInstall = ''
    ln -s "$out/bin/tsgo" "$out/bin/tsc"
  '';

  meta = {
    description = "Go implementation of TypeScript";
    homepage = "https://github.com/microsoft/typescript-go";
    license = lib.licenses.asl20;
    mainProgram = "tsc";
  };
})
