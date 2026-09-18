{
  lib,
  stdenv,
  fetchurl,
  cmake,
  pkg-config,
  hidapi,
  libcbor,
  openssl,
  udev,
  udevCheckHook,
  zlib,
  withPcsclite ? true,
  pcsclite,
  openssh,
}:

stdenv.mkDerivation rec {
  pname = "libfido2";
  version = "1.16.0";

  # releases on https://developers.yubico.com/libfido2/Releases/ are signed
  src = fetchurl {
    url = "https://developers.yubico.com/${pname}/Releases/${pname}-${version}.tar.gz";
    hash = "sha256-jCtvsnm1tC6aySrecYMuSFhSZHtTYHxDuqr7vOzqBOQ=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
    pkg-config
    udevCheckHook
  ];

  buildInputs = [
    libcbor
    zlib
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [ hidapi ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ udev ]
  ++ lib.optionals (stdenv.hostPlatform.isLinux && withPcsclite) [ pcsclite ];

  propagatedBuildInputs = [ openssl ];

  outputs = [
    "out"
    "dev"
    "man"
  ];

  doInstallCheck = true;

  cmakeEntries = {
    UDEV_RULES_DIR = "${placeholder "out"}/etc/udev/rules.d";
    CMAKE_INSTALL_LIBDIR = "lib";
    ${if stdenv.hostPlatform.isDarwin then "USE_HIDAPI" else null} = "1";
    ${if stdenv.hostPlatform.isLinux then "NFC_LINUX" else null} = "1";
    ${if stdenv.hostPlatform.isLinux && withPcsclite then "USE_PCSC" else null} = "1";
  };

  # causes possible redefinition of _FORTIFY_SOURCE?
  hardeningDisable = [ "fortify3" ];

  passthru.tests = {
    inherit openssh;
  };

  meta = {
    description = ''
      Provides library functionality for FIDO 2.0, including communication with a device over USB.
    '';
    homepage = "https://github.com/Yubico/libfido2";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "yubico" version;
  };
}
