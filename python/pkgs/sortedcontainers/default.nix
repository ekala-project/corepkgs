{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "sortedcontainers";
  version = "2.4.0";
  format = "setuptools";

  src = fetchFromGitHub {
    owner = "grantjenks";
    repo = "python-sortedcontainers";
    rev = "v${finalAttrs.version}";
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

  };
})
