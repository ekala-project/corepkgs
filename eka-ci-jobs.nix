let
  pkgs = import ./. { };
in
  { inherit (pkgs) stdenv gcc cmake sphinx python3 c-ares; }
