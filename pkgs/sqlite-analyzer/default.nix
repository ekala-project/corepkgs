{
  lib,
  stdenv,
  fetchurl,
  unzip,
  tcl,
  sqlite,
}:

let
  inherit (sqlite) archiveVersion;
in

stdenv.mkDerivation (finalAttrs: {
  pname = "sqlite-analyzer";
  version = "3.50.4";

  # nixpkgs-update: no auto update
  src = fetchurl {
    url = "https://sqlite.org/2025/sqlite-src-${archiveVersion finalAttrs.version}.zip";
    hash = "sha256-t7TcBg82BTkC+2WzRLu+1ZLmSyKRomrAb+d+7Al4UOk=";
  };

  nativeBuildInputs = [ unzip ];
  buildInputs = [ tcl ];

  configureFlags = [ "--with-tcl=${lib.getLib tcl}/lib" ];

  makeFlags = [ "sqlite3_analyzer" ];

  installPhase = "install -Dt $out/bin sqlite3_analyzer";

  meta = {
    description = "Tool that shows statistics about SQLite databases";
    homepage = "https://www.sqlite.org/sqlanalyze.html";
    downloadPage = "http://sqlite.org/download.html";
    license = lib.licenses.publicDomain;
    mainProgram = "sqlite3_analyzer";
    platforms = lib.platforms.unix;
  };
})
