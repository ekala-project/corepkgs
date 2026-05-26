{
  version,
  src-hash,
  packageAtLeast,
  packageOlder,
  ...
}@variantArgs:

{
  lib,
  stdenv,
  fetchurl,
  doCheck ? !(stdenv.hostPlatform.isStatic),
  dejagnu,
  nix-update-script,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libffi";
  inherit version;

  src = fetchurl {
    url = "https://github.com/libffi/libffi/releases/download/v${finalAttrs.version}/${finalAttrs.pname}-${finalAttrs.version}.tar.gz";
    hash = src-hash;
  };

  patches = lib.optional (packageAtLeast "3.5") ./freebsd-tsan-pthread.patch;

  outputs = [
    "out"
    "dev"
    "man"
    "info"
  ];

  configureFlags = [
    "--with-gcc-arch=generic"
    "--enable-pax_emutramp"
  ]
  ++ lib.optional (packageOlder "3.5") "--disable-exec-static-tramp";

  preCheck = ''
    # The tests use -O0 which is not compatible with -D_FORTIFY_SOURCE.
  ''
  + lib.optionalString (packageAtLeast "3.5") ''
    NIX_HARDENING_ENABLE=''${NIX_HARDENING_ENABLE/fortify3/}
  ''
  + ''
    NIX_HARDENING_ENABLE=''${NIX_HARDENING_ENABLE/fortify/}
  '';

  dontStrip = stdenv.hostPlatform != stdenv.buildPlatform;

  doCheck = false;

  nativeCheckInputs = [ dejagnu ];

  passthru =
    {
      tests =
        {
          unit = finalAttrs.finalPackage.overrideAttrs { doCheck = true; };
        }
        // lib.optionalAttrs (packageAtLeast "3.5") {
          pkg-config = testers.hasPkgConfigModules { package = finalAttrs.finalPackage; };
        };
    }
    // lib.optionalAttrs (packageAtLeast "3.5") {
      updateScript = nix-update-script { };
    };

  meta = {
    description = "Foreign function call interface library";
    homepage = "http://sourceware.org/libffi/";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  }
  // lib.optionalAttrs (packageAtLeast "3.5") {
    pkgConfigModules = [ "libffi" ];
  }
  // lib.optionalAttrs (packageOlder "3.5") {
    broken = stdenv.hostPlatform.isDarwin && stdenv.hostPlatform.isAarch64;
  };
}
// lib.optionalAttrs (packageAtLeast "3.5") {
  strictDeps = true;
  enableParallelBuilding = true;
  configurePlatforms = [
    "build"
    "host"
  ];
}
// lib.optionalAttrs (packageOlder "3.5") {
  hardeningDisable = [ "fortify3" ];
})
