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

    configurePhase = "";

    buildPhase = "";

    installPhase = ''

      mkdir -p $out/library
      R CMD INSTALL --library=$out/library .

    '';

    meta = args.meta or { } // {
      platforms = r-lang.meta.platforms;
    };
  }
)
