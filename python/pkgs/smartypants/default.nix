{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  isPyPy,
  setuptools,
  docutils,
  pygments,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "smartypants";
  version = "2.0.2";
  pyproject = true;

  disabled = isPyPy;

  src = fetchFromGitHub {
    owner = "leohemsted";
    repo = "smartypants.py";
    tag = "v${finalAttrs.version}";
    hash = "sha256-jSGiT36Rr0P6eEWZIHtMj4go3KGDRaF2spLxLNruDec=";
  };

  build-system = [ setuptools ];

  nativeCheckInputs = [
    docutils
    pygments
    pytestCheckHook
  ];

  # The tests reference the `smartypants` CLI script and `README.rst` at the
  # source root, so bundle them into the `test_src` output.
  testPaths = [
    "tests"
    "smartypants"
    "README.rst"
  ];

  preCheck = ''
    patchShebangs smartypants
  '';

  pythonImportsCheck = [ "smartypants" ];

  meta = {
    description = "Translate plain ASCII quotation marks and other characters into “smart” typographic HTML entities";
    homepage = "https://github.com/leohemsted/smartypants.py";
    changelog = "https://github.com/leohemsted/smartypants.py/blob/v${finalAttrs.version}/CHANGES.rst";
    license = lib.licenses.bsd3;

    mainProgram = "smartypants";
  };
})
