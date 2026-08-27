{
  lib,
  stdenv,
  fetchFromGitHub,
  replaceVars,

  # runtime dependencies
  glibc,
  icu,
  libxml2,
  libuuid,
  lz4,
  openssl,
  readline,
  tzdata,
  zlib,
  zstd,

  # optional runtime dependencies
  linux-pam,
  libkrb5,
  systemdLibs,

  # build dependencies
  bison,
  docbook-xsl-nons,
  docbook-xml-dtd,
  flex,
  libxslt,
  makeBinaryWrapper,
  perl,
  pkg-config,
  removeReferencesTo,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "postgresql";
  version = "17.11";

  src = fetchFromGitHub {
    owner = "postgres";
    repo = "postgres";
    rev = "refs/tags/REL_17_11";
    hash = "sha256-pkVBg4Rxku3rEnNhPvVoAoab55vqrDqZfW1z+umealE=";
  };

  __structuredAttrs = true;

  outputs = [
    "out"
    "dev"
    "doc"
    "lib"
    "man"
  ];

  outputChecks = {
    out = {
      disallowedReferences = [
        "dev"
        "doc"
        "man"
      ];
    };
    lib = {
      disallowedReferences = [
        "out"
        "dev"
        "doc"
        "man"
      ];
    };
  };

  strictDeps = true;

  buildInputs = [
    zlib
    readline
    openssl
    libxml2
    libuuid
    icu
    lz4
    zstd
    systemdLibs
    libkrb5
    linux-pam
  ];

  nativeBuildInputs = [
    bison
    docbook-xsl-nons
    docbook-xml-dtd.v4_5
    flex
    libxml2
    libxslt
    makeBinaryWrapper
    perl
    pkg-config
    removeReferencesTo
  ];

  enableParallelBuilding = true;

  separateDebugInfo = true;

  buildFlags = [ "world" ];

  env = {
    CFLAGS = "-fdata-sections -ffunction-sections";
    NIX_CFLAGS_COMPILE = "-UUSE_PRIVATE_ENCODING_FUNCS";
    LDFLAGS = "-Wl,--gc-sections";
  };

  configureFlags = [
    "--with-openssl"
    "--with-libxml"
    "--with-icu"
    "--sysconfdir=/etc"
    "--with-system-tzdata=${tzdata}/share/zoneinfo"
    "--enable-debug"
    "--with-systemd"
    "--with-uuid=e2fs"
    "--with-lz4"
    "--with-zstd"
    "--with-gssapi"
    "--with-pam"
    "LDFLAGS_EX_BE=-Wl,--export-dynamic"
  ];

  patches = [
    ./patches/relative-to-symlinks-16+.patch
    ./patches/empty-pg-config-view-15+.patch
    ./patches/less-is-more.patch
    ./patches/paths-for-split-outputs.patch
    ./patches/paths-with-postgresql-suffix.patch

    (replaceVars ./patches/locale-binary-path.patch {
      locale = "${lib.getBin stdenv.cc.libc}/bin/locale";
    })

    ./patches/socketdir-in-run-13+.patch
  ];

  installTargets = [ "install-world" ];

  postPatch = ''
    substituteInPlace "src/Makefile.global.in" --subst-var out
    substituteInPlace "src/common/config_info.c" --subst-var dev
    cat ${./pg_config.env.mk} >> src/common/Makefile
  '';

  postInstall = ''
    moveToOutput "bin/ecpg" "$dev"
    moveToOutput "lib/pgxs" "$dev"

    mkdir -p "$dev/nix-support"
    "$out/bin/pg_config" > "$dev/nix-support/pg_config.expected"

    rm "$out/bin/pg_config"
    make -C src/common pg_config.env
    substituteInPlace src/common/pg_config.env \
      --replace-fail "$out" "@out@" \
      --replace-fail "$man" "@man@"
    install -D src/common/pg_config.env "$dev/nix-support/pg_config.env"

    # Remove references to -dev, -doc and -man from out binaries and libs
    find "$out" -type f -exec remove-references-to -t "$dev" -t "$doc" -t "$man" '{}' +

    # Remove references to -out, -dev, -doc and -man from lib output
    find "$lib" -type f -exec remove-references-to -t "$dev" -t "$out" -t "$doc" -t "$man" '{}' +

    if [ -z "''${dontDisableStatic:-}" ]; then
      # Remove static libraries in case dynamic are available.
      for i in $lib/lib/*.a; do
        name="$(basename "$i")"
        ext="${stdenv.hostPlatform.extensions.sharedLibrary}"
        if [ -e "$lib/lib/''${name%.a}$ext" ] || [ -e "''${i%.a}$ext" ]; then
          rm "$i"
        fi
      done
    fi

    # The remaining static libraries are libpgcommon.a, libpgport.a and related.
    # Those are only used when building e.g. extensions, so go to $dev.
    moveToOutput "lib/*.a" "$dev"
  '';

  postFixup = ''
    # initdb needs access to "locale" command from glibc.
    wrapProgram $out/bin/initdb --prefix PATH ":" ${glibc.bin}/bin
  '';

  passthru = {
    dlSuffix = stdenv.hostPlatform.extensions.sharedLibrary;
    psqlSchema = lib.versions.major finalAttrs.version;
  };

  meta = {
    homepage = "https://www.postgresql.org";
    description = "Powerful, open source object-relational database system";
    license = lib.licenses.postgresql;
    changelog = "https://www.postgresql.org/docs/release/${finalAttrs.version}/";
    platforms = lib.platforms.linux;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "postgresql" finalAttrs.version;
  };
})
