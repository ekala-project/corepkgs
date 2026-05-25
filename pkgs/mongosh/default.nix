{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:

let
  version = "2.8.3";
  buildNpmPackage' = buildNpmPackage.override { nodejs = nodejs_22; };
in
buildNpmPackage' {
  pname = "mongosh";
  inherit version;

  src = fetchFromGitHub {
    owner = "mongodb-js";
    repo = "mongosh";
    tag = "v${version}";
    hash = "sha256-CHHGQYJBv1sVo2LT9jxx+c15TU8ecG9R5DVQOA9yG+A=";
  };

  npmDepsHash = "sha256-FlVKJqXiDW3FdBrm2lN2vw+xFkvm7J1FgCEI6rFfR4o=";

  patches = [
    ./disable-telemetry.patch
  ];

  npmFlags = [
    "--omit=optional"
    "--ignore-scripts"
  ];
  npmBuildScript = "compile";

  # Use automatic workspace support
  npmWorkspace = "packages/cli-repl";

  meta = {
    homepage = "https://www.mongodb.com/try/download/shell";
    description = "MongoDB Shell";
    maintainers = [ ];
    license = lib.licenses.asl20;
    mainProgram = "mongosh";
  };
}
