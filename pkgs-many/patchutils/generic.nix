{
  version,
  src-hash,
  patches ? [ ],
  withPython ? false,
  ...
}:

{
  lib,
  stdenv,
  fetchurl,
  perl,
  python3,
  makeWrapper,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "patchutils";
  inherit version patches;

  src = fetchurl {
    url = "http://cyberelk.net/tim/data/patchutils/stable/${finalAttrs.pname}-${finalAttrs.version}.tar.xz";
    sha256 = src-hash;
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ perl ] ++ lib.optional withPython python3;
  hardeningDisable = [ "format" ];

  # tests fail when building in parallel
  enableParallelBuilding = false;

  postInstall = ''
    for bin in $out/bin/{splitdiff,rediff,editdiff,dehtmldiff}; do
      wrapProgram "$bin" \
        --prefix PATH : "$out/bin"
    done
  '';

  doCheck = lib.versionAtLeast version "0.3.4";

  preCheck = ''
    patchShebangs tests
    chmod +x scripts/*
  ''
  + lib.optionalString (lib.versionOlder version "0.4.2") ''
    find tests -type f -name 'run-test' \
      -exec sed -i '{}' -e 's|/bin/echo|echo|g' \;
  '';

  meta = {
    description = "Tools to manipulate patch files";
    homepage = "http://cyberelk.net/tim/software/patchutils";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.all;
  };
})
