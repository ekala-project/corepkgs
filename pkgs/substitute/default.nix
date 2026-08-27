{ lib, stdenvNoCC }:
/*
  This is a wrapper around `substitute` in the stdenv.

  Attribute arguments:
  - `name` (optional): The name of the resulting derivation
  - `src`: The path to the file to substitute
  - `substitutions`: The list of substitution arguments to pass
    See https://nixos.org/manual/nixpkgs/stable/#fun-substitute

  Example:

  ```nix
  { substitute }:
  substitute {
    src = ./greeting.txt;
    substitutions = [
      "--replace"
      "world"
      "paul"
    ];
  }
  ```

  See ../../test/substitute for tests
*/
args:

let
  name = if args ? name then args.name else baseNameOf (toString args.src);
in
stdenvNoCC.mkDerivation (
  {
    inherit name;
    builder = ./substitute.sh;
    inherit (args) src;
    preferLocalBuild = true;
    allowSubstitutes = false;
  }
  // args
  // lib.optionalAttrs (args ? substitutions) {
    substitutions =
      assert lib.assertMsg (lib.isList args.substitutions)
        ''pkgs.substitute: For "${name}", `substitutions` is passed, which is expected to be a list, but it's a ${builtins.typeOf args.substitutions} instead.'';
      lib.escapeShellArgs args.substitutions;
  }
)
