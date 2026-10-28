{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pytestCheckHook,
  setuptools,
}:

buildPythonPackage (finalAttrs: {
  pname = "sortedcontainers";
  version = "2.4.0";
  pyproject = true;

  build-system = [ setuptools ];

  src = fetchFromGitHub {
    owner = "grantjenks";
    repo = "python-sortedcontainers";
    tag = "v${finalAttrs.version}";
    hash = "sha256-YRbSM2isWi7AzfquFvuZBlpEMNUnBJTBLBn0/XYVHKQ=";
  };

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "sortedcontainers" ];

  passthru.tests = {
    pytest = finalAttrs.finalPackage.overridePythonAttrs (_: {
      doCheck = true;
    });
  };

  meta = {
    description = "Python Sorted Container Types: SortedList, SortedDict, and SortedSet";
    homepage = "https://grantjenks.com/docs/sortedcontainers/";
    license = lib.licenses.asl20;
    platforms = lib.platforms.all;
  };
})
