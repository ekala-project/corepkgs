{
  lib,
  buildPythonPackage,
  cacert,
  pythonOlder,
  fetchFromGitHub,
  setuptools,
  pytestCheckHook,
}:

buildPythonPackage (finalAttrs: {
  pname = "certifi";
  version = "2026.10.23";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "certifi";
    repo = "python-certifi";
    tag = finalAttrs.version;
    hash = "sha256-uESJgC07To+bUePmwi180SCtAzAZkmEn1UolTWpB4X0=";
  };

  patches = [
    # Add support for NIX_SSL_CERT_FILE
    ./env.patch
  ];

  postPatch = ''
    # Use our system-wide ca-bundle instead of the bundled one
    rm -v "certifi/cacert.pem"
    ln -snvf "${cacert}/etc/ssl/certs/ca-bundle.crt" "certifi/cacert.pem"
  '';

  nativeBuildInputs = [ setuptools ];

  propagatedNativeBuildInputs = [
    # propagate cacerts setup-hook to set up `NIX_SSL_CERT_FILE`
    cacert
  ];

  nativeCheckInputs = [ pytestCheckHook ];

  pythonImportsCheck = [ "certifi" ];

  testPaths = [ "certifi/tests" ];

  meta = {
    homepage = "https://github.com/certifi/python-certifi";
    description = "Python package for providing Mozilla's CA Bundle";
    license = lib.licenses.isc;
    platforms = lib.platforms.all;
  };
})
