# Assertion checking for standalone home evaluation
#
# Same interface as assertions.nix but without system.extraDependencies.
# Assertions are checked when home.build.activationPackage is evaluated.
{
  config,
  lib,
  ...
}:

with lib;

{
  options = {
    assertions = mkOption {
      type = types.listOf types.unspecified;
      default = [ ];
      description = "List of assertions to check at evaluation time.";
    };

    warnings = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of warnings to display during evaluation.";
    };
  };

  config =
    let
      failedAssertions = filter (x: !x.assertion) config.assertions;

      assertionsCheck =
        if failedAssertions != [ ] then
          throw "\nFailed assertions:\n${concatMapStringsSep "\n" (x: "- ${x.message}") failedAssertions}"
        else
          null;

      warningsCheck =
        if config.warnings != [ ] then
          builtins.trace "\nWarnings:\n${concatMapStringsSep "\n" (x: "- ${x}") config.warnings}" null
        else
          null;
    in
    {
      # Force assertion/warning evaluation via home.build dependency
      home.users = mkIf (assertionsCheck == null && warningsCheck == null) { };
    };
}
