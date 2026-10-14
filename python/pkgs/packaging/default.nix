{
  lib,
  buildPythonPackage,
  fetchPypi,
  pythonOlder,

  # build-system
  flit-core,

  # tests
  pretend,
  pytestCheckHook,
}:

let
  packaging = buildPythonPackage (finalAttrs: {
    pname = "packaging";
    version = "25.0";
    pyproject = true;

    disabled = pythonOlder "3.7";

    src = fetchPypi {
      inherit (finalAttrs) pname version;
      hash = "sha256-1EOHLJjWd79g9qHy+MHLdI6P52LSv50xSLVZkpWw/E8=";
    };

    nativeBuildInputs = [ flit-core ];

    nativeCheckInputs = [
      pytestCheckHook
      pretend
    ];

    pythonImportsCheck = [
      "packaging"
      "packaging.metadata"
      "packaging.requirements"
      "packaging.specifiers"
      "packaging.tags"
      "packaging.version"
    ];

    passthru.tests = packaging.overridePythonAttrs (_: {
      doCheck = true;
    });

    meta = {
      changelog = "https://github.com/pypa/packaging/blob/${finalAttrs.version}/CHANGELOG.rst";
      description = "Core utilities for Python packages";
      downloadPage = "https://github.com/pypa/packaging";
      homepage = "https://packaging.pypa.io/";
      license = with lib.licenses; [
        bsd2
        asl20
      ];

    };
  });
in
packaging
