{
  lib,
  argcomplete,
  buildPythonPackage,
  fetchPypi,
  hatchling,
  hatch-vcs,
  jq,
  pytestCheckHook,
  pyyaml,
  replaceVars,
  tomlkit,
  xmltodict,
}:

buildPythonPackage (finalAttrs: {
  pname = "yq";
  version = "4.1.2";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-qPFIkw+L6zFw9FHWfynL4LOscTzS/JHs9R1DtIeea0w=";
  };

  patches = [
    (replaceVars ./jq-path.patch {
      jq = "${lib.getBin jq}/bin/jq";
    })
  ];

  build-system = [
    hatchling
    hatch-vcs
  ];

  dependencies = [
    argcomplete
    pyyaml
    tomlkit
    xmltodict
  ];

  nativeCheckInputs = [ pytestCheckHook ];

  testPaths = [ "test" ];

  enabledTestPaths = [ "test/test.py" ];

  pythonImportsCheck = [ "yq" ];

  meta = {
    description = "Command-line YAML/XML/TOML processor - jq wrapper for YAML, XML, TOML documents";
    homepage = "https://github.com/kislyuk/yq";
    license = lib.licenses.asl20;
    mainProgram = "yq";
  };
})
