# pyright — Type checker for the Python language
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage rec {
  pname = "pyright";
  version = "1.1.412";

  src = fetchFromGitHub {
    owner = "Microsoft";
    repo = "pyright";
    tag = version;
    hash = "sha256-V2sQp/LA43NjCdtr2/drZ1LMgm4u2tcf4EjdhWVLXHw=";
  };

  # TODO: prefetch-npm-deps doesn't capture all transitive deps; needs investigation
  npmDepsHash = "sha256-/sxbKCze7VNKeHNtWRp+fmwcUxDxlxaEGnaYk74YsHk=";

  # pyright is in a monorepo workspace — build and install only the pyright CLI
  npmWorkspace = "packages/pyright";
  dontNpmBuild = true;

  meta = {
    description = "Type checker for the Python language";
    homepage = "https://github.com/Microsoft/pyright";
    license = lib.licenses.mit;
    mainProgram = "pyright";
  };
}
