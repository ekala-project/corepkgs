{
  lib,
  buildPythonPackage,
  fetchPypi,
  hatchling,
}:

buildPythonPackage (finalAttrs: {
  pname = "soupsieve";
  version = "3.0.4";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-kk+rhK4hYEwZ4XXh85gV62+oO6I4NuCeneGAkl5bxMA=";
  };

  nativeBuildInputs = [ hatchling ];

  # Circular dependency on beautifulsoup4
  # pythonImportsCheck = [ "soupsieve" ];

  meta = {
    description = "CSS4 selector implementation for Beautiful Soup";
    license = lib.licenses.mit;
    homepage = "https://github.com/facelessuser/soupsieve";
    platforms = lib.platforms.all;
  };
})
