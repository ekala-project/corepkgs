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
  pname = "sqlite-rsync";
  version = "3.50.4";

  # nixpkgs-update: no auto update
  src = fetchurl {
    url = "https://sqlite.org/2025/sqlite-src-${archiveVersion version}.zip";
    hash = "sha256-t7TcBg82BTkC+2WzRLu+1ZLmSyKRomrAb+d+7Al4UOk=";
  };

  nativeBuildInputs = [ unzip ];
  buildInputs = [ tcl ];

  makeFlags = [ "sqlite3_rsync" ];

  installPhase = "install -Dt $out/bin sqlite3_rsync";

  meta = {
    description = "Database remote-copy tool for SQLite";
    homepage = "https://www.sqlite.org/rsync.html";
    downloadPage = "http://sqlite.org/download.html";
    license = lib.licenses.publicDomain;
    mainProgram = "sqlite3_rsync";
    platforms = lib.platforms.unix;
  };
}
