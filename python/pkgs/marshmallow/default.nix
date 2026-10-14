{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  flit-core,
  packaging,
}:

buildPythonPackage (finalAttrs: {
  pname = "marshmallow";
  version = "3.26.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "marshmallow-code";
    repo = "marshmallow";
    tag = finalAttrs.version;
    hash = "sha256-l5pEhv8D6jRlU24SlsGQEkXda/b7KUdP9mAqrZCbl38=";
  };

  nativeBuildInputs = [ flit-core ];

  propagatedBuildInputs = [ packaging ];

  pythonImportsCheck = [ "marshmallow" ];

  meta = {
    description = "Library for converting complex objects to and from simple Python datatypes";
    homepage = "https://github.com/marshmallow-code/marshmallow";
    changelog = "https://github.com/marshmallow-code/marshmallow/blob/${finalAttrs.version}/CHANGELOG.rst";
    license = lib.licenses.mit;

  };
})
