{
  lib,
  stdenv,
  fetchFromCodeberg,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libjodycode";
  version = "4.1.2";

  outputs = [
    "out"
    "man"
    "dev"
  ];

  src = fetchFromCodeberg {
    owner = "jbruchon";
    repo = "libjodycode";
    rev = "v${finalAttrs.version}";
    hash = "sha256-HqDNbZwWDebVnu1uj07N/ttwmvvz1qGk8s/Vrc3hJK4=";
  };

  env.PREFIX = placeholder "out";

  enableParallelBuilding = true;

  meta = {
    description = "Shared code used by several utilities written by Jody Bruchon";
    homepage = "https://codeberg.org/jbruchon/libjodycode";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = [ ];
  };
})
