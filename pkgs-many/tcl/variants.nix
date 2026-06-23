{
  v8_5 = {
    version = "8.5.19";
    src-hash = "sha256-0/BEVtqHPRfwLvwwc0sDAPtsO4UCjURf4oS4MlOm2xg=";
    extraPatch = ''
      substituteInPlace 'generic/tclInt.h' --replace-fail 'typedef int ptrdiff_t;' ""
    '';
  };
  v8_6 = {
    version = "8.6.16";
    src-hash = "sha256-kcuPphdxxjwmLvtVMFm3x61nV6+lhXr2Jl5LC9wqFKU=";
  };
  v9_0 = {
    version = "9.0.1";
    src-hash = "sha256-NWwCQGyaUzfTgHqpib4lLeflULWKuLE4qYxP+0EizHs=";
  };
}
