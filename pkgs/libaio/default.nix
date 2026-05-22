{
  lib,
  stdenv,
  fetchurl,
}:

stdenv.mkDerivation (finalAttrs: {
  version = "0.3.113";
  pname = "libaio";

  src = fetchurl {
    url = "https://pagure.io/libaio/archive/${finalAttrs.pname}-${finalAttrs.version}/${finalAttrs.pname}-${finalAttrs.pname}-${finalAttrs.version}.tar.gz";
    sha256 = "sha256-cWxwWXAyRzROsGa1TsvDyiE08BAzBxkubCt9q1+VKKs=";
  };

  postPatch = ''
    patchShebangs harness

    # Makefile is too optimistic, gcc is too smart
    substituteInPlace harness/Makefile \
      --replace "-Werror" ""
  '';

  makeFlags = [
    "prefix=${placeholder "out"}"
  ]
  ++ lib.optional stdenv.hostPlatform.isStatic "ENABLE_SHARED=0";

  hardeningDisable = lib.optional (stdenv.hostPlatform.isi686) "stackprotector";

  checkTarget = "partcheck"; # "check" needs root

  doCheck = false;

  passthru.tests.unit = finalAttrs.finalPackage.overrideAttrs { doCheck = true; };

  meta = {
    description = "Library for asynchronous I/O in Linux";
    homepage = "https://lse.sourceforge.net/io/aio.html";
    platforms = lib.platforms.linux;
    license = lib.licenses.lgpl21;
  };
})
