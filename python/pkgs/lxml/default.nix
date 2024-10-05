{
  stdenv,
  lib,
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  cython,
  setuptools,

  # native dependencies
  zlib,
  xcodebuild ? null,

  # For native versions of libxml2 and libxslt
  pkgs,
}:

buildPythonPackage rec {
  pname = "lxml";
  version = "5.2.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "lxml";
    repo = "lxml";
    rev = "refs/tags/lxml-${version}";
    hash = "sha256-c9r2uqjXmQOXyPCsJTzi1OatkQ9rhJbKqpxaoFz2l18=";
  };

  # setuptoolsBuildPhase needs dependencies to be passed through nativeBuildInputs
  nativeBuildInputs = [
    pkgs.libxml2
    pkgs.libxslt
    cython
    setuptools
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [ xcodebuild ];

  buildInputs = [
    pkgs.libxml2
    pkgs.libxslt
    zlib
  ];

  env = lib.optionalAttrs stdenv.cc.isClang {
    NIX_CFLAGS_COMPILE = "-Wno-error=incompatible-function-pointer-types";
  };

  # tests are meant to be ran "in-place" in the same directory as src
  doCheck = false;

  pythonImportsCheck = [
    "lxml"
    "lxml.etree"
  ];

  meta = with lib; {
    changelog = "https://github.com/lxml/lxml/blob/lxml-${version}/CHANGES.txt";
    description = "Pythonic binding for the libxml2 and libxslt libraries";
    homepage = "https://lxml.de";
    license = licenses.bsd3;
    maintainers = [ ];
  };
}