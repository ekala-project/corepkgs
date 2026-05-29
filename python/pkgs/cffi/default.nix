{
  buildPythonPackage,
  fetchFromGitHub,
  lib,
  libffi,
  pkg-config,
  pycparser,
  pytestCheckHook,
  setuptools,
  stdenv,
}:

buildPythonPackage (finalAttrs: {
  pname = "cffi";
  version = "2.0.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "python-cffi";
    repo = "cffi";
    tag = "v${finalAttrs.version}";
    hash = "sha256-7Mzz3KmmmE2xQru1GA4aY0DZqn6vxykWiExQvnA1bjM=";
  };

  nativeBuildInputs = [ pkg-config ];

  build-system = [ setuptools ];

  buildInputs = [ libffi ];

  # Some dependent packages expect to have pycparser available when using cffi.
  dependencies = [ pycparser ];

  doCheck = !(stdenv.hostPlatform.isMusl || stdenv.hostPlatform.useLLVM or false);

  nativeCheckInputs = [ pytestCheckHook ];

  # `testing/cffi1/test_parse_c_type.py` reads `src/cffi/parse_c_type.h`.
  testPaths = [
    "testing"
    "src"
  ];

  meta = {
    changelog = "https://github.com/python-cffi/cffi/releases/tag/v${finalAttrs.version}";
    description = "Foreign Function Interface for Python calling C code";
    downloadPage = "https://github.com/python-cffi/cffi";
    homepage = "https://cffi.readthedocs.org/";
    license = lib.licenses.mit0;
  };
})
