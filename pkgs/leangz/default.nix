{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "leangz";
  version = "0.1.21";

  src = fetchFromGitHub {
    owner = "digama0";
    repo = "leangz";
    tag = "v${finalAttrs.version}";
    hash = "sha256-EBQP+ilCZsVdv92Gx5c4NKpF4XBlFhFSUx3BjEd52Ik=";
  };

  cargoHash = "sha256-axSsZ1T1VNd7liTeVIYj2DICOo49CDV5821vcXqmw0Y=";

  meta = {
    description = "Lean 4 .olean file (de)compressor";
    homepage = "https://github.com/digama0/leangz";
    license = lib.licenses.asl20;
    mainProgram = "leantar";
  };
})
