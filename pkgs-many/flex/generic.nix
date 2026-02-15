{
  version,
  src-url,
  src-hash,
  needsFlexBootstrap ? false,
  needsTexinfo ? false,
  doCheck ? true,
  glibcPatchUrl ? null,
  glibcPatchHash ? null,
  metaHomepage,
  packageOlder,
  packageAtLeast,
  ...
}@variantArgs:

{
  lib,
  stdenv,
  buildPackages,
  fetchurl,
  bison,
  m4,
  autoreconfHook,
  help2man,
  flex ? null,
  texinfo ? null,
}:

# Avoid 'fetchpatch' to allow 'flex' to be used as a possible 'gcc'
# dependency during bootstrap. Useful when gcc is built from snapshot
# or from a git tree (flex lexers are not pre-generated there).

stdenv.mkDerivation rec {
  pname = "flex";
  inherit version;

  src = fetchurl {
    url = src-url;
    hash = src-hash;
  };

  # v2.6.4 needs glibc-2.26 patch (will be part of 2.6.5)
  # https://github.com/westes/flex/commit/24fd0551333e
  patches = lib.optionals (glibcPatchUrl != null) [
    (fetchurl {
      name = "glibc-2.26.patch";
      url = glibcPatchUrl;
      sha256 = glibcPatchHash;
    })
  ];

  postPatch =
    ''
      patchShebangs tests
    ''
    + lib.optionalString (stdenv.buildPlatform != stdenv.hostPlatform) ''
      substituteInPlace Makefile.in --replace "tests" " "

      substituteInPlace doc/Makefile.am --replace 'flex.1: $(top_srcdir)/configure.ac' 'flex.1: '
    '';

  depsBuildBuild = lib.optionals (packageAtLeast "2.6") [ buildPackages.stdenv.cc ];

  nativeBuildInputs =
    # v2.5.35 needs flex to build itself (bootstrap)
    lib.optionals needsFlexBootstrap [ flex ]
    ++ [
      bison
      help2man
      autoreconfHook
    ]
    # v2.5.35 needs texinfo
    ++ lib.optionals needsTexinfo [ texinfo ];

  buildInputs = lib.optionals (packageAtLeast "2.6") [ bison ];

  propagatedBuildInputs = [ m4 ];

  preConfigure = lib.optionalString (stdenv.hostPlatform != stdenv.buildPlatform) ''
    export ac_cv_func_malloc_0_nonnull=yes
    export ac_cv_func_realloc_0_nonnull=yes
  '';

  postConfigure = lib.optionalString (stdenv.hostPlatform.isDarwin || stdenv.hostPlatform.isCygwin) ''
    sed -i Makefile -e 's/-no-undefined//;'
  '';

  dontDisableStatic = stdenv.buildPlatform != stdenv.hostPlatform;

  inherit doCheck;

  postInstall = ''
    ln -s $out/bin/flex $out/bin/lex
  '';

  meta = {
    homepage = metaHomepage;
    description = "Fast lexical analyser generator";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.unix;
  }
  # v2.5.35 has a branch attribute in meta
  // lib.optionalAttrs (packageOlder "2.6") {
    branch = version;
  }
  # v2.6+ has mainProgram in meta
  // lib.optionalAttrs (packageAtLeast "2.6") {
    mainProgram = "flex";
  };
}
