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
  version = "8.7.1";

  src = fetchurl {
    url = "mirror://gnu/nano/nano-${finalAttrs.version}.tar.xz";
    hash = "sha256-dvDcskjy4vElHU7NIP0w+0AKNgo6N8bDQOClLC0c3t8=";
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
