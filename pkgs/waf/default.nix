{
  lib,
  stdenv,
  fetchFromGitLab,
  callPackage,
  ensureNewerSourcesForZipFilesHook,
  python3,
  makeWrapper,
  extraTools ? [ ],
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "waf";
  version = "2.1.9";

  src = fetchFromGitLab {
    owner = "ita1024";
    repo = "waf";
    rev = "waf-${finalAttrs.version}";
    hash = "sha256-myPGbJW/RkOtEas+qZ/vTL66bekwDBPhC6AmfXECkcw=";
  };

  nativeBuildInputs = [
    ensureNewerSourcesForZipFilesHook
    python3
    makeWrapper
  ];

  buildInputs = [
    python3
  ];

  strictDeps = true;

  configurePhase = ''

    python waf-light configure

  '';

  buildPhase =
    let
      extraToolsList = lib.optionalString (
        extraTools != [ ]
      ) "--tools=\"${lib.concatStringsSep "," extraTools}\"";
    in
    ''

      python waf-light build ${extraToolsList}

      substituteInPlace waf \
        --replace "w = test(i + '/lib/' + dirname)" \
                  "w = test('$out/${python3.sitePackages}')"

    '';

  installPhase = ''

    install -D waf "$out"/bin/waf
    wrapProgram "$out"/bin/waf --prefix PYTHONPATH : "$out"/${python3.sitePackages}
    mkdir -p "$out"/${python3.sitePackages}/
    cp -r waflib "$out"/${python3.sitePackages}/

  '';

  passthru = {
    inherit python3 extraTools;
    hook = callPackage ./hook.nix {
      waf = finalAttrs.finalPackage;
    };
  };

  meta = {
    homepage = "https://waf.io";
    description = "Meta build system";
    changelog = "https://gitlab.com/ita1024/waf/blob/waf-${finalAttrs.version}/ChangeLog";
    license = lib.licenses.bsd3;
    mainProgram = "waf";
    inherit (python3.meta) platforms;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
