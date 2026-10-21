# buildBunPackage — abstraction for the common two-derivation bun package pattern:
# a fixed-output node_modules derivation + a main derivation that copies them in,
# optionally builds, and installs.
#
# Usage: bun.buildPackage { pname = "foo"; version = "1.0"; src = ...; ... }
{
  lib,
  stdenv,
  stdenvNoCC,
  bun,
  makeWrapper,
}:

{
  pname,
  version,
  src,
  meta,
  node_modulesHash,
  installPhase,

  bunStdenv ? stdenv,
  bunInstallFlags ? [ ],
  bunBuildCommand ? null,
  node_modulesAttrs ? { },
  # "node_modules" copies only $fod/node_modules; "overlay" copies $fod/. over the source tree
  node_modulesCopyMode ? "node_modules",
  dontStrip ? false,
  nativeBuildInputs ? [ ],
  buildInputs ? [ ],
  passthru ? { },
  doInstallCheck ? true,
  nativeInstallCheckInputs ? [ ],
  ...
}@args:

let
  filteredArgs = builtins.removeAttrs args [
    "node_modulesHash"
    "bunInstallFlags"
    "bunBuildCommand"
    "node_modulesAttrs"
    "node_modulesCopyMode"
    "bunStdenv"
    "nativeBuildInputs"
    "passthru"
  ];

  node_modules = bunStdenv.mkDerivation (
    {
      pname = "${pname}-node_modules";
      inherit version src;

      nativeBuildInputs = [ bun ];

      dontConfigure = true;

      buildPhase = ''
        runHook preBuild
        export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
        bun install \
          --frozen-lockfile \
          --ignore-scripts \
          --no-progress \
          ${lib.concatStringsSep " \\\n      " bunInstallFlags}
        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out
        cp -r node_modules $out/node_modules
        cp package.json $out/
        [ -f bun.lock ] && cp bun.lock $out/ || true
        runHook postInstall
      '';

      dontFixup = true;
      outputHash = node_modulesHash;
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
    }
    // node_modulesAttrs
  );
in
bunStdenv.mkDerivation (
  filteredArgs
  // {
    nativeBuildInputs = [
      bun
      makeWrapper
    ]
    ++ nativeBuildInputs;

    dontConfigure = true;

    buildPhase =
      let
        copyCmd =
          if node_modulesCopyMode == "overlay" then
            "cp -rf ${node_modules}/. ."
          else
            "cp -r ${node_modules}/node_modules .";
      in
      ''
        runHook preBuild
        ${copyCmd}
        chmod -R u+w .
        ${lib.optionalString (bunBuildCommand != null) bunBuildCommand}
        runHook postBuild
      '';

    passthru = passthru // {
      inherit node_modules;
    };
  }
)
