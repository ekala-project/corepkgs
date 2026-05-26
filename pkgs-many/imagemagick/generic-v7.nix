{
  version,
  src-hash,
  bzip2Support ? true,
  zlibSupport ? true,
  libX11Support ? null,
  libXtSupport ? null,
  fontconfigSupport ? true,
  freetypeSupport ? true,
  ghostscriptSupport ? false,
  libjpegSupport ? true,
  djvulibreSupport ? true,
  lcms2Support ? true,
  openexrSupport ? null,
  libjxlSupport ? true,
  libpngSupport ? true,
  liblqr1Support ? true,
  libraqmSupport ? true,
  librawSupport ? true,
  librsvgSupport ? null,
  libtiffSupport ? true,
  libxml2Support ? true,
  openjpegSupport ? null,
  libwebpSupport ? null,
  libheifSupport ? true,
  fftwSupport ? true,
  mkVariantPassthru,
  ...
}@variantArgs:

{
  lib,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  libtool,
  bzip2,
  zlib,
  libX11,
  libXt,
  fontconfig,
  freetype,
  ghostscript,
  libjpeg,
  djvulibre,
  lcms2,
  openexr,
  libjxl,
  libpng,
  liblqr1,
  libraqm,
  libraw,
  librsvg,
  pango,
  libtiff,
  libxml2,
  openjpeg,
  libwebp,
  libheif,
  fftw,
  potrace,
  coreutils,
  curl,
  testers,
  nixos-icons,
  perlPackages,
  python3,
}:

let
  # Resolve null platform-default flags using the local stdenv
  libX11Support' = if libX11Support == null then !stdenv.hostPlatform.isMinGW else libX11Support;
  libXtSupport' = if libXtSupport == null then !stdenv.hostPlatform.isMinGW else libXtSupport;
  openexrSupport' = if openexrSupport == null then !stdenv.hostPlatform.isMinGW else openexrSupport;
  librsvgSupport' = if librsvgSupport == null then !stdenv.hostPlatform.isMinGW else librsvgSupport;
  openjpegSupport' = if openjpegSupport == null then !stdenv.hostPlatform.isMinGW else openjpegSupport;
  libwebpSupport' = if libwebpSupport == null then !stdenv.hostPlatform.isMinGW else libwebpSupport;
in

assert libXtSupport' -> libX11Support';
assert libraqmSupport -> freetypeSupport;

let
  arch =
    if stdenv.hostPlatform.system == "i686-linux" then
      "i686"
    else if
      stdenv.hostPlatform.system == "x86_64-linux" || stdenv.hostPlatform.system == "x86_64-darwin"
    then
      "x86-64"
    else if stdenv.hostPlatform.system == "armv7l-linux" then
      "armv7l"
    else if
      stdenv.hostPlatform.system == "aarch64-linux" || stdenv.hostPlatform.system == "aarch64-darwin"
    then
      "aarch64"
    else if stdenv.hostPlatform.system == "powerpc64le-linux" then
      "ppc64le"
    else
      null;
in

stdenv.mkDerivation (finalAttrs: {
  pname = "imagemagick";
  inherit version;

  src = fetchFromGitHub {
    owner = "ImageMagick";
    repo = "ImageMagick";
    tag = finalAttrs.version;
    hash = src-hash;
  };

  outputs = [
    "out"
    "dev"
    "doc"
  ]; # bin/ isn't really big
  outputMan = "out"; # it's tiny

  enableParallelBuilding = true;

  configureFlags = [
    # specify delegates explicitly otherwise `convert` will invoke the build
    # coreutils for filetypes it doesn't natively support.
    "MVDelegate=${lib.getExe' coreutils "mv"}"
    "RMDelegate=${lib.getExe' coreutils "rm"}"
    "--with-frozenpaths"
    (lib.withFeatureAs (arch != null) "gcc-arch" arch)
    (lib.withFeature librsvgSupport' "rsvg")
    (lib.withFeature librsvgSupport' "pango")
    (lib.withFeature liblqr1Support "lqr")
    (lib.withFeature libjxlSupport "jxl")
    (lib.withFeatureAs ghostscriptSupport "gs-font-dir" "${ghostscript.fonts}/share/fonts")
    (lib.withFeature ghostscriptSupport "gslib")
    (lib.withFeature fftwSupport "fftw")
  ]
  ++ lib.optionals stdenv.hostPlatform.isMinGW [
    # due to libxml2 being without DLLs ATM
    "--enable-static"
    "--disable-shared"
  ];

  nativeBuildInputs = [
    pkg-config
    libtool
  ];

  buildInputs = [
    potrace
  ]
  ++ lib.optional zlibSupport zlib
  ++ lib.optional fontconfigSupport fontconfig
  ++ lib.optional ghostscriptSupport ghostscript
  ++ lib.optional liblqr1Support liblqr1
  ++ lib.optional libpngSupport libpng
  ++ lib.optional libraqmSupport libraqm
  ++ lib.optional librawSupport libraw
  ++ lib.optional libtiffSupport libtiff
  ++ lib.optional libxml2Support libxml2
  ++ lib.optional libheifSupport libheif
  ++ lib.optional djvulibreSupport djvulibre
  ++ lib.optional libjxlSupport libjxl
  ++ lib.optional openexrSupport' openexr
  ++ lib.optionals librsvgSupport' [
    librsvg
    pango
  ]
  ++ lib.optional openjpegSupport' openjpeg;

  propagatedBuildInputs = [
    curl
  ]
  ++ lib.optional bzip2Support bzip2
  ++ lib.optional freetypeSupport freetype
  ++ lib.optional libjpegSupport libjpeg
  ++ lib.optional lcms2Support lcms2
  ++ lib.optional libX11Support' libX11
  ++ lib.optional libXtSupport' libXt
  ++ lib.optional libwebpSupport' libwebp
  ++ lib.optional fftwSupport fftw;

  postInstall = ''
    (cd "$dev/include" && ln -s ImageMagick* ImageMagick)
    # Q16HDRI = 16 bit quantum depth with HDRI support, and is the default ImageMagick configuration
    # If the default is changed, or the derivation is modified to use a different configuration
    # this will need to be changed below.
    moveToOutput "bin/*-config" "$dev"
    moveToOutput "lib/ImageMagick-*/config-Q16HDRI" "$dev" # includes configure params
    configDestination=($out/share/ImageMagick-*)
    grep -v '/nix/store' $dev/lib/ImageMagick-*/config-Q16HDRI/configure.xml > $configDestination/configure.xml
    for file in "$dev"/bin/*-config; do
      substituteInPlace "$file" --replace pkg-config \
        "PKG_CONFIG_PATH='$dev/lib/pkgconfig' '$(command -v $PKG_CONFIG)'"
    done
  ''
  + lib.optionalString ghostscriptSupport ''
    for la in $out/lib/*.la; do
      sed 's|-lgs|-L${lib.getLib ghostscript}/lib -lgs|' -i $la
    done
  '';

  passthru = mkVariantPassthru variantArgs // {
    tests = {
      version = testers.testVersion { package = finalAttrs.finalPackage; };
      inherit nixos-icons;
      inherit (perlPackages) ImageMagick;
      inherit (python3.pkgs) img2pdf willow;
      pkg-config = testers.hasPkgConfigModules {
        package = finalAttrs.finalPackage;
        version = lib.head (lib.splitString "-" finalAttrs.version);
      };
    };
  };

  meta = {
    homepage = "http://www.imagemagick.org/";
    changelog = "https://github.com/ImageMagick/Website/blob/main/ChangeLog.md";
    description = "Software suite to create, edit, compose, or convert bitmap images";
    pkgConfigModules = [
      "ImageMagick"
      "MagickWand"
    ];
    platforms = lib.platforms.unix;
    license = lib.licenses.asl20;
    mainProgram = "magick";
  };
})
