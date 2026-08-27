{
  lib,
  stdenv,
  fetchurl,
  versionCheckHook,
  libpcap,
  pkg-config,
  openssl,
  lua5_4,
  pcre2,
  libssh2,
  zlib,
  withLua ? true,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "nmap";
  version = "7.991";

  src = fetchurl {
    url = "https://nmap.org/dist/nmap-${finalAttrs.version}.tar.bz2";
    hash = "sha256-pdUH8pQ3vvO+3Udx/5qqj8HCoQnduh9bHPEgJ0VpKb4=";
  };

  configureFlags = [
    (if withLua then "--with-liblua=${lua5_4}" else "--without-liblua")
    "--without-ndiff"
    "--without-zenmap"
    "--without-nping"
  ];

  postInstall = ''
    install -m 444 -D nselib/data/passwords.lst $out/share/wordlists/nmap.lst
  '';

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    pcre2
    libssh2
    libpcap
    openssl
    zlib
    # TODO(corepkgs): Port liblinear for machine learning OS detection
  ];

  enableParallelBuilding = true;

  nativeInstallCheckInputs = [
    versionCheckHook
  ];
  versionCheckProgramArg = "-V";
  doInstallCheck = true;

  meta = {
    description = "Free and open source utility for network discovery and security auditing";
    homepage = "http://www.nmap.org";
    changelog = "https://nmap.org/changelog.html#${finalAttrs.version}";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.all;
    mainProgram = "nmap";
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "nmap" finalAttrs.version;
  };
})
