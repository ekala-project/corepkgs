{
  v8_5 = {
    version = "8.5.19";
    src-hash = "066vlr9k5f44w9gl9382hlxnryq00d5p6c7w5vq1fgc7v9b49w6k";
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
