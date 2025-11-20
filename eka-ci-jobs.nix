let
  pkgs = import ./. { };
in
  { inherit (pkgs) stdenv gcc; }
