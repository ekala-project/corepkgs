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
  version = "1.2.10";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "jelmer";
    repo = "dulwich";
    tag = "dulwich-${version}";
    hash = "sha256-ogYR4xK4sYbh7zOozpiZ+bubA6/kDx1iFkbIAjYLkIs=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit pname version src;
    hash = "sha256-Shu80kj4rir3JvrgXmO82/Z6ZROaACl43zQBzjlDFYc=";
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
    maintainers = [ ];
  };
}
