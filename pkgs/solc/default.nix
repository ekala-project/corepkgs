# solc — Solidity compiler for Ethereum smart contracts
{
  lib,
  stdenv,
  fetchzip,
  boost,
  cmake,
}:

stdenv.mkDerivation rec {
  pname = "solc";
  version = "0.8.37";

  src = fetchzip {
    url = "https://github.com/ethereum/solidity/releases/download/v${version}/solidity_${version}.tar.gz";
    hash = "sha256-RQmyCTM8Fzkh3J7vkMKd6ZGcTojmSM4RjALaPsJ0rDE=";
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
}
