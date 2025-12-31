{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  flit-core,
  packaging,
}:

buildPythonPackage rec {
  pname = "marshmallow";
  version = "3.26.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "marshmallow-code";
    repo = "marshmallow";
    tag = version;
    hash = "sha256-l5pEhv8D6jRlU24SlsGQEkXda/b7KUdP9mAqrZCbl38=";
  };

  nativeBuildInputs = [ flit-core ];

  propagatedBuildInputs = [ packaging ];

  # Avoid simplejson
  doCheck = false;

  pythonImportsCheck = [ "marshmallow" ];

  meta = {
    description = "Library for converting complex objects to and from simple Python datatypes";
    homepage = "https://github.com/marshmallow-code/marshmallow";
    changelog = "https://github.com/marshmallow-code/marshmallow/blob/${version}/CHANGELOG.rst";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
}
