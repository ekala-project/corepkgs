# Assertion checking for ekaos
# Allows modules to define assertions that are checked at evaluation time
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
      default = [];
      description = ''
        List of assertions to check at evaluation time.
        Each assertion should be an attribute set with:
        - assertion: a boolean expression
        - message: error message to show if assertion fails
      '';
      example = literalExpression ''
        [
          {
            assertion = config.services.foo.enable -> config.services.bar.enable;
            message = "Service foo requires service bar to be enabled";
          }
        ]
      '';
    };

    warnings = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        List of warnings to display during evaluation.
        Warnings do not cause evaluation to fail.
      '';
      example = literalExpression ''
        [
          "The foo option is deprecated, please use bar instead"
        ]
      '';
    };
  };

  config = let
    # Check assertions at evaluation time
    # This will throw an error if any assertion fails
    failedAssertions = filter (x: !x.assertion) config.assertions;

    # Force evaluation of assertions when system.build.toplevel is accessed
    assertionsCheck =
      if failedAssertions != []
      then throw "\nFailed assertions:\n${
        concatMapStringsSep "\n" (x: "- ${x.message}") failedAssertions
      }"
      else null;

    # Display warnings when evaluated
    warningsCheck =
      if config.warnings != []
      then builtins.trace "\nWarnings:\n${
        concatMapStringsSep "\n" (x: "- ${x}") config.warnings
      }" null
      else null;
  in {
    # Force assertions and warnings to be checked by adding dummy dependency
    # This ensures they're evaluated when the system is built
    system.extraDependencies = mkIf (assertionsCheck == null && warningsCheck == null) [];
  };
}
