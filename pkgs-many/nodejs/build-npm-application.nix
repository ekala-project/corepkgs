{
  lib,
  stdenv,
  nodejs,
  importNpmLock,
  makeWrapper,
}:

{
  pname,
  version,
  src,
  npmDeps ? importNpmLock { npmRoot = src; },
  npmRoot ? null,
  npmFlags ? [ ],
  npmInstallFlags ? [ ],
  npmRebuildFlags ? [ ],
  npmBuildScript ? "build",
  dontNpmBuild ? false,
  dontNpmInstall ? false,
  npmPackName ? pname,
  nativeBuildInputs ? [ ],
  buildInputs ? [ ],
  ...
}@args:

let
  cleanedArgs = builtins.removeAttrs args [
    "npmDeps"
    "npmRoot"
    "npmFlags"
    "npmInstallFlags"
    "npmRebuildFlags"
    "npmBuildScript"
    "dontNpmBuild"
    "dontNpmInstall"
    "npmPackName"
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
      npmDeps
      ;

    nativeBuildInputs = [
      nodejs
      importNpmLock.npmConfigHook
      makeWrapper
    ]
    ++ nativeBuildInputs;

    inherit buildInputs;

    buildPhase =
      args.buildPhase or (
        if dontNpmBuild then
          null
        else
          ''
            runHook preBuild
            if grep -q "\"${npmBuildScript}\"" package.json 2>/dev/null; then
              npm run ${npmBuildScript} --offline
            fi
            runHook postBuild
          ''
      );

    dontBuild = if args ? buildPhase then false else dontNpmBuild;

    installPhase =
      args.installPhase or (
        if dontNpmInstall then
          null
        else
          ''
            runHook preInstall

            mkdir -p $out/lib/node_modules/${npmPackName}
            cp -r . $out/lib/node_modules/${npmPackName}/

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
                  --add-flags "$out/lib/node_modules/${npmPackName}/$binPath"
              done
            fi

            runHook postInstall
          ''
      );

    passthru = (args.passthru or { }) // {
      inherit nodejs;
    };

    meta = (args.meta or { }) // {
      platforms = nodejs.meta.platforms;
    };
  }
)
