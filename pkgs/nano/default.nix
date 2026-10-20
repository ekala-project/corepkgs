{
  lib,
  stdenv,
  fetchurl,
  ncurses,
  gettext,
  pkg-config,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "nano";
  version = "9.2";

  src = fetchurl {
    url = "mirror://gnu/nano/nano-${finalAttrs.version}.tar.xz";
    hash = "sha256-Bey5kke3guils6Je1BAd0DSwI2kC90SbyXlbcXZC9+k=";
  };

  nativeBuildInputs = [
    pkg-config
    gettext
  ];

  buildInputs = [
    ncurses
  ];

  configureFlags = [
    "--enable-utf8"
    "--sysconfdir=/etc"
  ];

  outputs = [
    "out"
    "man"
    "info"
  ];

  meta = {
    homepage = "https://www.nano-editor.org/";
    description = "Small, user-friendly console text editor";
    longDescription = ''
      GNU nano is an easy-to-use text editor originally designed as a
      replacement for Pico, the ncurses-based editor from the non-free Pine
      e-mail client. GNU nano aims to emulate Pico while offering additional
      functionality and features, including syntax highlighting for various
      file types and the ability to rebind keys.
    '';
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.all;
    mainProgram = "nano";
    identifiers.cpeParts = {
      vendor = "gnu";
      product = "nano";
    };
  };
})
