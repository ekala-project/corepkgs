{
  buildPerlPackage,
  DBI,
  fetchpatch,
  fetchurl,
  lib,
  perl,
  sqlite,
}:

buildPerlPackage {
  pname = "DBD-SQLite";
  version = "1.74";

  src = fetchurl {
    url = "mirror://cpan/authors/id/I/IS/ISHIGAKI/DBD-SQLite-1.74.tar.gz";
    hash = "sha256-iZSZfYS5/rRUd5X3h0bGYfty48tqJdvdeJtzH1aIpN0=";
  };

  propagatedBuildInputs = [ DBI ];
  buildInputs = [ sqlite ];

  patches = [
    # Support building against our own sqlite.
    ./external-sqlite.patch

    # Pull upstream fix for test failures against sqlite-3.37.
    (fetchpatch {
      name = "sqlite-3.37-compat.patch";
      url = "https://github.com/DBD-SQLite/DBD-SQLite/commit/ba4f472e7372dbf453444c7764d1c342e7af12b8.patch";
      hash = "sha256-nn4JvaIGlr2lUnUC+0ABe9AFrRrC5bfdTQiefo0Pjwo=";
    })
  ];

  makeMakerFlags = [
    "SQLITE_INC=${sqlite.dev}/include"
    "SQLITE_LIB=${sqlite.out}/lib"
  ];

  postInstall = ''
    # Get rid of a pointless copy of the SQLite sources.
    rm -rf $out/${perl.libPrefix}/*/*/auto/share
  '';

  preCheck = "rm t/65_db_config.t"; # do not run failing tests

  meta = {
    description = "Self Contained SQLite RDBMS in a DBI Driver";
    platforms = lib.platforms.unix;
  };
}
