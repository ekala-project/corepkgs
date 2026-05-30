{
  stdenv,
  go,
  # TODO: docker missing - needs docker.moby-src for tarsum implementation
  docker ? null,
}:

assert docker != null -> docker ? moby-src;

stdenv.mkDerivation {
  name = "tarsum";

  nativeBuildInputs = [ go ];
  disallowedReferences = [ go ];

  dontUnpack = true;

  env = {
    CGO_ENABLED = 0;
    GOFLAGS = "-trimpath";
    GO111MODULE = "off";
  };

  buildPhase = ''
    runHook preBuild
    mkdir tarsum
    cd tarsum
    cp ${./tarsum.go} tarsum.go
    export GOPATH=$(pwd)
    export GOCACHE="$TMPDIR/go-cache"
    mkdir -p src/github.com/docker/docker/daemon/builder/remotecontext
    # We need to drop the internal as otherwise go refuses to use it.
    ${
      if docker != null then
        ''
          ln -sT ${docker.moby-src}/daemon/builder/remotecontext/internal/tarsum src/github.com/docker/docker/daemon/builder/remotecontext/tarsum
        ''
      else
        ''
          echo "ERROR: docker.moby-src is required to build tarsum" >&2
          exit 1
        ''
    }
    go build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp tarsum $out/bin/
    runHook postInstall
  '';

  # Tests removed - nixosTests not available in core-pkgs
  passthru.tests = { };

  meta = {
    platforms = go.meta.platforms;
    mainProgram = "tarsum";
    maintainers = [ ];
  };
}
