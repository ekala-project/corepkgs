{ lib
, fetchPypi
, python3
}:

python3.pkgs.buildPythonApplication rec {
  pname = "cmake-format";
  version = "0.6.13";
  # The source distribution does not build because of missing files.
  format = "wheel";

  src = fetchPypi {
    inherit version format;
    python = "py3";
    pname = "cmakelang";
    sha256 = "0kmggnfbv6bba75l3zfzqwk0swi90brjka307m2kcz2w35kr8jvn";
  };

  propagatedBuildInputs = (with python3.pkgs; [
    jinja2
    pyyaml
    six
  ]);

  doCheck = false;

  meta = with lib; {
    description = "Source code formatter for cmake listfiles";
    homepage = "https://github.com/cheshirekow/cmake_format";
    license = licenses.gpl3;
    mainProgram = "cmake-format";
    platforms = platforms.all;
  };
}
