{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  zstd,
  callPackage,
}:

let
  # argv[0] selects ec's mode, so each mode and each compiler name ec
  # recognises gets a symlink back to bin/ec under libexec/ekacache.
  modes = [
    "cache"
    "slot"
    "rustcwrap"
    "gocacheprog"
    "reloc-fixup"
    "nix-store"
  ];
  compilers = [
    "cc"
    "c++"
    "gcc"
    "g++"
    "clang"
    "clang++"
    "gfortran"
  ];
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ekacache";
  version = "0.2.0-unstable-2026-11-19";

  src = fetchFromGitHub {
    owner = "ekala-project";
    repo = "jig";
    rev = "ecc8334f4028ff046bcddfb7c137b4b36f528514";
    hash = "sha256-eF2XqpQah9l0b7l5CCVr48A69saBV35xC/6DkY/VucA=";
  };

  cargoHash = "sha256-EaHPt7NhSqk3qIfb99YiuCTaO44AgUFzvcwh0SRRbwk=";

  outputs = [
    "out"
    "ekacached"
  ];

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ zstd ];

  # ec only serves files under this store and derives its default socket,
  # /nix/var/nix/ekacache/socket, from it. It is fixed at build time.
  env.EKACACHE_STORE_DIR = builtins.storeDir;

  cargoBuildFlags = [
    "-p"
    "ekacache"
    "-p"
    "ekacached"
  ];

  postInstall = ''
    moveToOutput bin/ecd "$ekacached"
    mkdir -p "$out/libexec/ekacache"
    for name in ${lib.escapeShellArgs (modes ++ compilers)}; do
      ln -s ../../bin/ec "$out/libexec/ekacache/$name"
    done
  '';

  passthru = {
    inherit modes compilers;
    # ec talks to ecd over this socket; it is the in-sandbox path builds see
    # once the host maps /nix/var/nix/ekacache into the sandbox.
    socket = "${dirOf builtins.storeDir}/var/nix/ekacache/socket";
    tests = callPackage ./tests.nix { ekacache = finalAttrs.finalPackage; };
  };

  meta = {
    description = "Compile cache for Nix builds (ec) and its per-machine daemon (ecd)";
    homepage = "https://github.com/ekala-project/jig";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    mainProgram = "ec";
  };
})
