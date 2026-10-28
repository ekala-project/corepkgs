{
  lib,
  buildPythonPackage,
  fetchPypi,
  isPyPy,

  # build-system
  hatchling,
  hatch-vcs,

  # optional-dependencies
  brotli,
  brotlicffi,
  pysocks,
  zstandard,

  # tests
  pytestCheckHook,
  pytest-timeout,
  tornado ? null,
  trustme ? null,
}:

buildPythonPackage (finalAttrs: {
  pname = "urllib3";
  version = "2.8.0";
  pyproject = true;

  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-Y78urUyHlCbr8i7yp4HutKo7SueYoENVBvhof9W7m2M=";
  };

  build-system = [
    hatchling
    hatch-vcs
  ];

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail ', "setuptools-scm>=8,<11"' ""
  '';

  optional-dependencies = {
    brotli = if isPyPy then [ brotlicffi ] else [ brotli ];
    socks = [ pysocks ];
    zstd = [ zstandard ];
  };

  nativeCheckInputs = [
    pytest-timeout
    pytestCheckHook
  ]
  ++ lib.optional (tornado != null) tornado
  ++ lib.optional (trustme != null) trustme
  ++ lib.concatAttrValues finalAttrs.optional-dependencies;

  passthru.tests.pytest = finalAttrs.finalPackage.overridePythonAttrs (_: {
    doCheck = true;
  });

  preCheck = ''
    export CI # Increases LONG_TIMEOUT
  '';

  pythonImportsCheck = [ "urllib3" ];

  meta = {
    description = "Powerful, user-friendly HTTP client for Python";
    homepage = "https://github.com/urllib3/urllib3";
    changelog = "https://github.com/urllib3/urllib3/blob/${finalAttrs.version}/CHANGES.rst";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
