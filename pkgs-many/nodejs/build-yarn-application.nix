{
  lib,
  stdenv,
  nodejs,
  yarn,
  fetchYarnDeps,
  yarnConfigHook,
  yarnBuildHook,
  yarnInstallHook,
  makeWrapper,
}:

{
  pname,
  version,
  src,
  # yarn dependency management — provide yarnOfflineCache directly, or yarnDepsHash to auto-compute
  yarnOfflineCache ? null,
  yarnDepsHash ? "",
  # build control
  yarnBuildScript ? "build",
  yarnBuildFlags ? [ ],
  dontYarnBuild ? false,
  # install control
  dontYarnInstall ? false,
  yarnKeepDevDeps ? false,
  yarnPackName ? pname,
  # standard mkDerivation args
  nativeBuildInputs ? [ ],
  buildInputs ? [ ],
  ...
}@args:

let
  yarnOfflineCache' =
    if args.yarnOfflineCache or null != null then
      args.yarnOfflineCache
    else
      fetchYarnDeps {
        inherit src;
        hash = yarnDepsHash;
      };

  cleanedArgs = builtins.removeAttrs args [
    "yarnOfflineCache"
    "yarnDepsHash"
    "yarnBuildScript"
    "yarnBuildFlags"
    "dontYarnBuild"
    "dontYarnInstall"
    "yarnKeepDevDeps"
    "yarnPackName"
    "nativeBuildInputs"
    "buildInputs"
    "buildPhase"
    "installPhase"
  ];
in

stdenv.mkDerivation (
  cleanedArgs
  // {
    inherit
      pname
      version
      src
      ;

    yarnOfflineCache = yarnOfflineCache';

    nativeBuildInputs = [
      nodejs
      yarn
      yarnConfigHook
      makeWrapper
    ]
    ++ nativeBuildInputs;

    inherit buildInputs;

    buildPhase =
      args.buildPhase or (
        if dontYarnBuild then
          null
        else
          ''
            runHook preBuild
            if grep -q "\"${yarnBuildScript}\"" package.json 2>/dev/null; then
              yarn --offline ${yarnBuildScript} ${lib.escapeShellArgs yarnBuildFlags}
            fi
            runHook postBuild
          ''
      );

    dontBuild = if args ? buildPhase then false else dontYarnBuild;

    installPhase =
      args.installPhase or (
        if dontYarnInstall then
          null
        else
          ''
            runHook preInstall

            mkdir -p $out/lib/node_modules/${yarnPackName}
            cp -r . $out/lib/node_modules/${yarnPackName}/

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
                  --add-flags "$out/lib/node_modules/${yarnPackName}/$binPath"
              done
            fi

            runHook postInstall
          ''
      );

    passthru = (args.passthru or { }) // {
      inherit nodejs yarn;
    };

    meta = (args.meta or { }) // {
      platforms = nodejs.meta.platforms;
    };
  }
  // lib.optionalAttrs yarnKeepDevDeps {
    inherit yarnKeepDevDeps;
  }
)
