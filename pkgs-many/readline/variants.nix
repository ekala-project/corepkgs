{
  v7_0 = {
    version = "7.0";
    src-hash = "sha256-dQ1DcYUob0CjaeHk9HZO2pMrlFm17JpzFig5PdPTIzQ=";
    upstreamPatches = import ./readline-7.0-patches.nix;
  };

  v8_3 = {
    version = "8.3";
    src-hash = "sha256-/lODIERngozUle6NHTwDen66E4nCK8agQfYnl2+QYcw=";
    upstreamPatches = import ./readline-8.3-patches.nix;
  };
}
