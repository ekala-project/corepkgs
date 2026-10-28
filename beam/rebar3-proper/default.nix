{
  lib,
  buildRebar3,
  fetchHex,
}:

buildRebar3 (finalAttrs: {
  name = "rebar3_proper";
  version = "0.12.1";

  src = fetchHex {
    pkg = finalAttrs.name;
    inherit (finalAttrs) version;
    sha256 = "1f174fb6h2071wr7qbw9aqqvnglzsjlylmyi8215fhrmi38w94b6";
  };

  meta = {
    description = "rebar3 proper plugin";
    license = lib.licenses.bsd3;
    homepage = "https://github.com/ferd/rebar3_proper";
    platforms = lib.platforms.unix;
  };
})
