# Test script configuration and processing

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  # Generate Python code to define machine objects
  machinesPython = concatStringsSep "\n" (
    mapAttrsToList (name: node: ''
      ${name} = Machine("${name}", "${node.vm}")
      register_machine(${name})
    '') config.builtNodes
  );

  # Machine definitions, run before the test script or the interactive
  # REPL. Its globals are the namespace the test script runs in.
  testPrelude = ''
    # Auto-generated ekaosTest prelude

    import os
    import sys
    from test_driver import Machine, register_machine, start_all, shutdown_all, subtest

    # Define machines
    ${machinesPython}
  '';

in

{
  options = {
    testScript = mkOption {
      type = types.either types.str (types.functionTo types.str);
      description = ''
        Python test script to execute.

        Can be a string or a function that takes nodes as argument:
          testScript = nodes: ''' ... ''';

        The script has access to machine objects with test primitives:
        - machine.start()
        - machine.wait_for_unit("service")
        - machine.succeed("command")
        - machine.wait_for_open_port(port)
        etc.
      '';
      example = literalExpression ''
        '''
          start_all()
          machine.wait_for_unit("multi-user.target")
          machine.succeed("systemctl status")
          machine.shutdown()
        '''
      '';
    };

    testScriptString = mkOption {
      type = types.str;
      internal = true;
      description = "Processed test script as string";
    };

    testScriptFile = mkOption {
      type = types.package;
      internal = true;
      description = "Test script written to file";
    };

    testPreludeFile = mkOption {
      type = types.package;
      internal = true;
      description = "Machine definitions run before the test script or REPL";
    };
  };

  config = {
    # Convert testScript to string if it's a function
    testScriptString =
      if isFunction config.testScript then config.testScript config.builtNodes else config.testScript;

    testScriptFile = pkgs.writeText "test-script.py" config.testScriptString;
    testPreludeFile = pkgs.writeText "test-prelude.py" testPrelude;
  };
}
