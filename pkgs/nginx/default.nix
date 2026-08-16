{
  lib,
  stdenv,
  fetchurl,
  openssl,
  zlib,
  pcre2,
  libxml2,
  libxslt,
  perl,
  removeReferencesTo,
  installShellFiles,
  withDebug ? false,
  withStream ? true,
  withMail ? false,
  withPerl ? false,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "nginx";
  version = "1.30.4";

  src = fetchurl {
    url = "https://nginx.org/download/nginx-${finalAttrs.version}.tar.gz";
    hash = "sha256-QmHckOnkfBxAQSdumqo9SOvi5mT3KOFPqVrmxn1XoIs=";
  };

  nativeBuildInputs = [
    installShellFiles
    removeReferencesTo
  ];

  buildInputs = [
    openssl
    zlib
    pcre2
    libxml2
    libxslt
  ]
  ++ lib.optional withPerl perl;

  patches = [
    ./nix-etag-1.15.4.patch
    ./nix-skip-check-logs-path.patch
  ];

  postPatch = ''
    substituteInPlace src/http/ngx_http_core_module.c \
      --replace-fail '@nixStoreDir@' "$NIX_STORE" \
      --replace-fail '@nixStoreDirLen@' "''${#NIX_STORE}"
  '';

  configureFlags = [
    "--sbin-path=bin/nginx"
    "--with-http_ssl_module"
    "--with-http_v2_module"
    "--with-http_v3_module"
    "--with-http_realip_module"
    "--with-http_addition_module"
    "--with-http_xslt_module"
    "--with-http_sub_module"
    "--with-http_dav_module"
    "--with-http_flv_module"
    "--with-http_mp4_module"
    "--with-http_gunzip_module"
    "--with-http_gzip_static_module"
    "--with-http_auth_request_module"
    "--with-http_random_index_module"
    "--with-http_secure_link_module"
    "--with-http_degradation_module"
    "--with-http_stub_status_module"
    "--with-threads"
    "--with-pcre-jit"
    "--http-log-path=/var/log/nginx/access.log"
    "--error-log-path=/var/log/nginx/error.log"
    "--pid-path=/var/log/nginx/nginx.pid"
    "--http-client-body-temp-path=/tmp/nginx_client_body"
    "--http-proxy-temp-path=/tmp/nginx_proxy"
    "--http-fastcgi-temp-path=/tmp/nginx_fastcgi"
    "--http-uwsgi-temp-path=/tmp/nginx_uwsgi"
    "--http-scgi-temp-path=/tmp/nginx_scgi"
  ]
  ++ lib.optionals withDebug [ "--with-debug" ]
  ++ lib.optionals withStream [
    "--with-stream"
    "--with-stream_realip_module"
    "--with-stream_ssl_module"
    "--with-stream_ssl_preread_module"
  ]
  ++ lib.optionals withMail [
    "--with-mail"
    "--with-mail_ssl_module"
  ]
  ++ lib.optionals withPerl [
    "--with-http_perl_module"
    "--with-perl=${perl}/bin/perl"
    "--with-perl_modules_path=lib/perl5"
  ]
  ++ lib.optional stdenv.hostPlatform.isLinux "--with-file-aio";

  env.NIX_CFLAGS_COMPILE = toString (
    [
      "-I${libxml2.dev}/include/libxml2"
      "-Wno-error=implicit-fallthrough"
    ]
    ++ (
      if stdenv.cc.isGNU then
        [ "-Wno-error=discarded-qualifiers" ]
      else
        [ "-Wno-error=incompatible-pointer-types-discards-qualifiers" ]
    )
    ++ lib.optionals (stdenv.cc.isGNU && lib.versionAtLeast stdenv.cc.version "11") [
      "-Wno-error=stringop-overread"
    ]
    ++ lib.optionals stdenv.cc.isClang [
      "-Wno-error=deprecated-declarations"
      "-Wno-error=gnu-folding-constant"
      "-Wno-error=unused-but-set-variable"
    ]
  );

  configurePlatforms = [ ];

  # Disable _multioutConfig hook which adds --bindir=$out/bin into
  # configureFlags, which breaks the build since nginx does not use autoconf.
  preConfigure = ''
    setOutputFlags=
  '';

  enableParallelBuilding = true;

  preInstall = ''
    if [[ -e man/nginx.8 ]]; then
      installManPage man/nginx.8
    fi
  '';

  meta = {
    description = "Reverse proxy and lightweight webserver";
    mainProgram = "nginx";
    homepage = "https://nginx.org";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.unix;
    maintainers = [ ];
  };
})
