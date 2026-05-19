{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  pythonOlder,
  installShellFiles,
  secretstorage,
  setuptools-scm,
  jeepney,
  jaraco-classes,
  jaraco-context,
  jaraco-functools,
  importlib-metadata,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "keyring";
  version = "25.7.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "jaraco";
    repo = "keyring";
    tag = "v${version}";
    hash = "sha256-v9s28vwx/5DJRa3dQyS/mdZppfvFcfBtafjBRi2c1oQ=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail '"coherent.licensed",' ""
  '';

  build-system = [ setuptools-scm ];

  nativeBuildInputs = [
    installShellFiles
  ];

  dependencies = [
    jaraco-classes
    jaraco-context
    jaraco-functools
    jeepney
    secretstorage
  ]
  ++ lib.optionals (pythonOlder "3.12") [ importlib-metadata ];

  # TODO: determine why this doesnt work
  # postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
  #   installShellCompletion --cmd keyring \
  #     --bash <($out/bin/keyring --print-completion bash) \
  #     --zsh <($out/bin/keyring --print-completion zsh)
  # '';

  pythonImportsCheck = [
    "keyring"
    "keyring.backend"
  ];

  # Disable tests as they require pyfakefs and shtab
  doCheck = false;

  meta = {
    description = "Store and access your passwords safely";
    homepage = "https://github.com/jaraco/keyring";
    changelog = "https://github.com/jaraco/keyring/blob/${src.tag}/NEWS.rst";
    license = lib.licenses.mit;
    mainProgram = "keyring";
    maintainers = [ ];
    platforms = lib.platforms.unix;
  };
}
