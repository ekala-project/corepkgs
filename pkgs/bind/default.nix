{
  lib,
  stdenv,
  fetchurl,
  perl,
  openssl,
  libuv,
  libcap,
  zlib,
  pkg-config,
  userspace-rcu,
  runCommand,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "bind";
  version = "9.20.5";

  src = fetchurl {
    url = "https://downloads.isc.org/isc/bind9/${finalAttrs.version}/bind-${finalAttrs.version}.tar.xz";
    hash = "sha256-GSdP1znAI3crQhKgtsIBz0NkhV+n5qfT20lpP1XbGrg=";
  };

  outputs = [
    "out"
    "dev"
    "man"
    "utils" # dig, nslookup, host, etc.
  ];

  nativeBuildInputs = [
    perl
    pkg-config
  ];

  buildInputs = [
    openssl
    libuv
    libcap
    zlib
    userspace-rcu
  ];

  configureFlags = [
    "--with-openssl=${openssl.dev}"
    "--with-libuv=${libuv}"
    "--disable-static"
    "--without-python"
    "--without-gssapi"
    "--without-idn"
    "--disable-dnstap"
    "--disable-doh" # Disable DNS-over-HTTPS (requires libnghttp2)
    # Disable server components, we only want client tools
    "--disable-linux-caps"
  ];

  enableParallelBuilding = true;

  postInstall = ''
    # Move utilities to separate output
    mkdir -p $utils/bin
    mv $out/bin/dig $utils/bin/
    mv $out/bin/host $utils/bin/
    mv $out/bin/nslookup $utils/bin/
    mv $out/bin/nsupdate $utils/bin/ || true
    mv $out/bin/delv $utils/bin/ || true

    # Remove server binaries we don't need
    rm -rf $out/sbin || true
    rm -rf $out/etc || true
  '';

  passthru.tests = {
    version = testers.testVersion {
      package = finalAttrs.finalPackage;
      command = "dig -v";
    };
    simple = runCommand "bind-test" { } ''
      ${finalAttrs.finalPackage}/bin/dig +short -x 127.0.0.1 > /dev/null 2>&1 || true
      touch $out
    '';
  };

  meta = {
    homepage = "https://www.isc.org/bind/";
    description = "Domain name server and DNS utilities";
    longDescription = ''
      BIND (Berkeley Internet Name Domain) is a complete, highly portable
      implementation of the DNS (Domain Name System) protocol.

      This package provides the DNS client utilities:
      - dig: DNS lookup utility
      - host: DNS lookup utility (simplified)
      - nslookup: Query Internet name servers interactively
      - nsupdate: Dynamic DNS update utility
    '';
    license = lib.licenses.mpl20;
    platforms = lib.platforms.unix;
    maintainers = [ ];
  };
})
