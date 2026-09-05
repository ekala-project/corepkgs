# pyright — Type checker for the Python language
#
# Pyright is in a monorepo; the root lockfile uses npm v3 format which omits
# `resolved` URLs for registry packages, breaking prefetch-npm-deps.
# We build each workspace package separately using the per-package lockfiles
# (which do have resolved URLs), following the same approach as nixpkgs.
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  runCommand,
  jq,
}:

let
  version = "1.1.412";

  src = fetchFromGitHub {
    owner = "Microsoft";
    repo = "pyright";
    tag = version;
    hash = "sha256-V2sQp/LA43NjCdtr2/drZ1LMgm4u2tcf4EjdhWVLXHw=";
  };

  # The root package.json pulls in the entire monorepo's devDependencies (lerna,
  # nx, eslint, etc).  Strip it to just the two deps the pyright build needs.
  patchedPackageJSON =
    runCommand "package.json"
      {
        nativeBuildInputs = [ jq ];
      }
      ''
        jq '
          .devDependencies |= with_entries(select(.key == "glob" or .key == "jsonc-parser"))
          | .scripts =  {  }
          ' ${src}/package.json > $out
      '';

  # Stage 1: install root workspace deps (glob, jsonc-parser)
  pyright-root = buildNpmPackage {
    pname = "pyright-root";
    inherit version src;
    npmDepsHash = "sha256-0w/CYFfAaEK6LKZZc9+nt5zUmxCqCcJfSZRAroOhJOA=";
    dontNpmBuild = true;
    postPatch = ''
      cp ${patchedPackageJSON} ./package.json
      cp ${./package-lock.json} ./package-lock.json
    '';
    installPhase = ''
      runHook preInstall
      cp -r . "$out"
      runHook postInstall
    '';
  };

  # Stage 2: install pyright-internal deps (vscode-languageserver, etc)
  pyright-internal = buildNpmPackage {
    pname = "pyright-internal";
    inherit version src;
    sourceRoot = "${src.name}/packages/pyright-internal";
    npmDepsHash = "sha256-skTnHcET5ujyKTEqh3oyiBwHF6yvaY8c/ccOnwQQKJ0=";
    dontNpmBuild = true;
    installPhase = ''
      runHook preInstall
      cp -r . "$out"
      runHook postInstall
    '';
  };
in

# Stage 3: install pyright CLI deps and link workspace node_modules
buildNpmPackage rec {
  pname = "pyright";
  inherit version src;

  sourceRoot = "${src.name}/packages/pyright";
  npmDepsHash = "sha256-rgENiJVYKMSZimWzlvaaiC6Z5/OEdk4W47gkjcuv0nw=";

  postPatch = ''
    chmod +w ../../
    ln -s ${pyright-root}/node_modules ../../node_modules
    chmod +w ../pyright-internal
    ln -s ${pyright-internal}/node_modules ../pyright-internal/node_modules
  '';

  dontNpmBuild = true;

  postInstall = ''
    mkdir -p $out/bin
    ln -s $out/lib/node_modules/pyright/index.js $out/bin/pyright
    ln -s $out/lib/node_modules/pyright/langserver.index.js $out/bin/pyright-langserver
  '';

  meta = {
    description = "Type checker for the Python language";
    homepage = "https://github.com/Microsoft/pyright";
    license = lib.licenses.mit;
    mainProgram = "pyright";
  };
}
