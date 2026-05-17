{
  version,
  src-hash,
  ...
}:

{
  lib,
  stdenv,
  fetchurl,
  autoconf,
  bison,
  flex,
  pkg-config,
  re2c,
  libxml2,
  openssl,
  curl,
  zlib,
  bzip2,
  libzip,
  readline,
  sqlite,
  oniguruma,
  pcre2,
  libsodium,
  callPackage,
}:

let
  majorVersion = lib.versions.major version;
  minorVersion = lib.versions.majorMinor version;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "php";
  inherit version;

  src = fetchurl {
    url = "https://www.php.net/distributions/php-${version}.tar.xz";
    hash = src-hash;
  };

  nativeBuildInputs = [
    autoconf
    bison
    flex
    pkg-config
    re2c
  ];

  buildInputs = [
    libxml2
    openssl
    curl
    zlib
    bzip2.out
    bzip2.dev
    libzip
    readline.dev
    sqlite
    oniguruma
    pcre2
    libsodium
  ];

  configureFlags = [
    "--with-config-file-scan-dir=/etc/php.d"
    "--with-openssl"
    "--with-zlib"
    "--with-bz2=${bzip2.dev}"
    "--with-curl"
    "--with-readline=${readline.dev}"
    "--with-zip"
    "--enable-mbstring"
    "--enable-bcmath"
    "--enable-calendar"
    "--enable-exif"
    "--enable-ftp"
    "--enable-sockets"
    "--enable-pcntl"
    "--enable-soap"
    "--with-pdo-mysql=mysqlnd"
    "--with-mysqli=mysqlnd"
    "--with-pdo-sqlite"
    "--with-sqlite3"
    "--with-sodium"
  ];

  enableParallelBuilding = true;

  postInstall = ''
    # Create php.ini-development and php.ini-production
    cp php.ini-development $out/etc/php.ini-development || true
    cp php.ini-production $out/etc/php.ini-production || true

    # Create default php.ini directory
    mkdir -p $out/etc/php.d
  '';

  passthru = {
    majorVersion = majorVersion;
    minorVersion = minorVersion;
    # Extension builder will be added later
    buildPecl = callPackage ./build-pecl.nix {
      php = finalAttrs.finalPackage;
    };
  };

  meta = {
    description = "PHP: Hypertext Preprocessor";
    homepage = "https://www.php.net/";
    changelog = "https://www.php.net/ChangeLog-${majorVersion}.php#PHP_${
      lib.replaceStrings [ "." ] [ "_" ] version
    }";
    license = lib.licenses.php301;
    platforms = lib.platforms.unix ++ lib.platforms.darwin;
    mainProgram = "php";
    maintainers = [ ];
  };
})
