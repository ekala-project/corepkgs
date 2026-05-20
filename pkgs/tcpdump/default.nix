{
  lib,
  stdenv,
  fetchurl,
  libpcap,
  openssl,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "tcpdump";
  version = "4.99.5";

  src = fetchurl {
    url = "https://www.tcpdump.org/release/tcpdump-${finalAttrs.version}.tar.gz";
    hash = "sha256-jHWFbgCt3urfcNrWfJ/z3TaFNrK4Vjq/aFTXx2TNOts=";
  };

  buildInputs = [
    libpcap
    openssl
  ];

  configureFlags = [
    "--with-crypto=${openssl}"
  ];

  outputs = [
    "out"
    "man"
  ];

  enableParallelBuilding = true;

  postInstall = ''
    # Remove unneeded files
    rm -f $out/sbin/tcpdump.${finalAttrs.version}
  '';

  meta = {
    homepage = "https://www.tcpdump.org/";
    description = "Network packet analyzer";
    longDescription = ''
      tcpdump is a powerful command-line packet analyzer. It allows the user to
      display TCP/IP and other packets being transmitted or received over a
      network to which the computer is attached.

      Distributed under the BSD license, tcpdump runs under most Unix-like
      operating systems.
    '';
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
    maintainers = [ ];
    mainProgram = "tcpdump";
  };
})
