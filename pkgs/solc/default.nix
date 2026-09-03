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
  version = "0.8.33";

  src = fetchzip {
    url = "https://github.com/ethereum/solidity/releases/download/v${version}/solidity_${version}.tar.gz";
    hash = "sha256-sWCV0GOUW5GPNX1flk+UOrdwoHZHnx4MsZMGDDBxx6M=";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ boost ];

  cmakeFlags = [
    "-DBoost_USE_STATIC_LIBS=OFF"
    "-DUSE_Z3=OFF"
    "-DUSE_CVC4=OFF"
  ];

  enableParallelBuilding = true;

  meta = {
    description = "Compiler for Ethereum smart contract language Solidity";
    homepage = "https://github.com/ethereum/solidity";
    license = lib.licenses.gpl3;
    platforms = lib.platforms.linux;
  };
}
