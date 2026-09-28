{
  lib,
  buildPythonPackage,
  cargo,
  fetchFromGitHub,
  pytestCheckHook,
  rustPlatform,
  rustc,
  setuptools,
  setuptools-rust,
  urllib3,
}:

buildPythonPackage rec {
  pname = "dulwich";
  version = "1.2.15";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "jelmer";
    repo = "dulwich";
    tag = "dulwich-${version}";
    hash = "sha256-ZLTgVeY9seeElnRc0G7M+0bFx8b/9i5dMj4/61A/maY=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit pname version src;
    hash = "sha256-X8sKVLTPQVjAcW+h1X/AsHW7UgwSOUbAa4VRZfhepM0=";
  };

  nativeBuildInputs = [
    rustPlatform.cargoSetupHook
    cargo
    rustc
  ];

  build-system = [
    setuptools
    setuptools-rust
  ];

  dependencies = [
    urllib3
  ];

  # Disable tests as they require many dependencies not yet in core-pkgs
  doCheck = false;

  pythonImportsCheck = [ "dulwich" ];

  meta = {
    description = "Implementation of the Git file formats and protocols";
    longDescription = ''
      Dulwich is a Python implementation of the Git file formats and protocols, which
      does not depend on Git itself. All functionality is available in pure Python.
    '';
    homepage = "https://www.dulwich.io/";
    changelog = "https://github.com/jelmer/dulwich/blob/dulwich-${src.tag}/NEWS";
    license = with lib.licenses; [
      asl20
      gpl2Plus
    ];
  };
}
