{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "objgraph";
  version = "3.7.0";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-tu9LJEIXQQUJsleXBBOwGpedVN9I0tQFW2lB6Ged27s=";
  };

  build-system = [ setuptools ];

  # graphviz (the Python library and the external program) is only needed
  # for rendering reference graphs; the core counting/inspection API
  # works without it.

  pythonImportsCheck = [ "objgraph" ];

  meta = {
    description = "Draws Python object reference graphs with graphviz";
    homepage = "https://mg.pov.lt/objgraph/";
    license = lib.licenses.mit;
  };
})
