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
  version = "2026.11.20";
  pyproject = true;

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "certifi";
    repo = "python-certifi";
    tag = finalAttrs.version;
    hash = "sha256-0wu2HR9JgE4TONyzLT0d/+Kt1CSeFFTNyOboZhhcJJU=";
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
