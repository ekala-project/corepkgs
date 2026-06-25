{
  lib,
  stdenv,
  nodejs,
  pnpm,
  pnpmConfigHook,
  fetchPnpmDeps,
  makeWrapper,
}:

let
  defaultPnpm = pnpm;
in

{
  pname,
  version,
  src,
  # pnpm dependency management — provide pnpmDeps directly, or pnpmDepsHash to auto-compute
  pnpmDeps ? null,
  pnpmDepsHash ? "",
  pnpm ? defaultPnpm,
  fetcherVersion ? 3,
  pnpmWorkspaces ? [ ],
  pnpmInstallFlags ? [ ],
  pnpmRoot ? null,
  # build control
  pnpmBuildScript ? "build",
  pnpmBuildFlags ? [ ],
  dontPnpmBuild ? false,
  # install control
  dontPnpmInstall ? false,
  pnpmPackName ? pname,
  # standard mkDerivation args
  nativeBuildInputs ? [ ],
  buildInputs ? [ ],
  ...
}@args:

let
  pnpmDeps' =
    if args.pnpmDeps or null != null then
      args.pnpmDeps
    else
      fetchPnpmDeps {
        inherit
          pname
          version
          src
          pnpm
          fetcherVersion
          pnpmWorkspaces
          pnpmInstallFlags
          ;
        hash = pnpmDepsHash;
      };

  cleanedArgs = builtins.removeAttrs args [
    "pnpmDeps"
    "pnpmDepsHash"
    "pnpm"
    "fetcherVersion"
    "pnpmWorkspaces"
    "pnpmInstallFlags"
    "pnpmRoot"
    "pnpmBuildScript"
    "pnpmBuildFlags"
    "dontPnpmBuild"
    "dontPnpmInstall"
    "pnpmPackName"
    "nativeBuildInputs"
    "buildInputs"
    "buildPhase"
    "installPhase"
  ];

  workspaceFlags = lib.concatMapStringsSep " " (ws: "--filter=${ws}") pnpmWorkspaces;
in

stdenv.mkDerivation (
  cleanedArgs
  // {
    inherit
      pname
      version
      src
      ;

    pnpmDeps = pnpmDeps';

    nativeBuildInputs = [
      nodejs
      pnpm
      pnpmConfigHook
      makeWrapper
    ]
    ++ nativeBuildInputs;

    inherit buildInputs;

    buildPhase =
      args.buildPhase or (
        if dontPnpmBuild then
          null
        else
          ''
            runHook preBuild
            ${lib.optionalString (pnpmRoot != null) "pushd ${pnpmRoot}"}
            if grep -q "\"${pnpmBuildScript}\"" package.json 2>/dev/null; then
              pnpm run ${workspaceFlags} ${pnpmBuildScript} ${lib.escapeShellArgs pnpmBuildFlags}
            fi
            ${lib.optionalString (pnpmRoot != null) "popd"}
            runHook postBuild
          ''
      );

    dontBuild = if args ? buildPhase then false else dontPnpmBuild;

    installPhase =
      args.installPhase or (
        if dontPnpmInstall then
          null
        else
          ''
            runHook preInstall

            mkdir -p $out/lib/node_modules/${pnpmPackName}
            cp -r . $out/lib/node_modules/${pnpmPackName}/

            # Read bin entries from package.json and create wrappers
            local binEntries
            binEntries=$(${lib.getExe nodejs} -e "
              const pkg = JSON.parse(require('fs').readFileSync('package.json', 'utf8'));
              const bin = pkg.bin || {};
              const entries = typeof bin === 'string'
                ? [[pkg.name.split('/').pop(), bin]]
                : Object.entries(bin);
              entries.forEach(([name, path]) => console.log(name + ':' + path));
            ")

            if [ -n "$binEntries" ]; then
              mkdir -p $out/bin
              echo "$binEntries" | while IFS=: read -r binName binPath; do
                makeWrapper ${lib.getExe nodejs} "$out/bin/$binName" \
                  --add-flags "$out/lib/node_modules/${pnpmPackName}/$binPath"
              done
            fi

            runHook postInstall
          ''
      );

    passthru = (args.passthru or { }) // {
      inherit nodejs pnpm;
    };

    meta = (args.meta or { }) // {
      platforms = nodejs.meta.platforms;
    };
  }
  // lib.optionalAttrs (pnpmRoot != null) {
    inherit pnpmRoot;
  }
  // lib.optionalAttrs (pnpmWorkspaces != [ ]) {
    pnpmWorkspaces = builtins.concatStringsSep " " pnpmWorkspaces;
  }
  // lib.optionalAttrs (pnpmInstallFlags != [ ]) {
    inherit pnpmInstallFlags;
  }
)
