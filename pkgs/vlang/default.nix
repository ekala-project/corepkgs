{
  lib,
  stdenv,
  fetchFromGitHub,
  glfw,
  freetype,
  openssl,
  makeWrapper,
  pkg-config,
  sqlite,
  upx,
  boehmgc,
  libxdmcp,
  libxau,
  libx11,
  xorgproto,
  binaryen,
}:

let
  version = "0.5.2";
  vc = stdenv.mkDerivation {
    pname = "v.c";
    version = "0.5.2";
    src = fetchFromGitHub {
      owner = "vlang";
      repo = "vc";
      rev = "7eb8c54a3843e5107d5af06d7a8c3e928f322475";
      hash = "sha256-Ca8RqMN2BwnwCfjvtGtFAl/qaoSLQTHGmhIk5FN3CO8=";
    };

    installPhase = ''
      mkdir -p $out
      cp v.c $out/
    '';
  };
  markdown = fetchFromGitHub {
    owner = "vlang";
    repo = "markdown";
    rev = "ef2f1018c37c1db6e379331b3cd841331b6a6fd2";
    hash = "sha256-drhDQYm7yiL+EDyslkTb0MGA9NQRrDLVg3IElwXAIIY=";
  };
  boehmgcStatic = boehmgc.override {
    enableStatic = true;
  };
in

stdenv.mkDerivation {
  pname = "vlang";
  inherit version;

  src = fetchFromGitHub {
    owner = "vlang";
    repo = "v";
    rev = version;
    hash = "sha256-0PInqMmb4sNzJwVD9SMhTXzvxMdaC1uIJl7fpdXKESE=";
  };

  propagatedBuildInputs = [
    glfw
    freetype
    openssl
    sqlite
  ]
  ++ lib.optional stdenv.hostPlatform.isUnix upx;

  nativeBuildInputs = [
    makeWrapper
    pkg-config
  ];

  buildInputs = [
    binaryen
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    libx11
    libxau
    libxdmcp
    xorgproto
  ];

  makeFlags = [
    "local=1"
  ];

  env.VC = vc;

  preBuild = ''
    export HOME=$(mktemp -d)
    mkdir -p ./thirdparty/tcc/lib
    cp -r ${boehmgcStatic}/lib/* ./thirdparty/tcc/lib
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib,share}
    cp -r examples $out/share
    cp -r {cmd,vlib,thirdparty} $out/lib
    cp v v.mod $out/lib
    ln -s $out/lib/v $out/bin/v
    wrapProgram $out/bin/v \
      --prefix PATH : ${
        lib.makeBinPath [
          stdenv.cc
          pkg-config
        ]
      } \
      --prefix PKG_CONFIG_PATH : ${lib.getDev sqlite}/lib/pkgconfig

    rm $out/lib/cmd/tools/gen_vc.v

    mkdir -p $HOME/.vmodules;
    ln -sf ${markdown} $HOME/.vmodules/markdown
    $out/lib/v -v build-tools
    $out/lib/v -v $out/lib/cmd/tools/vdoc
    $out/lib/v -v $out/lib/cmd/tools/vast
    $out/lib/v -v $out/lib/cmd/tools/vvet
    $out/lib/v -v $out/lib/cmd/tools/vcreate

    runHook postInstall
  '';

  meta = {
    homepage = "https://vlang.io/";
    description = "Simple, fast, safe, compiled language for developing maintainable software";
    license = lib.licenses.mit;
    mainProgram = "v";
    platforms = lib.platforms.all;
  };
}
