{
  stdenv,
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  python,

  # tests
  distutils ? null,
}:

buildPythonPackage (finalAttrs: {
  pname = "setuptools";
  version = "80.9.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "pypa";
    repo = "setuptools";
    tag = "v${finalAttrs.version}";
    hash = "sha256-wueVQsV0ja/iPFRK7OKV27FQ7hYKF8cP3WH5wJeIXnI=";
  };

  patches = [
    ./tag-date.patch
  ];

  # Drop dependency on coherent.license, which in turn requires coherent.build
  postPatch = ''
    sed -i "/coherent.licensed/d" pyproject.toml
  '';

  preBuild = lib.optionalString (!stdenv.hostPlatform.isWindows) ''
    export SETUPTOOLS_INSTALL_WINDOWS_SPECIFIC_FILES=0
  '';

  passthru.tests = { } // lib.optionalAttrs (distutils != null) { inherit distutils; };

  pythonImportsCheck = [
    "setuptools"
    "pkg_resources"
  ];

  meta = {
    description = "Utilities to facilitate the installation of Python packages";
    homepage = "https://github.com/pypa/setuptools";
    changelog = "https://setuptools.pypa.io/en/stable/history.html#v${
      lib.replaceStrings [ "." ] [ "-" ] finalAttrs.version
    }";
    license = with lib.licenses; [ mit ];
    platforms = python.meta.platforms;

  };
})
