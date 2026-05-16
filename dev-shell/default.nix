{ lib, pkgs, stdenv }:

let
  # Import the process-compose translation layer
  pcTranslate = import ../services/lib/process-compose-translate.nix { inherit lib pkgs; };

  # Import service module infrastructure
  serviceLib = import ../services/lib/service-module.nix { inherit lib pkgs; };

  # Simple mkShell implementation (Phase 1 - basic version)
  mkShell = attrs: stdenv.mkDerivation ({
    name = "dev-shell";
    phases = [ "buildPhase" ];
    buildPhase = ''
      echo "This derivation is not meant to be built, only to be used with nix-shell"
      touch $out
    '';
    shellHook = "";
  } // attrs);

in

{
  # Main function: Create a development shell with services
  mkDevShell =
    {
      # Service configuration via ekaos modules
      modules ? [ ],

      # Traditional mkShell options
      packages ? [ ],
      shellHook ? "",
      buildInputs ? [ ],

      # process-compose specific options
      processCompose ? {
        tui = true;
        autoStart = false;
        logDir = "./.dev/logs";
        dataDir = "./.dev/data";
      },

      # Pass-through options for mkShell
      ...
    }@args:

    let
      # Evaluate the service modules
      servicesEval = lib.evalModules {
        modules = [
          {
            options.services = serviceLib.mkServicesOption;
          }
        ] ++ modules;
      };

      # Extract enabled services
      services = servicesEval.config.services or { };
      enabledServices = lib.filterAttrs (_: cfg: cfg.enable or false) services;

      # Build the process-compose configuration
      processComposeConfig = pcTranslate.buildProcessComposeConfig enabledServices;

      # Use real process-compose package
      processComposePackage = pkgs.process-compose;

      # Create utility scripts
      utilities = import ./lib/utilities.nix {
        inherit lib pkgs processComposeConfig;
        processCompose = processComposePackage;
        inherit (processCompose) tui logDir dataDir;
      };

      # Extract non-service options for mkShell
      shellArgs = builtins.removeAttrs args [
        "modules"
        "processCompose"
      ];

      # Build the enhanced shellHook
      enhancedShellHook = ''
        # Create directories for services
        mkdir -p ${processCompose.logDir}
        mkdir -p ${processCompose.dataDir}

        # Display service information
        echo "================================================"
        echo "Development Shell with Services"
        echo "================================================"
        ${lib.optionalString (enabledServices != {}) ''
          echo ""
          echo "Available services:"
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: _: "  echo \"  - ${name}\"") enabledServices)}
          echo ""
          echo "Service management commands:"
          echo "  pc-up       - Start all services (with TUI)"
          echo "  pc-down     - Stop all services"
          echo "  pc-status   - Show service status"
          echo "  pc-logs     - View all service logs"
          echo ""
        ''}
        echo "================================================"
        echo ""

        # User's custom shellHook
        ${shellHook}
      '';

    in
    mkShell (shellArgs // {
      buildInputs = buildInputs
        ++ packages
        ++ [ processComposePackage ]
        ++ (lib.attrValues utilities);

      shellHook = enhancedShellHook;

      # Make process-compose config available as environment variable
      PROCESS_COMPOSE_CONFIG = "${processComposeConfig}";

      # Set data and log directories
      DEV_DATA_DIR = processCompose.dataDir;
      DEV_LOG_DIR = processCompose.logDir;
    });
}
