{
  lib,
  stdenv,
  fetchurl,
  bison,
  cmake,
  pkg-config,
  icu,
  libedit,
  libevent,
  lz4,
  ncurses,
  openssl,
  re2,
  readline,
  zlib,
  zstd,
  numactl,
  curl,
}:

let
  common = finalAttrs: {

    version = "8.4.11";

    src = fetchurl {
      url = "https://dev.mysql.com/get/Downloads/MySQL-${lib.versions.majorMinor finalAttrs.version}/mysql-${finalAttrs.version}.tar.gz";
      hash = "sha256-6zBRFk1iXdNGqCA/duDV1dmuxR2+nVF4jjnsaz8TlMI=";
    };

    patches = [
      ./no-force-outline-atomics.patch
    ];

    postPatch = ''
      substituteInPlace cmake/libutils.cmake --replace /usr/bin/libtool libtool
      substituteInPlace cmake/os/Darwin.cmake --replace /usr/bin/libtool libtool
    '';

    nativeBuildInputs = [
      bison
      cmake
      cmake.configurePhaseHook
      pkg-config
      # TODO(corepkgs): Port rpcsvc-proto for NIS support
    ];

    buildInputs = [
      (curl.override { inherit openssl; })
      icu
      libedit
      libevent
      lz4
      ncurses
      openssl
      re2
      readline
      zlib
      zstd
      # TODO(corepkgs): Port protobuf_21 (MySQL 8.4 requires protobuf 3.21, not newer versions)
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      numactl
      # TODO(corepkgs): Port libtirpc for NIS/RPC support
    ];

    outputs = [
      "out"
      "static"
      "man"
    ];

    cmakeFlags = [
      "-DFORCE_UNSUPPORTED_COMPILER=1"
      "-DWITH_ROUTER=OFF"
      "-DWITH_SYSTEM_LIBS=ON"
      "-DWITH_PROTOBUF=bundled"
      "-DWITH_TIRPC=bundled"
      "-DWITHOUT_GROUP_REPLICATION=1" # requires rpcgen from rpcsvc-proto
      "-DWITH_UNIT_TESTS=OFF"
      "-DMYSQL_UNIX_ADDR=/run/mysqld/mysqld.sock"
      "-DMYSQL_DATADIR=/var/lib/mysql"
      "-DINSTALL_INFODIR=share/mysql/docs"
      "-DINSTALL_MANDIR=share/man"
      "-DINSTALL_PLUGINDIR=lib/mysql/plugin"
      "-DINSTALL_INCLUDEDIR=include/mysql"
      "-DINSTALL_DOCREADMEDIR=share/mysql"
      "-DINSTALL_SUPPORTFILESDIR=share/mysql"
      "-DINSTALL_MYSQLSHAREDIR=share/mysql"
      "-DINSTALL_MYSQLTESTDIR="
      "-DINSTALL_DOCDIR=share/mysql/docs"
      "-DINSTALL_SHAREDIR=share/mysql"
    ];

    cmakeBuildType = "Release";

    postInstall = ''
      moveToOutput "lib/*.a" $static
      so=${stdenv.hostPlatform.extensions.sharedLibrary}
      ln -s libmysqlclient$so $out/lib/libmysqlclient_r$so
    '';

    passthru = {
      mysqlVersion = lib.versions.majorMinor finalAttrs.version;
    };

    meta = {
      homepage = "https://www.mysql.com/";
      description = "World's most popular open source database";
      license = lib.licenses.gpl2;
      maintainers = [ ];
      platforms = lib.platforms.unix;
    };
  };
  client = stdenv.mkDerivation (
    finalAttrs:
    let
      common' = common finalAttrs;
    in
    common'
    // {
      pname = "mysql-client";

      cmakeFlags = common'.cmakeFlags ++ [
        "-DWITHOUT_SERVER=ON"
        "-DINSTALL_MYSQLSHAREDIR=share/mysql-client"
      ];
      meta = common'.meta // {
        mainProgram = "mysql";
      };
    }
  );
in

stdenv.mkDerivation (
  finalAttrs:
  let
    common' = common finalAttrs;
  in
  common'
  // {
    pname = "mysql";

    meta = common'.meta // {
      mainProgram = "mysqld";
    };

    passthru = lib.recursiveUpdate common'.passthru {
      inherit client;
      connector-c = client;
      server = finalAttrs.finalPackage;
    };
  }
)
