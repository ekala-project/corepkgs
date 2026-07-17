{
  lib,
  stdenv,
  fetchurl,
  bzip2,
  gfortran,
  libx11,
  libxmu,
  libxt,
  libjpeg,
  libpng,
  libtiff,
  ncurses,
  pango,
  pcre2,
  perl,
  readline,
  tcl,
  texliveSmall ? null,
  tk,
  xz,
  zlib,
  less,
  texinfo,
  # TODO(corepkgs): Enable graphviz for R vignettes (needs gd, gts ported)
  # graphviz,
  icu,
  pkg-config,
  bison,
  which,
  jdk,
  blas,
  lapack,
  curl,
  tzdata,
  cairo,
  withRecommendedPackages ? true,
  enableStrictBarrier ? false,
  enableMemoryProfiling ? false,
  static ? false,
  testers,
}:

assert (!blas.isILP64) && (!lapack.isILP64);

stdenv.mkDerivation (finalAttrs: {
  pname = "R";
  version = "4.6.0";

  src =
    let
      inherit (finalAttrs) pname version;
    in
    fetchurl {
      url = "https://cran.r-project.org/src/base/R-${lib.versions.major version}/${pname}-${version}.tar.gz";
      hash = "sha256-uNybRUNmDHtZa4eTjfUyOUNQNgl2Un00QijuDtEuRew=";
    };

  outputs = [
    "out"
    "man"
  ]
  ++ lib.optional (texliveSmall != null) "tex";

  nativeBuildInputs = [
    bison
    perl
    pkg-config
    tzdata
    which
  ];

  buildInputs = [
    bzip2
    gfortran
    libx11
    libxmu
    libxt
    libjpeg
    libpng
    libtiff
    ncurses
    pango
    pcre2
    readline
    xz
    zlib
    less
    texinfo
    icu
    which
    blas
    lapack
    curl
    cairo
    tcl
    tk
    jdk
  ]
  ++ lib.optional (texliveSmall != null) (
    texliveSmall.withPackages (
      ps: with ps; [
        inconsolata
        helvetic
        ps.texinfo
        fancyvrb
        cm-super
        rsfs
      ]
    )
  );

  strictDeps = true;

  patches = [
    ./no-usr-local-search-paths.patch
  ];

  dontDisableStatic = static;

  preConfigure = ''
    configureFlagsArray=(
      --disable-lto
      --with${lib.optionalString (!withRecommendedPackages) "out"}-recommended-packages
      --with-blas="-L${blas}/lib -lblas"
      --with-lapack="-L${lapack}/lib -llapack"
      --with-readline
      --with-tcltk --with-tcl-config="${tcl}/lib/tclConfig.sh" --with-tk-config="${tk}/lib/tkConfig.sh"
      --with-cairo
      --with-libpng
      --with-jpeglib
      --with-libtiff
      --with-ICU
      ${lib.optionalString enableStrictBarrier "--enable-strict-barrier"}
      ${lib.optionalString enableMemoryProfiling "--enable-memory-profiling"}
      ${if static then "--enable-R-static-lib" else "--enable-R-shlib"}
      AR=$(type -p ar)
      AWK=$(type -p gawk)
      CC=$(type -p cc)
      CXX=$(type -p c++)
      FC="${gfortran}/bin/gfortran" F77="${gfortran}/bin/gfortran"
      JAVA_HOME="${jdk}"
      RANLIB=$(type -p ranlib)
      CURL_CONFIG="${lib.getExe' (lib.getDev curl) "curl-config"}"
      r_cv_have_curl728=yes
      R_SHELL="${stdenv.shell}"
    )
    echo >>etc/Renviron.in "TCLLIBPATH=${tk}/lib"
    echo >>etc/Renviron.in "TZDIR=${tzdata}/share/zoneinfo"
  '';

  installTargets = [
    "install"
    "install-info"
  ]
  ++ lib.optional (texliveSmall != null) "install-pdf";

  postInstall = lib.optionalString (texliveSmall != null) ''
    mv -T "$out/lib/R/share/texmf" "$tex"
    ln -s "$tex" "$out/lib/R/share/texmf"
  '';

  postFixup = ''
    echo ${which} > $out/nix-support/undetected-runtime-dependencies
    find $out -name "*.so" -exec patchelf {} --add-rpath $out/lib/R/lib \;
  '';

  doCheck = true;
  preCheck = "export HOME=$TMPDIR; export TZ=CET; bin/Rscript -e 'sessionInfo()'";

  enableParallelBuilding = true;

  setupHook = ./setup-hook.sh;

  passthru.tests.pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;

  passthru.tlDeps = ps: [
    ps.amsfonts
    ps.amsmath
    ps.fancyvrb
    ps.graphics
    ps.hyperref
    ps.iftex
    ps.jknapltx
    ps.latex
    ps.lm
    ps.tools
    ps.upquote
    ps.url
  ];

  meta = {
    homepage = "http://www.r-project.org/";
    description = "Free software environment for statistical computing and graphics";
    mainProgram = "R";
    license = lib.licenses.gpl2Plus;
    pkgConfigModules = [ "libR" ];
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
})
