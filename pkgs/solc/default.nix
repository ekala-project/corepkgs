# solc — Solidity compiler for Ethereum smart contracts
{
  lib,
  stdenv,
  fetchzip,
  boost,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "solc";
  version = "0.8.38";

  src = fetchzip {
    url = "https://github.com/ethereum/solidity/releases/download/v${finalAttrs.version}/solidity_${finalAttrs.version}.tar.gz";
    hash = "sha256-oB9b86sNYV0xuGeLbfOvZub1Z3JviGUmj5VGv30bE9w=";
  };

  nativeBuildInputs = [
    cmake
    cmake.configurePhaseHook
  ];
  buildInputs = [ boost ];

  cmakeEntries = {
    Boost_USE_STATIC_LIBS = false;
    USE_Z3 = false;
    USE_CVC4 = false;
  };

  meta = {
    description = "Compiler for Ethereum smart contract language Solidity";
    homepage = "https://github.com/ethereum/solidity";
    license = lib.licenses.gpl3;
    platforms = lib.platforms.linux;
  };
})
