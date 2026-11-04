{
  lib,
  python,
  fetchFromGitHub,

  buildPythonPackage,
  cython,
  setuptools,
  libstemmer,
}:

buildPythonPackage (finalAttrs: {
  pname = "pystemmer";
  version = "3.1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "snowballstem";
    repo = "pystemmer";
    tag = "v${finalAttrs.version}";
    hash = "sha256-GPPl6ioB9sB2y8G2hYfu2ksR+D9xNJjK6glMADLnr7M=";
  };

  build-system = [
    cython
    setuptools
  ];

  postConfigure = ''
    export PYSTEMMER_SYSTEM_LIBSTEMMER="${lib.getDev libstemmer}/include"
  '';

  env = {
    NIX_CFLAGS_COMPILE = toString [ "-I${lib.getDev libstemmer}/include" ];
    NIX_CFLAGS_LINK = toString [ "-L${libstemmer}/lib" ];
  };

  pythonImportsCheck = [ "Stemmer" ];

  checkPhase = ''
    ${python.interpreter} runtests.py
  '';

  meta = {
    description = "Snowball stemming algorithms, for information retrieval";
    downloadPage = "https://github.com/snowballstem/pystemmer";
    homepage = "http://snowball.tartarus.org/";
    license = with lib.licenses; [
      bsd3
      mit
    ];
    platforms = lib.platforms.unix;
  };
})
