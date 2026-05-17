{
  lib,
  stdenv,
  nodejs,
  fetchurl,
  makeWrapper,
}:

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
  ...
}@args:

stdenv.mkDerivation (
  args
  // {
    inherit pname version src;

    nativeBuildInputs = [
      nodejs
      makeWrapper
    ]
    ++ nativeBuildInputs;

    buildInputs = [ nodejs ] ++ buildInputs;

    configurePhase =
      args.configurePhase or ''
        runHook preConfigure

        export HOME=$TMPDIR
        export npm_config_cache=$TMPDIR/.npm
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
          if npmDepsHash != "" then
            ''
              # Use pre-fetched dependencies
              npm ci --offline --cache=$npm_config_cache ${lib.concatStringsSep " " npmFlags}
            ''
          else
            ''
              npm install --cache=$npm_config_cache ${lib.concatStringsSep " " npmFlags}
            ''
        }

        # Run build script if it exists
        ${lib.optionalString (npmBuildScript != "") ''
          if grep -q "\"${npmBuildScript}\"" package.json; then
            npm run ${npmBuildScript} --cache=$npm_config_cache
          fi
        ''}

        runHook postBuild
      '';

    installPhase =
      args.installPhase or ''
        runHook preInstall

        mkdir -p $out/{lib,bin}

        # Copy the entire package to lib
        cp -r . $out/lib/${pname}

        # Remove node_modules and reinstall production dependencies
        rm -rf $out/lib/${pname}/node_modules
        cd $out/lib/${pname}
        npm install --production --cache=$npm_config_cache ${lib.concatStringsSep " " npmFlags}

        # Create bin wrappers for executables in package.json
        if [ -f package.json ]; then
          # Check if package.json has a "bin" field
          if grep -q '"bin"' package.json; then
            # Extract bin entries and create wrappers
            # This is a simplified version - real implementation would parse JSON properly
            ln -s $out/lib/${pname}/node_modules/.bin/* $out/bin/ 2>/dev/null || true
          fi
        fi

        runHook postInstall
      '';

    passthru = args.passthru or { } // {
      inherit nodejs;
    };

    meta = args.meta or { } // {
      platforms = nodejs.meta.platforms;
    };
  }
)
