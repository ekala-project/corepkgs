{ lib }:

let
  rubyVersion = import ./ruby-version.nix { inherit lib; };
in
{
  v3_3 = {
    version = rubyVersion "3" "3" "10" "";
    hash = "sha256-tVW6pGejBs/I5sbtJNDSeyfpob7R2R2VUJhZ6saw6Sg=";
    cargoHash = "sha256-xE7Cv+NVmOHOlXa/Mg72CTSaZRb72lOja98JBvxPvSs=";
  };

  v3_4 = {
    version = rubyVersion "3" "4" "8" "";
    hash = "sha256-U8TdrUH7thifH17g21elHVS9H4f4dVs9aGBBVqNbBFs=";
    cargoHash = "sha256-5Tp8Kth0yO89/LIcU8K01z6DdZRr8MAA0DPKqDEjIt0=";
  };

  v4_0 = {
    version = rubyVersion "4" "0" "0" "preview3";
    hash = "sha256-Q9CSbndvvVWZrcx7zLTMyAThCfQCogaGB6KoZWLCzcA=";
    cargoHash = "sha256-z7NwWc4TaR042hNx0xgRkh/BQEpEJtE53cfrN0qNiE0=";
  };
}
