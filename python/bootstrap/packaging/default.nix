{
  stdenv,
  python,
  flit-core,
  installer,
  packaging,
}:

stdenv.mkDerivation {
  pname = "${python.libPrefix}-bootstrap-${packaging.pname}";
  inherit (packaging) version src meta;

  buildPhase = ''

    PYTHONPATH="${flit-core}/${python.sitePackages}" \
      ${python.interpreter} -m flit_core.wheel

  '';

  installPhase = ''

    PYTHONPATH="${installer}/${python.sitePackages}" \
      ${python.interpreter} -m installer \
        --destdir "$out" --prefix "" dist/*.whl

  '';
}
