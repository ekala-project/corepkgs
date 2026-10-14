{
  lib,
  buildPythonPackage,
  flit,
}:

buildPythonPackage (finalAttrs: {
  pname = "flit-core";
  inherit (flit) version;
  format = "pyproject";

  inherit (flit) src patches;

  postPatch = "cd flit_core";

  passthru.tests = {
    inherit flit;
  };

  pythonImportsCheck = [ "flit_core" ];

  meta = {
    description = "Distribution-building parts of Flit. See flit package for more information";
    homepage = "https://github.com/pypa/flit";
    changelog = "https://github.com/pypa/flit/blob/${finalAttrs.src.rev}/doc/history.rst";
    license = lib.licenses.bsd3;

  };
})
