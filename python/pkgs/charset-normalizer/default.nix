{
  lib,
  stdenv,
  aiohttp,
  buildPythonPackage,
  fetchFromGitHub,
  isPyPy,
  mypy,
  pytestCheckHook,
  requests,
  setuptools,
  setuptools-scm,
  # mypyc compilation needs a working mypy for the host; it is also the leg of
  # the cycle rustPlatform.fetchCargoVendor breaks when it builds its own
  # requests, so keep it switchable.
  withMypyc ? !isPyPy && !stdenv.hostPlatform.isStatic,
}:

buildPythonPackage (finalAttrs: {
  pname = "charset-normalizer";
  version = "3.5.3";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "jawah";
    repo = "charset_normalizer";
    tag = finalAttrs.version;
    hash = "sha256-yRz/j6uAazRuVDIEE9PXCM/Nar4kSuGl2DR0OB313e0=";
  };

  build-system = [
    setuptools
    setuptools-scm
  ]
  ++ lib.optional withMypyc mypy;

  env.CHARSET_NORMALIZER_USE_MYPYC = lib.optionalString withMypyc "1";

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "charset_normalizer" ];

  passthru.tests = {
    inherit aiohttp requests;
  };

  meta = {
    description = "Python module for encoding and language detection";
    mainProgram = "normalizer";
    homepage = "https://charset-normalizer.readthedocs.io/";
    changelog = "https://github.com/jawah/charset_normalizer/blob/${finalAttrs.src.tag}/CHANGELOG.md";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
})
