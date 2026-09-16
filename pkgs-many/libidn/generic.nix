{
  version,
  src-url,
  src-hash,
  packageOlder,
  packageAtLeast,
  ...
}@variantArgs:

{
  lib,
  stdenv,
  fetchurl,
  libiconv,
  libunistring,
  help2man,
  texinfo,
  buildPackages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = if packageAtLeast "2" then "libidn2" else "libidn";
  inherit version;

  src = fetchurl {
    url = src-url;
    hash = src-hash;
  };

  outputs = [
    "bin"
    "dev"
    "out"
    "info"
    "devdoc"
  ];

  strictDeps = true;

  hardeningDisable = lib.optionals (packageOlder "2") [ "format" ];

  depsBuildBuild = lib.optionals (packageAtLeast "2") [
    buildPackages.stdenv.cc
  ];

  nativeBuildInputs = lib.optionals (packageAtLeast "2" && stdenv.hostPlatform.isDarwin) [
    help2man
    texinfo
  ];

  buildInputs =
    lib.optionals (packageAtLeast "2") [ libunistring ]
    ++ lib.optional stdenv.hostPlatform.isDarwin libiconv;

  meta = {
    homepage =
      if packageAtLeast "2" then
        "https://www.gnu.org/software/libidn/#libidn2"
      else
        "https://www.gnu.org/software/libidn/";
    description =
      if packageAtLeast "2" then
        "Free software implementation of IDNA2008 and TR46"
      else
        "Library for internationalized domain names";
    mainProgram = if packageAtLeast "2" then "idn2" else "idn";
    license =
      if packageAtLeast "2" then
        with lib.licenses;
        [
          lgpl3Plus
          gpl2Plus
          gpl3Plus
        ]
      else
        lib.licenses.lgpl2Plus;
    platforms = lib.platforms.all;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "gnu" finalAttrs.version;
  };
})
