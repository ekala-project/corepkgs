# Build the test driver package

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  # Import the Python test driver package
  testDriverPkg = pkgs.callPackage ../test-driver { };

  # List of VM start scripts
  vmStartScripts = mapAttrsToList (name: node: "${node.vm}") config.builtNodes;

  # Build the driver executable
  driverScript = pkgs.writeScript "ekaos-test-driver" ''
    #!${pkgs.python3}/bin/python3

    import sys
    import os

    # Add test driver to path
    sys.path.insert(0, "${testDriverPkg}/${pkgs.python3.sitePackages}")

    # Set environment variables for test script
    os.environ["TEST_SCRIPT"] = "${config.testScriptFile}"
    os.environ["TEST_NAME"] = "${config.name}"

    # Execute the test script
    with open("${config.testScriptFile}", "r") as f:
        test_code = f.read()

    try:
        exec(test_code)
        print("\n=== Test '${config.name}' PASSED ===")
        sys.exit(0)
    except Exception as e:
        print(f"\n=== Test '${config.name}' FAILED ===")
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
  '';

in

{
  options = {
    driver = mkOption {
      type = types.package;
      internal = true;
      description = "Test driver package";
    };
  };

  config = {
    driver =
      pkgs.runCommand "ekaos-test-driver-${config.name}"
        {
          preferLocalBuild = true;
        }
        ''
          mkdir -p $out/bin
          ln -s ${driverScript} $out/bin/ekaos-test-driver
          chmod +x $out/bin/ekaos-test-driver

          # Store VM scripts for reference
          mkdir -p $out/vm-scripts
          ${concatStringsSep "\n" (
            mapAttrsToList (name: node: ''
              ln -s ${node.vm} $out/vm-scripts/${name}
            '') config.builtNodes
          )}
        '';
  };
}
