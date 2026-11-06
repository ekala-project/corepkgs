{
  lib,
  buildPythonPackage,
  sphinx,
  fetchFromGitHub,
  flit-core,
}:
buildPythonPackage (finalAttrs: {
  pname = "sphinx-issues";
  version = "6.0.0";
  pyproject = true;

  build-system = [ flit-core ];

  src = fetchFromGitHub {
    owner = "sloria";
    repo = "sphinx-issues";
    tag = finalAttrs.version;
    sha256 = "sha256-havy1wP300yAKRi68fAVfQS7t5S9NueuGqE2RqdkVP0=";
  };

  pythonImportsCheck = [ "sphinx_issues" ];

  propagatedBuildInputs = [ sphinx ];

  meta = {
    homepage = "https://github.com/sloria/sphinx-issues";
    description = "Sphinx extension for linking to your project's issue tracker";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
