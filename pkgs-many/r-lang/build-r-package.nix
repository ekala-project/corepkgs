{
  r-lang,
  stdenv,
  lib,
}:

{
  pname,
  version,
  src,
  buildInputs ? [ ],
  nativeBuildInputs ? [ ],
  ...
}@args:

stdenv.mkDerivation (
  args
  // {
    pname = "r-${pname}";
    inherit version src;

    nativeBuildInputs = [ r-lang ] ++ nativeBuildInputs;

    buildInputs = [ r-lang ] ++ buildInputs;

    configurePhase = ''
      runHook preConfigure
      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/library
      R CMD INSTALL --library=$out/library .

      runHook postInstall
    '';

    meta = args.meta or { } // {
      platforms = r-lang.meta.platforms;
    };
  }
)
