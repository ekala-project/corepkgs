{
  version,
  src-url,
  src-hash,
  isoents-url,
  isoents-hash,
  mkVariantPassthru,
  ...
}@variantArgs:

{
  lib,
  stdenv,
  fetchurl,
  unzip,
}:

let
  src = fetchurl {
    url = src-url;
    sha256 = src-hash;
  };

  isoents = fetchurl {
    url = isoents-url;
    sha256 = isoents-hash;
  };
in

stdenv.mkDerivation {
  name = "docbook-sgml-${version}";

  dontUnpack = true;

  nativeBuildInputs = [ unzip ];

  installPhase = ''
    o=$out/sgml/dtd/docbook-${version}
    mkdir -p $o
    cd $o
    unzip ${src}
    unzip ${isoents}
    sed -e "s/iso-/ISO/" -e "s/.gml//" -i docbook.cat
  '';

  passthru = mkVariantPassthru variantArgs;

  meta = {
    platforms = lib.platforms.unix;
  };
}
