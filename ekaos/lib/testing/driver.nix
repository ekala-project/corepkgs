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

  # ptpython backs the --interactive REPL
  python = pkgs.python3.withPackages (ps: [ ps.ptpython ]);

  # Build the driver executable
  driverScript = pkgs.writeScript "ekaos-test-driver" ''
    #!${python}/bin/python3

    import argparse
    import os
    import sys

    parser = argparse.ArgumentParser(prog="ekaos-test-driver")
    parser.add_argument(
        "-I",
        "--interactive",
        action="store_true",
        help="drop into a python repl instead of running the test script",
    )
    args = parser.parse_args()

    # Add test driver to path
    sys.path.insert(0, "${testDriverPkg}/${pkgs.python3.sitePackages}")

    # socat backs Machine.shell_interact()
    os.environ["PATH"] = "${pkgs.socat}/bin:" + os.environ.get("PATH", "")

    # Set environment variables for test script
    os.environ["TEST_SCRIPT"] = "${config.testScriptFile}"
    os.environ["TEST_NAME"] = "${config.name}"

    from test_driver import shutdown_all


    def run_file(path, symbols):
        with open(path, "r") as f:
            exec(compile(f.read(), path, "exec"), symbols)


    # The prelude defines the machines; the test script and the REPL share
    # its namespace.
    symbols = {"__name__": "__main__"}
    run_file("${config.testPreludeFile}", symbols)


    def test_script():
        """Run the test script against the current machines"""
        run_file("${config.testScriptFile}", symbols)


    symbols["test_script"] = test_script

    if args.interactive:
        from ptpython.repl import embed

        print(
            "ekaosTest '${config.name}' interactive driver\n"
            "  machines: ${concatStringsSep ", " (attrNames config.builtNodes)}\n"
            "  try: start_all(), test_script(), <machine>.shell_interact(),\n"
            "       <machine>.console_interact()"
        )
        try:
            embed(
                globals=symbols,
                history_filename=os.path.join(os.getcwd(), ".ekaos-test-history"),
                patch_stdout=True,
            )
        finally:
            shutdown_all()
        sys.exit(0)

    status = 0
    try:
        test_script()
    except SystemExit as e:
        status = e.code or 0
    except Exception as e:
        print(f"\n=== Test '${config.name}' FAILED ===")
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        status = 1
    finally:
        shutdown_all()

    if status == 0:
        print("\n=== Test '${config.name}' PASSED ===")
    sys.exit(status)
  '';

in

{
  options = {
    driver = mkOption {
      type = types.package;
      internal = true;
      description = "Test driver package";
    };

    driverInteractive = mkOption {
      type = types.package;
      internal = true;
      description = "Test driver that starts in the interactive REPL";
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

          # Store VM scripts for reference
          mkdir -p $out/vm-scripts
          ${concatStringsSep "\n" (
            mapAttrsToList (name: node: ''
              ln -s ${node.vm} $out/vm-scripts/${name}
            '') config.builtNodes
          )}
        '';

    driverInteractive = pkgs.writeShellScriptBin "ekaos-test-driver" ''
      exec ${config.driver}/bin/ekaos-test-driver --interactive "$@"
    '';
  };
}
