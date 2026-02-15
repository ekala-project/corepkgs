{
  v6_3 = rec {
    version = "6.3.0";
    src-urls = [
      "mirror://gnu/gmp/gmp-${version}.tar.bz2"
      "ftp://ftp.gmplib.org/pub/gmp-${version}/gmp-${version}.tar.bz2"
    ];
    src-hash = "sha256-rCghGnz7YJuuLiyNYFjWbI/pZDT3QM9v4uR7AA0cIMs=";
    withCxx = false;
  };

  withCxx = {
    withCxx = true;
  };
}
