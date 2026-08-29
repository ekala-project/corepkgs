lib:

originalArgs:

# A special kind of derivation that is only meant to be consumed by the
# nix-shell. Merges the original derivation's build inputs with
# user-supplied overrides.
{
  name ? if originalArgs ? name then "${originalArgs.name}-dev-shell" else "nix-shell",
  # a list of packages to add to the shell environment
  packages ? [ ],
  # propagate all the inputs from the given derivations
  inputsFrom ? [ ],
  buildInputs ? [ ],
  nativeBuildInputs ? [ ],
  propagatedBuildInputs ? [ ],
  propagatedNativeBuildInputs ? [ ],
  ...
}@attrs:
let
  mergeInputs =
    name:
    (originalArgs.${name} or [ ])
    ++ (attrs.${name} or [ ])
    # 1. get all `{build,nativeBuild,...}Inputs` from the elements of `inputsFrom`
    # 2. since that is a list of lists, `flatten` that into a regular list
    # 3. filter out of the result everything that's in `inputsFrom` itself
    #    this leaves actual dependencies of the derivations in `inputsFrom`,
    #    but never the derivations themselves
    ++ (lib.subtractLists inputsFrom (lib.flatten (lib.catAttrs name inputsFrom)));

  rest = builtins.removeAttrs attrs [
    "name"
    "packages"
    "inputsFrom"
    "buildInputs"
    "nativeBuildInputs"
    "propagatedBuildInputs"
    "propagatedNativeBuildInputs"
    "shellHook"
  ];
in
originalArgs
// {
  inherit name;

  buildInputs = mergeInputs "buildInputs";
  nativeBuildInputs = packages ++ (mergeInputs "nativeBuildInputs");
  propagatedBuildInputs = mergeInputs "propagatedBuildInputs";
  propagatedNativeBuildInputs = mergeInputs "propagatedNativeBuildInputs";

  # Shell derivations only need a single output
  outputs = [ "out" ];

  # Avoid explicit checkout, and assume that shell will be used on source in repo
  src = null;

  shellHook = lib.concatStringsSep "\n" (
    lib.catAttrs "shellHook" (lib.reverseList inputsFrom ++ [ attrs ])
  );

  phases = [ "buildPhase" ];

  buildPhase = ''
    { echo "------------------------------------------------------------";
      echo " WARNING: the existence of this path is not guaranteed.";
      echo " It is an internal implementation detail for pkgs.mkShell.";
      echo "------------------------------------------------------------";
      echo;
      # Record all build inputs as runtime dependencies
      export;
    } >> "$out"
  '';

  preferLocalBuild = true;
}
// rest
