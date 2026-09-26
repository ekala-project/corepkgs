# Adios port of ekaos/modules/misc/assertions.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, ... }:

{
  options = {
    assertions = {
      type = types.listOf types.any;
      default = [ ];
      description = ''
        List of assertions to check at evaluation time.
        Each assertion should be an attribute set with:
        - assertion: a boolean expression
        - message: error message to show if assertion fails
      '';
      example = [
        {
          assertion = true;
          message = "Service foo requires service bar to be enabled";
        }
      ];
    };

    warnings = {
      type = types.listOf types.string;
      default = [ ];
      description = ''
        List of warnings to display during evaluation.
        Warnings do not cause evaluation to fail.
      '';
      example = [
        "The foo option is deprecated, please use bar instead"
      ];
    };
  };

  impl =
    { options, ... }:
    let
      failedAssertions = builtins.filter (x: !x.assertion) options.assertions;
    in
    if failedAssertions != [ ] then
      builtins.throw "Failed assertions:\n${
        builtins.concatStringsSep "\n" (builtins.map (x: "- ${x.message}") failedAssertions)
      }"
    else if options.warnings != [ ] then
      builtins.trace
        "Warnings:\n${builtins.concatStringsSep "\n" (builtins.map (x: "- ${x}") options.warnings)}"
        {
          # Dummy dependency so assertions/warnings are checked on build.
          system.extraDependencies = [ ];
        }
    else
      {
        system.extraDependencies = [ ];
      };
}
