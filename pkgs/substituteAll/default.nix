{ lib, stdenvNoCC }:

/**
  `substituteAll` is a thin wrapper around the [bash function `substituteAll`](https://nixos.org/manual/nixpkgs/stable/#fun-substituteAll)
  in the stdenv. It writes the file `src` to `$out`, replacing any occurrence
  of `@varName@` with the value of the attribute `varName` from the call's
  arguments (or from the inheritance of the derivation's environment).

  Unlike `replaceVars`, this is the legacy interface kept for compatibility
  with third-party packages: it does NOT fail on unsubstituted `@name@`
  occurrences. Prefer `replaceVars` for new code.

  # Inputs

  `src` ([Store Path](https://nixos.org/manual/nix/latest/store/store-path.html#store-path) String)
  : The file in which to substitute variables.

  `dir` (String, optional)
  : Sub directory under `$out` where the result should be written.

  `isExecutable` (Boolean, optional)
  : Whether to chmod +x the result.

  Other attributes are passed through to `stdenvNoCC.mkDerivation` *and*
  exported as environment variables visible to `substituteAll` (which is how
  the `@var@` replacements get their values).

  # Example

  ```nix
  substituteAll {
    src = ./greeting.txt;
    name = "greeting.txt";
    world = "hello";
  }
  ```
*/
args@{
  src,
  ...
}:

let
  # Attrs consumed by the builder script or mkDerivation — not substitution variables.
  builderAttrs = [
    "src"
    "name"
    "isExecutable"
    "dir"
    "preInstall"
    "postInstall"
  ];
in

stdenvNoCC.mkDerivation (
  {
    name = if args ? name then args.name else baseNameOf (toString src);
    inherit src;
    preferLocalBuild = true;
    allowSubstitutes = false;
    builder = ./substitute-all-builder.sh;

    # Substitution variables go through `env` so they are exported and
    # visible to the `substituteAll` bash function under structuredAttrs.
    env = builtins.removeAttrs args builderAttrs;
  }
  # Pass through optional builder attrs (dir, isExecutable, etc.)
  // lib.optionalAttrs (args ? dir) { inherit (args) dir; }
  // lib.optionalAttrs (args ? isExecutable) { inherit (args) isExecutable; }
  // lib.optionalAttrs (args ? preInstall) { inherit (args) preInstall; }
  // lib.optionalAttrs (args ? postInstall) { inherit (args) postInstall; }
)
