{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  cmake,
  curl,
  openssl,
  zlib-ng-compat,
  zstd,
  libiconv,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "mariadb-connector-c";
  version = "3.3.5";

  src = fetchFromGitHub {
    owner = "mariadb-corporation";
    repo = "mariadb-connector-c";
    tag = "v${finalAttrs.version}";
    hash = "sha256-RLHx8PyfbfIDr6X6ky5/w0XsGMFd+v5PgmQHvYOaf+k=";
  };

  patches = [
    # fix compilation against gcc15
    (fetchpatch {
      url = "https://github.com/mariadb-corporation/mariadb-connector-c/commit/e8448137f3365568090d5c0d4051039ddc1cdb6f.patch";
      hash = "sha256-aDbaaJA8DxGG5RrOa+CHhk4wuzlBy5tWyS+f/zVYU0c=";
    })

    # Fix the build with CMake 4.
    (fetchpatch {
      name = "mariadb-connector-c-fix-cmake-4.patch";
      url = "https://github.com/mariadb-corporation/mariadb-connector-c/commit/598dc3d2d7a63e5d250421dd0ea88be55ea8511f.patch";
      hash = "sha256-HojNRobguBmtpEdr2lVi/MpcoDAsZnb3+tw/pt376es=";
    })
  ];

  outputs = [
    "out"
    "dev"
  ];

  postPatch = ''
    substituteInPlace mariadb_config/mariadb_config.c.in \
      --replace-fail '#define INCLUDE "-I%s/@INSTALL_INCLUDEDIR@ -I%s/@INSTALL_INCLUDEDIR@/mysql"' "#define INCLUDE \"-I$dev/include -I$dev/include/mysql\"" \
      --replace-fail '#define LIBS    "-L%s/@INSTALL_LIBDIR@/ -lmariadb"' "#define LIBS    \"-L$out/lib/mariadb -lmariadb\"" \
      --replace-fail '#define PKG_LIBDIR "%s/@INSTALL_LIBDIR@"' "#define PKG_LIBDIR \"$out/lib/mariadb\"" \
      --replace-fail '#define PLUGIN_DIR "%s/@INSTALL_PLUGINDIR@"' "#define PLUGIN_DIR \"$out/lib/mariadb/plugin\"" \
      --replace-fail '#define PKG_PLUGINDIR "%s/@INSTALL_PLUGINDIR@"' "#define PKG_PLUGINDIR \"$out/lib/mariadb/plugin\""
  ''
  + lib.optionalString stdenv.hostPlatform.isStatic ''
    # Disables all dynamic plugins
    substituteInPlace cmake/plugins.cmake \
      --replace-fail 'if(''${CC_PLUGIN_DEFAULT} STREQUAL "DYNAMIC")' 'if(''${CC_PLUGIN_DEFAULT} STREQUAL "INVALID")'
    # Force building static libraries
    substituteInPlace libmariadb/CMakeLists.txt \
      --replace-fail 'libmariadb SHARED' 'libmariadb STATIC'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  # `libmariadb.pc`'s Libs.private and `mariadb_config --libs_sys` both emit a
  # bare `-lssl -lcrypto -lz` with no `-L`, so consumers that static-link or
  # paste that output into their link line need these in scope. curl and zstd
  # appear in neither: only the dlopen'd plugins use them, via our own RPATH.
  propagatedBuildInputs = [
    openssl
    zlib-ng-compat
  ];

  buildInputs = [
    curl
    libiconv
    zstd
  ];

  cmakeFlags = [
    "-DMARIADB_UNIX_ADDR=/run/mysqld/mysqld.sock"
    "-DWITH_CURL=ON"
    "-DWITH_EXTERNAL_ZLIB=ON"
    "-DWITH_MYSQLCOMPAT=ON"
  ];

  postInstall = ''
    moveToOutput bin/mariadb_config "$dev"
  '';

  # The connector installs everything under a `mariadb` subdirectory; the
  # symlinks and the copied `my_config.h` are what makes it drop-in compatible
  # with MySQL's own client library, which is why this is `libmysqlclient`.
  postFixup = ''
    ln -sv mariadb_config $dev/bin/mysql_config
    ln -sv mariadb $out/lib/mysql
    ln -sv mariadb $dev/include/mysql
    ln -sv mariadb_version.h $dev/include/mariadb/mysql_version.h
    ln -sv libmariadb.pc $dev/lib/pkgconfig/mysqlclient.pc
    install -Dm644 include/ma_config.h $dev/include/mariadb/my_config.h
  '';

  meta = {
    description = "Client library that can be used to connect to MySQL or MariaDB";
    homepage = "https://github.com/mariadb-corporation/mariadb-connector-c";
    license = lib.licenses.lgpl21Plus;
    platforms = lib.platforms.all;
  };
})
