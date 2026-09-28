{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  pytest-cov-stub ? null,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "wcwidth";
  version = "0.9.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "jquast";
    repo = "wcwidth";
    tag = version;
    hash = "sha256-tH96gjq8dTDdogdZYj4r+BTLw8/CX4ebBWLTJAYUfUE=";
  };

  build-system = [ setuptools ];

  doCheck = false;

  nativeCheckInputs = [
    pytest-cov-stub
    pytestCheckHook
  ];

  pythonImportsCheck = [ "wcwidth" ];

  meta = {
    description = "Measures number of Terminal column cells of wide-character codes";
    longDescription = ''
      This API is mainly for Terminal Emulator implementors -- any Python
      program that attempts to determine the printable width of a string on
      a Terminal. It is implemented in python (no C library calls) and has
      no 3rd-party dependencies.
    '';
    homepage = "https://github.com/jquast/wcwidth";
    changelog = "https://github.com/jquast/wcwidth/releases/tag/${src.tag}";
    license = lib.licenses.mit;
  };
}
