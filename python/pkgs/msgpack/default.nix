{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pytestCheckHook,
  setuptools,
  cython,
  borgbackup ? null,
}:

buildPythonPackage (finalAttrs: {
  pname = "msgpack";
  version = "1.2.3";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "msgpack";
    repo = "msgpack-python";
    tag = "v${finalAttrs.version}";
    hash = "sha256-sih4e/AsuKknUFgyP6NfVdvQU3V42ZaIc4mB/wA6/3E=";
  };

  build-system = [ setuptools ];

  nativeBuildInputs = [ cython ];

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "msgpack" ];

  passthru.tests = {
    # borgbackup is sensible to msgpack versions: https://github.com/borgbackup/borg/issues/3753
    # please be mindful before bumping versions.
    inherit borgbackup;
  };

  preBuild = ''
    make cython
  '';

  meta = {
    description = "MessagePack serializer implementation";
    homepage = "https://github.com/msgpack/msgpack-python";
    changelog = "https://github.com/msgpack/msgpack-python/blob/${finalAttrs.src.tag}/ChangeLog.rst";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
  };
})
