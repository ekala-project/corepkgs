{
  version,
  src-hash,
  ...
}:

{
  lib,
  stdenv,
  libgcrypt,
  curl,
  gnutls,
  pkg-config,
  libiconv,
  libintl,
  fetchurl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "libmicrohttpd";
  inherit version;

  src = fetchurl {
    url = "mirror://gnu/libmicrohttpd/libmicrohttpd-${version}.tar.gz";
    hash = src-hash;
  };

  outputs = [
    "out"
    "dev"
    "devdoc"
    "info"
  ];
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    libgcrypt
    curl
    gnutls
    libiconv
    libintl
  ];

  preCheck = ''
    # Since `localhost' can't be resolved in a chroot, work around it.
    sed -i -e 's/localhost/127.0.0.1/g' src/test*/*.[ch]
  '';

  passthru = {
    ekapkgs-update.semver-strategy = "patch";
    # tests = {
    #   build = finalAttrs.finalPackage.overrideAttrs { doCheck = true; };
    # };
    # Tests disabled: the tests can time-out
  };

  meta = {
    description = "Embeddable HTTP server library";

    longDescription = ''
      GNU libmicrohttpd is a small C library that is supposed to make
      it easy to run an HTTP server as part of another application.
    '';

    license = lib.licenses.lgpl2Plus;

    homepage = "https://www.gnu.org/software/libmicrohttpd/";

    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "gnu" version;
  };
})
