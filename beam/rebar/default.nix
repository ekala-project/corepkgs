{
  lib,
  stdenv,
  fetchFromGitHub,
  erlang,
}:

stdenv.mkDerivation rec {
  pname = "rebar";
  version = "2.6.4";

  src = fetchFromGitHub {
    owner = "rebar";
    repo = "rebar";
    rev = version;
    sha256 = "sha256-okvG7X2uHtZ1p+HUoFOmslrWvYjk0QWBAvAMAW2E40c=";
  };

  nativeBuildInputs = [ erlang ];
  buildInputs = [ erlang ];

  buildPhase = "escript bootstrap";
  installPhase = ''
    mkdir -p $out/bin
    cp rebar $out/bin/rebar
  '';

  meta = {
    homepage = "https://github.com/rebar/rebar";
    description = "Erlang build tool that makes it easy to compile and test Erlang applications, port drivers and releases";
    mainProgram = "rebar";
    platforms = lib.platforms.unix;
    license = lib.licenses.asl20;
  };
}
