{
  lib,
  stdenv,
  fetchurl,
  unzip,
  tcl,
}:

let
  archiveVersion = import ../sqlite/archive-version.nix lib;
in

stdenv.mkDerivation rec {
  pname = "sqldiff";
  version = "3.50.4";

  # nixpkgs-update: no auto update
  src = fetchurl {
    url = "https://sqlite.org/2025/sqlite-src-${archiveVersion version}.zip";
    hash = "sha256-t7TcBg82BTkC+2WzRLu+1ZLmSyKRomrAb+d+7Al4UOk=";
  };

  nativeBuildInputs = [ unzip ];
  buildInputs = [ tcl ];

  makeFlags = [ "sqldiff" ];

  installPhase = "install -Dt $out/bin sqldiff";

  meta = {
    description = "Tool that displays the differences between SQLite databases";
    homepage = "https://www.sqlite.org/sqldiff.html";
    downloadPage = "http://sqlite.org/download.html";
    license = lib.licenses.publicDomain;
    mainProgram = "sqldiff";
    platforms = lib.platforms.unix;
  };
}
