{
  lib,
  stdenv,
  nodejs,
  fetchNpmDeps,
  makeWrapper,
}:

assert lib.assertMsg (nodejs ? npmInstallHook) "nodejs must have npmInstallHook in passthru";

{
  pname,
  version,
  src,
  npmDepsHash ? "",
  npmFlags ? [ ],
  npmBuildScript ? "build",
  makeCacheWritable ? false,
  buildInputs ? [ ],
  nativeBuildInputs ? [ ],
  dontNpmInstall ? false,
  # Workspace support for monorepos
  npmWorkspace ? null, # e.g., "packages/cli" or "@scope/package-name"
  ...
}@args:

let
  # Create npm-deps FOD if npmDepsHash is provided
  npmDeps =
    if npmDepsHash != "" then
      fetchNpmDeps {
        inherit src;
        hash = npmDepsHash;
      }
    else
      null;
in

stdenv.mkDerivation (
  args
  // {
    inherit pname version src;

    nativeBuildInputs = [
      nodejs
      nodejs.npmInstallHook
      makeWrapper
    ]
    ++ nativeBuildInputs;

    buildInputs = [ nodejs ] ++ buildInputs;

    configurePhase =
      args.configurePhase or ''
        runHook preConfigure

        export HOME=$TMPDIR
        export npm_config_cache=$TMPDIR/.npm

        ${lib.optionalString (npmDeps != null) ''
          # Populate npm cache from FOD
          if [ -d "${npmDeps}" ]; then
            cp -r "${npmDeps}" "$npm_config_cache"
            chmod -R +w "$npm_config_cache"
          fi
        ''}

        ${lib.optionalString makeCacheWritable ''
          chmod -R +w $npm_config_cache || true
        ''}

        runHook postConfigure
      '';

    buildPhase =
      args.buildPhase or ''
        runHook preBuild

        # Install dependencies
        ${
          if npmDeps != null then
            ''
              # Use pre-fetched dependencies from FOD
              npm ci --offline --cache=$npm_config_cache ${lib.concatStringsSep " " npmFlags}
            ''
          else
            ''
              # Fetch dependencies (impure, requires network)
              npm install --cache=$npm_config_cache ${lib.concatStringsSep " " npmFlags}
            ''
        }

        # Patch shebangs in node_modules after install
        if [ -d node_modules ]; then
          patchShebangs node_modules
        fi

        # Run build script if it exists
        ${lib.optionalString (npmBuildScript != "") ''
          if grep -q "\"${npmBuildScript}\"" package.json 2>/dev/null; then
            npm run ${npmBuildScript} --cache=$npm_config_cache
          fi
        ''}

        runHook postBuild
      '';

    # installPhase is handled by npmInstallHook
    # Users can override by setting installPhase or dontNpmInstall
    inherit dontNpmInstall;

    passthru = args.passthru or { } // {
      inherit nodejs;
    };

    meta = args.meta or { } // {
      platforms = nodejs.meta.platforms;
    };

    ${if (npmWorkspace != null) then "npmWorkspace" else null} = npmWorkspace;
  }
)
