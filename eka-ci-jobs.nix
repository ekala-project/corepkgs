let
  pkgs = import ./. { };
in
  { inherit (pkgs) stdenv gcc cmake openssl sphinx python3; }
