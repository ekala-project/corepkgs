{
  stdenv,
  python,
  flit-core,
  installer,
}:

stdenv.mkDerivation {
  pname = "${python.libPrefix}-bootstrap-${installer.pname}";
  inherit (installer)
    version
    src
    patches
    meta
    ;

  buildPhase = ''

    PYTHONPATH="${flit-core}/${python.sitePackages}" \
      ${python.interpreter} -m flit_core.wheel

  '';

  installPhase = ''

    PYTHONPATH=src ${python.interpreter} -m installer \
      --destdir "$out" --prefix "" dist/installer-*.whl

  '';
}
