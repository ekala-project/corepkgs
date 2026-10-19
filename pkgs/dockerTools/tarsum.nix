{
  fetchFromGitHub,
  stdenv,
  go,
}:

let
  version = "29.8.0";
  moby-src = fetchFromGitHub {
    owner = "moby";
    repo = "moby";
    tag = "docker-v${version}";
    hash = "sha256-V8p+MDEEMERGqQ9sWKPE/jkUw43UcO0x3Z1XZ8DWM2E=";
  };
in

stdenv.mkDerivation {
  pname = "tarsum";
  inherit version;

  nativeBuildInputs = [ go ];
  disallowedReferences = [ go ];

  dontUnpack = true;

  env = {
    CGO_ENABLED = 0;
    GOFLAGS = "-trimpath";
    GO111MODULE = "off";
  };

  buildPhase = ''
    mkdir tarsum
    cd tarsum
    cp ${./tarsum.go} tarsum.go
    export GOPATH=$(pwd)
    export GOCACHE="$TMPDIR/go-cache"
    mkdir -p src/github.com/docker/docker/daemon/builder/remotecontext
    # We need to drop the internal as otherwise go refuses to use it.
    ln -sT ${moby-src}/daemon/builder/remotecontext/internal/tarsum src/github.com/docker/docker/daemon/builder/remotecontext/tarsum
    go build
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp tarsum $out/bin/
  '';

  meta.platforms = go.meta.platforms;
  meta.mainProgram = "tarsum";
}
