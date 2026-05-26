{
  version,
  src-hash,
  apngSupport ? false,
  apng-patch-hash ? null,
  packageAtLeast,
  packageOlder,
  ...
}@variantArgs:

{
  lib,
  stdenv,
  fetchurl,
  zlib,
  testers,
}:

assert apngSupport -> apng-patch-hash != null;
assert packageOlder "1.6" -> stdenv.hostPlatform == stdenv.buildPlatform -> zlib != null;
assert packageAtLeast "1.6" -> zlib != null;

let
  branch = lib.versions.majorMinor version;
  whenPatched = lib.optionalString apngSupport;
  patch_src =
    if apngSupport then
      fetchurl {
        url = "mirror://sourceforge/libpng-apng/libpng-${version}-apng.patch.gz";
        hash = apng-patch-hash;
      }
    else
      null;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "libpng" + whenPatched "-apng";
  inherit version;

  src = fetchurl {
    url = "mirror://sourceforge/libpng/libpng-${finalAttrs.version}.tar.xz";
    hash = src-hash;
  };

  postPatch =
    whenPatched "gunzip < ${patch_src} | patch -Np1"
    + lib.optionalString (packageAtLeast "1.6" && stdenv.hostPlatform.isFreeBSD) ''

      sed -i 1i'int feenableexcept(int __mask);' contrib/libtests/pngvalid.c
    ''
    + lib.optionalString (packageOlder "1.6" && stdenv.hostPlatform.isDarwin) ''
      substituteInPlace pngconf.h --replace-fail '<fp.h>' '<math.h>'
    '';

  outputs = [
    "out"
    "dev"
    "man"
  ];

  propagatedBuildInputs = [ zlib ];

  doCheck = packageAtLeast "1.6";

  passthru = {
    inherit zlib;

    tests =
      {
        pkg-config = testers.testMetaPkgConfig finalAttrs.finalPackage;
      }
      // lib.optionalAttrs (packageAtLeast "1.6") {
        pkg-config-install = testers.pkg-config.testInstall finalAttrs.finalPackage { };
      };
  };

  meta = {
    description =
      "Official reference implementation for the PNG file format" + whenPatched " with animation patch";
    homepage = "http://www.libpng.org/pub/png/libpng.html";
    license = if packageAtLeast "1.6" then lib.licenses.libpng2 else lib.licenses.libpng;
    inherit branch;
    pkgConfigModules =
      [ "libpng" ]
      ++ lib.optional (packageAtLeast "1.6") "libpng16"
      ++ lib.optional (packageOlder "1.6") "libpng12";
    platforms = if packageAtLeast "1.6" then lib.platforms.all else lib.platforms.unix;
  }
  // lib.optionalAttrs (packageAtLeast "1.6") {
    changelog = "https://github.com/pnggroup/libpng/blob/v${finalAttrs.version}/CHANGES";
  };
}
// lib.optionalAttrs (packageOlder "1.6") {
  configureFlags = [ "--enable-static" ];

  postInstall = ''mv "$out/bin" "$dev/bin"'';
}
// lib.optionalAttrs (packageAtLeast "1.6") {
  outputBin = "dev";
})
