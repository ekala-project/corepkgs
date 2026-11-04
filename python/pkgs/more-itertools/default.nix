{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  flit-core,
  pytestCheckHook,
  stdenv,
}:

buildPythonPackage (finalAttrs: {
  pname = "more-itertools";
  version = "11.2.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "more-itertools";
    repo = "more-itertools";
    tag = "v${finalAttrs.version}";
    hash = "sha256-bT+dDxPcrPYKEzsPYzKDJehZIpeJTqvheVhSG+ufmbo=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail "flit_core >=4,<5" "flit_core >=3,<5"
  '';

  build-system = [ flit-core ];

  nativeCheckInputs = [ pytestCheckHook ];

  testPaths = [ "tests" ];

  # iterable = range(10 ** 10)  # Is efficiently reversible
  # OverflowError: Python int too large to convert to C long
  doCheck = !stdenv.hostPlatform.is32bit;

  pythonImportsCheck = [ "more_itertools" ];

  meta = {
    homepage = "https://more-itertools.readthedocs.org";
    changelog = "https://more-itertools.readthedocs.io/en/stable/versions.html";
    description = "Expansion of the itertools module";
    downloadPage = "https://github.com/more-itertools/more-itertools";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
