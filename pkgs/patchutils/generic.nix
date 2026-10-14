{
  lib,
  stdenv,
  fetchurl,
  perl,
  makeWrapper,
  version,
  sha256,
  patches ? [ ],
  extraBuildInputs ? [ ],
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "patchutils";
  inherit version patches;

  src = fetchurl {
    url = "http://cyberelk.net/tim/data/patchutils/stable/${finalAttrs.pname}-${finalAttrs.version}.tar.xz";
    inherit sha256;
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ perl ] ++ extraBuildInputs;
  hardeningDisable = [ "format" ];

  # tests fail when checking in parallel
  enableParallelChecking = false;

  preConfigure = ''
    export PERL=${perl.interpreter}
  '';

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
