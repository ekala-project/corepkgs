{
  lib,
  buildPythonPackage,
  isPyPy,
  fetchFromGitHub,
  setuptools,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "pyflakes";
  version = "4.1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "PyCQA";
    repo = "pyflakes";
    tag = finalAttrs.version;
    hash = "sha256-Z8m4IaTr0+3C15O05G24LT2iNhvWebKhfoaaK0DfWWI=";
  };

  build-system = [ setuptools ];

  nativeCheckInputs = [ pytestCheckHook ];

  testPaths = [ "pyflakes/test" ];

  disabledTests = [
    # paths in error messages differ in sandbox
    "test_readFromStdin"
    "test_errors_io"
    "test_errors_syntax"
    "test_fileWithFlakes"
    "test_goodFile"
  ]
  ++ lib.optionals isPyPy [
    # https://github.com/PyCQA/pyflakes/issues/779
    "test_eofSyntaxError"
    "test_misencodedFileUTF16"
    "test_misencodedFileUTF8"
    "test_multilineSyntaxError"
  ];

  pythonImportsCheck = [ "pyflakes" ];

  meta = {
    homepage = "https://github.com/PyCQA/pyflakes";
    changelog = "https://github.com/PyCQA/pyflakes/blob/${finalAttrs.src.tag}/NEWS.rst";
    description = "Simple program which checks Python source files for errors";
    mainProgram = "pyflakes";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
