{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

# buildNpmPackage does not accept a finalAttrs function.
let
  version = "3.19.3";
in
buildNpmPackage {
  pname = "uglify-js";
  inherit version;

  src = fetchFromGitHub {
    owner = "mishoo";
    repo = "UglifyJS";
    tag = "v${version}";
    hash = "sha256-sMLQSB1+ux/ya/J22KGojlAxWhtPQdk22KdHy43zdyg=";
  };

  npmDepsHash = "sha256-/Xb8DT7vSzZPEd+Z+z1BlFnrOeOwGP+nGv2K9iz6lKI=";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  dontNpmBuild = true;

  meta = {
    description = "JavaScript parser / mangler / compressor / beautifier toolkit";
    homepage = "https://github.com/mishoo/UglifyJS";
    changelog = "https://github.com/mishoo/UglifyJS/releases/tag/v${version}";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.all;
    mainProgram = "uglifyjs";
  };
}
