{
  lib,
  stdenv,
  fetchurl,
  # Image file formats
  libjpeg,
  libtiff,
  giflib,
  libpng,
  libwebp,
  libjxl,
  freetype,
  bzip2,
  pkg-config,
  x11Support ? true,
  webpSupport ? true,
  jxlSupport ? false,
  libxft,
  libxext,
}:

let
  inherit (lib) optional optionals;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "imlib2";
  version = "1.12.6";

  src = fetchurl {
    url = "mirror://sourceforge/enlightenment/imlib2-${finalAttrs.version}.tar.xz";
    hash = "sha256-JQ+XUvadxSLlKagaqpOVcF9/wxL/JFPl3lmsK6HyhY8=";
  };

  buildInputs = [
    libjpeg
    libtiff
    giflib
    libpng
    bzip2
    freetype
    # TODO(corepkgs): Port libid3tag for ID3 tag image loading
    # TODO(corepkgs): Port libspectre for PostScript support (psSupport)
    # TODO(corepkgs): Port librsvg for SVG support (svgSupport)
    # TODO(corepkgs): Port libheif for HEIF support (heifSupport)
  ]
  ++ optionals x11Support [
    libxft
    libxext
  ]
  ++ optional webpSupport libwebp
  ++ optional jxlSupport libjxl;

  nativeBuildInputs = [ pkg-config ];

  enableParallelBuilding = true;

  # Do not build amd64 assembly code on Darwin, because it fails to compile
  # with unknown directive errors
  configureFlags =
    optional stdenv.hostPlatform.isDarwin "--enable-amd64=no"
    ++ [
      "--without-svg"
      "--without-heif"
    ]
    ++ optional (!x11Support) "--without-x";

  outputs = [
    "bin"
    "out"
    "dev"
  ];

  meta = {
    description = "Image manipulation library";

    longDescription = ''
      This is the Imlib 2 library - a library that does image file loading and
      saving as well as rendering, manipulation, arbitrary polygon support, etc.
      It does ALL of these operations FAST. Imlib2 also tries to be highly
      intelligent about doing them, so writing naive programs can be done
      easily, without sacrificing speed.
    '';

    homepage = "https://docs.enlightenment.org/api/imlib2/html";
    changelog = "https://git.enlightenment.org/old/legacy-imlib2/raw/tag/v${finalAttrs.version}/ChangeLog";
    license = lib.licenses.imlib2;
    pkgConfigModules = [ "imlib2" ];
    platforms = lib.platforms.unix;
    maintainers = [ ];
  };
})
