{
  # Julia 1.10 LTS
  v1_10 = rec {
    version = "1.10.12";
    src-url = "https://github.com/JuliaLang/julia/releases/download/v${version}/julia-${version}-full.tar.gz";
    src-hash = "sha256-KIFenIPyMWflO9SnnAhea5VHrigIrLI0FatcVYqFzuw=";
  };

  # Julia 1.12 (current stable)
  v1_12 = rec {
    version = "1.12.7";
    src-url = "https://github.com/JuliaLang/julia/releases/download/v${version}/julia-${version}-full.tar.gz";
    src-hash = "sha256-XH2Ft3HeMYXuyp+8LmFz2Lz2109oQYYiqenEOtdSr1E=";
  };
}
