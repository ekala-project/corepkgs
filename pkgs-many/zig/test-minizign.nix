{
  lib,
  fetchFromGitHub,
  zig,
}:

zig.buildZigPackage (finalAttrs: {
  pname = "minizign";
  version = "0.1.13";

  src = fetchFromGitHub {
    owner = "jedisct1";
    repo = "zig-minisign";
    tag = finalAttrs.version;
    hash = "sha256-qGOGcpmmPPMN9Tm7k31aBXnbouPWXg69KjZLFLNPldo=";
  };

  zigHash = "sha256-/ylcSBv+oPW+mcWO7ArPAR2rp1GGpmW0ajIlsQWcTJw=";

  meta = {
    description = "Minisign reimplemented in Zig";
    homepage = "https://github.com/jedisct1/zig-minisign";
    license = lib.licenses.isc;
    mainProgram = "minizign";
  };
})
