{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  openssl,
  nix,
}:

stdenv.mkDerivation rec {
  pname = "s2n-tls";
  version = "1.7.9";

  src = fetchFromGitHub {
    owner = "aws";
    repo = "s2n-tls";
    rev = "v${version}";
    hash = "sha256-OGEqKjhl+gf8dq9ddIir+P4fUO+c9FGo/IsqDCCltqQ=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];

  outputs = [
    "out"
    "dev"
  ];

  buildInputs = [ openssl ]; # s2n-config has find_dependency(LibCrypto).

  cmakeEntries = {
    BUILD_SHARED_LIBS = true;
    UNSAFE_TREAT_WARNINGS_AS_ERRORS = false; # disable -Werror
    # See https://github.com/aws/s2n-tls/issues/1592 and https://github.com/aws/s2n-tls/pull/1609
    ${if stdenv.hostPlatform.isMips64 then "S2N_NO_PQ" else null} = true;
  };

  propagatedBuildInputs = [ openssl ]; # s2n-config has find_dependency(LibCrypto).

  postInstall = ''
    # Glob for 'shared' or 'static' subdir
    for f in $out/lib/s2n/cmake/*/s2n-targets.cmake; do
      substituteInPlace "$f" \
        --replace-fail 'INTERFACE_INCLUDE_DIRECTORIES "''${_IMPORT_PREFIX}/include"' 'INTERFACE_INCLUDE_DIRECTORIES ""'
    done
  '';

  # TODO(corepkgs): move to passthru
  doCheck = false;

  passthru.tests = {
    inherit nix;
  };

  meta = {
    description = "C99 implementation of the TLS/SSL protocols";
    homepage = "https://github.com/aws/s2n-tls";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "amazon" version;
  };
}
