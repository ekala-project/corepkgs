{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  flit-core,
  pytestCheckHook,
  sphinx,
}:

buildPythonPackage (finalAttrs: {
  pname = "roman-numerals-py";
  version = "4.1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "AA-Turner";
    repo = "roman-numerals";
    tag = "v${finalAttrs.version}";
    hash = "sha256-v+aPIcsggjRJ3l6Xfw97b3zcqpyWNY4XWy2+5aWyitY=";
  };

  postPatch = ''
    ls -lah
    cp LICENCE.rst python/

    cd python
  '';

  build-system = [ flit-core ];

  nativeCheckInputs = [ pytestCheckHook ];

  testPaths = [ "tests" ];

  pythonImportsCheck = [ "roman_numerals" ];

  meta = {
    description = "Manipulate roman numerals";
    homepage = "https://github.com/AA-Turner/roman-numerals/";
    changelog = "https://github.com/AA-Turner/roman-numerals/blob/${finalAttrs.src.tag}/CHANGES.rst";
    license = lib.licenses.cc0;
    mainProgram = "roman-numerals-py";
    platforms = lib.platforms.all;
  };
})
