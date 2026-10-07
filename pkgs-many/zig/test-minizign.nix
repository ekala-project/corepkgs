{
  lib,
  stdenv,
  fetchFromGitHub,
  zig,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "minizign";
  version = "0.1.13";

  src = fetchFromGitHub {
    owner = "jedisct1";
    repo = "zig-minisign";
    tag = finalAttrs.version;
    hash = "sha256-qGOGcpmmPPMN9Tm7k31aBXnbouPWXg69KjZLFLNPldo=";
  };

  nativeBuildInputs = [ zig.hook ];

  zigDeps = zig.fetchDeps {
    inherit (finalAttrs) src pname version;
    fetchAll = true;
    hash = "sha256-/ylcSBv+oPW+mcWO7ArPAR2rp1GGpmW0ajIlsQWcTJw=";
  };

  postConfigure = ''
    ln -s ${finalAttrs.zigDeps} "$ZIG_GLOBAL_CACHE_DIR/p"
  '';

  meta = {
    description = "Minisign reimplemented in Zig";
    homepage = "https://github.com/jedisct1/zig-minisign";
    license = lib.licenses.isc;
    mainProgram = "minizign";
    inherit (zig.meta) platforms;
  };
})
