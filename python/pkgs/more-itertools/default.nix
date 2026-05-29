{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  flit-core,
  pytestCheckHook,
  six,
  stdenv,
}:

buildPythonPackage (finalAttrs: {
  pname = "more-itertools";
  version = "11.0.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "more-itertools";
    repo = "more-itertools";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ZKM9+3l0qNclcQRNOEk8IF59xqyh1+uvdDRriG3Z/ek=";
  };

  build-system = [ flit-core ];

  propagatedBuildInputs = [ six ];

  nativeCheckInputs = [ pytestCheckHook ];

  testPaths = [ "tests" ];

  # iterable = range(10 ** 10)  # Is efficiently reversible
  # OverflowError: Python int too large to convert to C long
  doCheck = !stdenv.hostPlatform.is32bit;

  meta = {
    homepage = "https://more-itertools.readthedocs.org";
    changelog = "https://more-itertools.readthedocs.io/en/stable/versions.html";
    description = "Expansion of the itertools module";
    downloadPage = "https://github.com/more-itertools/more-itertools";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
})
