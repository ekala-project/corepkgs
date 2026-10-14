{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pythonOlder,
  hatchling,
  hatch-vcs,
}:

buildPythonPackage (finalAttrs: {
  pname = "argcomplete";
  version = "3.7.2";
  pyproject = true;

  disabled = pythonOlder "3.8";

  src = fetchFromGitHub {
    owner = "kislyuk";
    repo = "argcomplete";
    tag = "v${finalAttrs.version}";
    hash = "sha256-WKIhWlftH9xgdklljAOmW4XYMbclGrCFTtsxws2FRzg=";
  };

  build-system = [
    hatchling
    hatch-vcs
  ];

  pythonImportsCheck = [ "argcomplete" ];

  meta = {
    description = "Bash tab completion for argparse";
    homepage = "https://kislyuk.github.io/argcomplete/";
    changelog = "https://github.com/kislyuk/argcomplete/blob/${finalAttrs.src.tag}/Changes.rst";
    downloadPage = "https://github.com/kislyuk/argcomplete";
    license = lib.licenses.asl20;

  };
})
