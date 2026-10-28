{
  lib,
  buildPythonPackage,
  sphinx,
  fetchFromGitHub,
  setuptools,
}:
buildPythonPackage (finalAttrs: {
  pname = "sphinx-issues";
  version = "3.0.1";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchFromGitHub {
    owner = "sloria";
    repo = "sphinx-issues";
    tag = finalAttrs.version;
    sha256 = "1lns6isq9kwcw8z4jwgy927f7idx9srvri5adaa5zmypw5x47hha";
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
