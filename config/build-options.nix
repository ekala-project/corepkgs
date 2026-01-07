{ lib, ... }:

let
  inherit (lib)
    mkOption
    types
    ;

  mkMassRebuild =
    args:
    mkOption (
      lib.removeAttrs args [ "feature" ]
      // {
        type = args.type or (types.uniq types.bool);
        default = args.default or false;
        description = (
          (args.description or ''
            Whether to ${args.feature} while building nixpkgs packages.
          ''
          )
          + ''
            Changing the default may cause a mass rebuild.
          ''
        );
      }
    );

in
{
  options = {

    # Internal stuff

    # Hide built-in module system options from docs.
    _module.args = mkOption {
      internal = true;
    };

    warnings = mkOption {
      type = types.listOf types.str;
      default = [ ];
      internal = true;
    };

    inHydra = mkOption {
      type = types.bool;
      default = false;
      internal = true;
    };

    # Config options

    warnUndeclaredOptions = mkOption {
      description = "Whether to warn when `config` contains an unrecognized attribute.";
      type = types.bool;
      default = false;
    };

    doCheckByDefault = mkMassRebuild {
      feature = "run `checkPhase` by default";
    };

    strictDepsByDefault = mkMassRebuild {
      feature = "set `strictDeps` to true by default";
    };

    structuredAttrsByDefault = mkMassRebuild {
      feature = "set `__structuredAttrs` to true by default";
    };

    enableParallelBuildingByDefault = mkMassRebuild {
      feature = "set `enableParallelBuilding` to true by default";
    };

    configurePlatformsByDefault = mkMassRebuild {
      feature = "set `configurePlatforms` to `[\"build\" \"host\"]` by default";
    };

    contentAddressedByDefault = mkMassRebuild {
      feature = "set `__contentAddressed` to true by default";
    };

    cudaSupport = mkMassRebuild {
      type = types.bool;
      default = false;
      feature = "build packages with CUDA support by default";
    };

    rocmSupport = mkMassRebuild {
      type = types.bool;
      default = false;
      feature = "build packages with ROCm support by default";
    };
  };
}
