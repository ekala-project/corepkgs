{
  lib,
  stdenv,
  fetchurl,
  fetchpatch,
  pkg-config,
  autoreconfHook,
  autoconf-archive,
  libestr,
  json_c,
  zlib,
  docutils,
  libfastjson,
  withLibyaml ? true,
  libyaml,
  withKrb5 ? true,
  libkrb5,
  withSystemd ? lib.meta.availableOn stdenv.hostPlatform systemd,
  systemd,
  withJemalloc ? true,
  jemalloc,
  withUuid ? true,
  libuuid,
  withCurl ? true,
  curl,
  withGnutls ? true,
  gnutls,
  withGcrypt ? true,
  libgcrypt,
  withLognorm ? true,
  liblognorm,
  withOpenssl ? true,
  openssl,
  withRelp ? true,
  librelp,
  withLogging ? true,
  liblogging,
  withNet ? true,
  libnet,
  withHiredis ? true,
  hiredis,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rsyslog";
  version = "8.2606.0";

  src = fetchurl {
    url = "https://www.rsyslog.com/files/download/rsyslog/rsyslog-${finalAttrs.version}.tar.gz";
    hash = "sha256-JXSz8waOaVXrlO9WQ+K2pbhYXMjqp3IJ/1y8Hi5fceU=";
  };

  patches = [
    # Remove with rsyslog 8.2608.0 or newer.
    (fetchpatch {
      name = "CVE-2026-19654.patch";
      url = "https://github.com/rsyslog/rsyslog/commit/f7f774228273730ba1075f4cd457ae78303a8f08.patch";
      hash = "sha256-ww8Ade2eKrQygJduLMPFjxd/fmBnpQ4ePLEzHffPy90=";
    })

    # Fix imjournal invalidation reopen busy-loop.
    # Remove with rsyslog 8.2608.0 or newer.
    # https://github.com/rsyslog/rsyslog/pull/7384
    (fetchpatch {
      name = "imjournal-invalidation-reopen-busy-loop.patch";
      url = "https://github.com/rsyslog/rsyslog/commit/383f80f21f16c3c94e7d7a57b0a5af12cdac9d75.patch";
      excludes = [ "ChangeLog" ];
      hash = "sha256-RlhXoK+dAPBN2wu4V7GoFw/d+uWQzO7+nUkW5+z7QJY=";
    })
  ];

  nativeBuildInputs = [
    pkg-config
    autoreconfHook
    autoconf-archive
    docutils
  ];

  buildInputs = [
    libfastjson
    libestr
    json_c
    zlib
  ]
  ++ lib.optional withLibyaml libyaml
  ++ lib.optional withKrb5 libkrb5
  ++ lib.optional withJemalloc jemalloc
  ++ lib.optional withUuid libuuid
  ++ lib.optional withCurl curl
  ++ lib.optional withGnutls gnutls
  ++ lib.optional withGcrypt libgcrypt
  ++ lib.optional withLognorm liblognorm
  ++ lib.optional withOpenssl openssl
  ++ lib.optional withRelp librelp
  ++ lib.optional withLogging liblogging
  ++ lib.optional withNet libnet
  ++ lib.optional withHiredis hiredis
  ++ lib.optional withSystemd systemd;

  configureFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    "--with-systemdsystemunitdir=\${out}/etc/systemd/system"
    (lib.enableFeature true "largefile")
    (lib.enableFeature true "regexp")
    (lib.enableFeature withLibyaml "libyaml")
    (lib.enableFeature withKrb5 "gssapi-krb5")
    (lib.enableFeature true "klog")
    (lib.enableFeature true "kmsg")
    (lib.enableFeature withSystemd "imjournal")
    (lib.enableFeature true "inet")
    (lib.enableFeature withJemalloc "jemalloc")
    (lib.enableFeature true "unlimited-select")
    (lib.enableFeature withCurl "clickhouse")
    (lib.enableFeature false "debug")
    (lib.enableFeature false "debug-symbols")
    (lib.enableFeature true "debugless")
    (lib.enableFeature false "valgrind")
    (lib.enableFeature false "diagtools")
    (lib.enableFeature withCurl "fmhttp")
    (lib.enableFeature true "usertools")
    (lib.enableFeature false "mysql") # TODO(corepkgs): Port libmysqlclient
    (lib.enableFeature false "pgsql") # TODO(corepkgs): Port libpq
    (lib.enableFeature false "libdbi") # TODO(corepkgs): Port libdbi
    (lib.enableFeature false "snmp") # TODO(corepkgs): Port net-snmp
    (lib.enableFeature withUuid "uuid")
    (lib.enableFeature withCurl "elasticsearch")
    (lib.enableFeature withGnutls "gnutls")
    (lib.enableFeature withGcrypt "libgcrypt")
    (lib.enableFeature true "rsyslogrt")
    (lib.enableFeature true "rsyslogd")
    (lib.enableFeature true "mail")
    (lib.enableFeature withLognorm "mmnormalize")
    (lib.enableFeature false "mmdblookup") # TODO(corepkgs): Port libmaxminddb
    (lib.enableFeature true "mmjsonparse")
    (lib.enableFeature true "mmaudit")
    (lib.enableFeature true "mmanon")
    (lib.enableFeature true "mmutf8fix")
    (lib.enableFeature true "mmcount")
    (lib.enableFeature true "mmsequence")
    (lib.enableFeature true "mmfields")
    (lib.enableFeature true "mmpstrucdata")
    (lib.enableFeature withOpenssl "mmrfc5424addhmac")
    (lib.enableFeature withRelp "relp")
    (lib.enableFeature false "ksi-ls12") # TODO(corepkgs): Port libksi
    (lib.enableFeature withLogging "liblogging-stdlog")
    (lib.enableFeature withLogging "rfc3195")
    (lib.enableFeature true "imfile")
    (lib.enableFeature false "imsolaris")
    (lib.enableFeature true "imptcp")
    (lib.enableFeature true "impstats")
    (lib.enableFeature false "impstats-push")
    (lib.enableFeature true "omprog")
    (lib.enableFeature withNet "omudpspoof")
    (lib.enableFeature true "omstdout")
    (lib.enableFeature withSystemd "omjournal")
    (lib.enableFeature true "pmlastmsg")
    (lib.enableFeature true "pmcisconames")
    (lib.enableFeature true "pmciscoios")
    (lib.enableFeature true "pmaixforwardedfrom")
    (lib.enableFeature true "pmsnare")
    (lib.enableFeature true "omruleset")
    (lib.enableFeature true "omuxsock")
    (lib.enableFeature true "mmsnmptrapd")
    (lib.enableFeature false "omhdfs") # TODO(corepkgs): Port hadoop
    (lib.enableFeature false "omkafka") # TODO(corepkgs): Port rdkafka
    (lib.enableFeature false "ommongodb") # TODO(corepkgs): Port mongoc
    (lib.enableFeature false "imczmq") # TODO(corepkgs): Port czmq
    (lib.enableFeature false "omczmq") # TODO(corepkgs): Port czmq
    (lib.enableFeature false "omrabbitmq") # TODO(corepkgs): Port rabbitmq-c
    (lib.enableFeature withHiredis "omhiredis")
    (lib.enableFeature withCurl "omhttp")
    (lib.enableFeature true "generate-man-pages")
  ];

  env.NIX_CFLAGS_LINK = "-lz";

  meta = {
    homepage = "https://www.rsyslog.com/";
    description = "Enhanced syslog implementation";
    mainProgram = "rsyslogd";
    changelog = "https://raw.githubusercontent.com/rsyslog/rsyslog/v${finalAttrs.version}/ChangeLog";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "rsyslog" finalAttrs.version;
  };
})
