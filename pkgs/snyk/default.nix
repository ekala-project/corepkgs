{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  testers,
  snyk,
}:

let
  version = "1.1301.2";
in
stdenvNoCC.mkDerivation {
  pname = "snyk";
  inherit version;

  src =
    let
      sources = {
        "x86_64-linux" = fetchurl {
          url = "https://downloads.snyk.io/cli/v${version}/snyk-linux";
          hash = "sha256-G2oMuFMCDG7Ve7HV/FtMCN10i4IwaNswDzs5nu18YU4=";
        };
        "aarch64-linux" = fetchurl {
          url = "https://downloads.snyk.io/cli/v${version}/snyk-linux-arm64";
          hash = "sha256-hCN88Bbuf9/xg6DXpY6GPjdlr4voTL6e2e7m6GnvpHY=";
        };
        "x86_64-darwin" = fetchurl {
          url = "https://downloads.snyk.io/cli/v${version}/snyk-macos";
          hash = "sha256-kfvGg2LWySIhe+ce6u8yLAtOJg/GYLaWivr5AGjYfbY=";
        };
        "aarch64-darwin" = fetchurl {
          url = "https://downloads.snyk.io/cli/v${version}/snyk-macos-arm64";
          hash = "sha256-rWYELWYrdPBq4OQi8HMhSW6lNjWF6FAYpcfHaxe3ET0=";
        };
      };
    in
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "Unsupported system: ${stdenvNoCC.hostPlatform.system}");

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [
    autoPatchelfHook
  ];

  installPhase = ''
    runHook preInstall

    install -Dm 755 $src $out/bin/snyk

    runHook postInstall
  '';

  passthru.tests.version = testers.testVersion {
    package = snyk;
  };

  meta = {
    description = "Scans and monitors projects for security vulnerabilities";
    homepage = "https://snyk.io";
    changelog = "https://github.com/snyk/cli/releases/tag/v${version}";
    license = lib.licenses.asl20;
    maintainers = [ ];
    mainProgram = "snyk";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
