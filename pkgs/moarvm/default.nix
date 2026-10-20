{
  fetchFromGitHub,
  lib,
  perl,
  pkg-config,
  stdenv,
  zstd,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "moarvm";
  version = "2026.09";

  src = fetchFromGitHub {
    owner = "MoarVM";
    repo = "MoarVM";
    tag = finalAttrs.version;
    fetchSubmodules = true;
    hash = "sha256-GOtqY/A70sMvJQWUahgASpcn45RrLGxXu2ydJwgxo5E=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ zstd ];

  postPatch = ''
    patchShebangs .
    substituteInPlace Configure.pl \
      --replace-fail 'my @check_tools = qw/ar cc ld/;' 'my @check_tools = ();'
  '';

  configureScript = "${lib.getExe perl} ./Configure.pl";
  configureFlags = [
    "--pkgconfig=${lib.getExe pkg-config}"
  ];

  meta = {
    description = "VM with adaptive optimization and JIT compilation, built for Rakudo";
    homepage = "https://moarvm.org";
    license = lib.licenses.artistic2;
    mainProgram = "moar";
    platforms = lib.platforms.unix;
  };
})
