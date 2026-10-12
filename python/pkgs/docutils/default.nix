{
  lib,
  fetchurl,
  buildPythonPackage,
  flit-core,
  pillow,
  python,
}:

# Note: this package is used to build LLVM’s documentation, which is part of the Darwin stdenv.
# It cannot use `fetchgit` because that would pull curl into the bootstrap, which is disallowed.

buildPythonPackage (finalAttrs: {
  pname = "docutils";
  version = "0.23";
  pyproject = true;

  src = fetchurl {
    url = "mirror://sourceforge/docutils/docutils-${finalAttrs.version}.tar.gz";
    hash = "sha256-dG9QYDIlESgKHlDrdoRu1r8jQphLKsBNxCyqGo14eZ4=";
  };

  build-system = [ flit-core ];

  passthru.tests.pytest = finalAttrs.finalPackage.overridePythonAttrs { doCheck = true; };

  nativeCheckInputs = [ pillow ];

  checkPhase = ''
    ${python.interpreter} test/alltests.py
  '';

  # Create symlinks lacking a ".py" suffix, many programs depend on these names
  postFixup = ''
    for f in $out/bin/*.py; do
      ln -s $(basename $f) $out/bin/$(basename $f .py)
    done
  '';

  pythonImportsCheck = [ "docutils" ];

  meta = {
    description = "Python Documentation Utilities";
    homepage = "http://docutils.sourceforge.net/";
    changelog = "https://sourceforge.net/projects/docutils/files/docutils/${finalAttrs.version}";
    license = with lib.licenses; [
      publicDomain
      bsd2
      psfl
      gpl3Plus
    ];

    mainProgram = "docutils";
  };
})
