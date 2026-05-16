{ lib, pkgs }:

let
  inherit (lib)
    concatStringsSep
    escapeShellArg
    optionalString
    mapAttrsToList
    ;

  # Translate restart policy from ekaos to process-compose
  translateRestartPolicy =
    policy:
    if policy == "always" then
      "always"
    else if policy == "on-failure" then
      "on_failure"
    else if policy == "never" then
      "no"
    else
      "on_failure"; # default

  # Build the command string with lifecycle hooks
  buildCommand =
    serviceName: config:
    let
      # Base command with arguments
      baseCommand =
        if config.args != [ ] then
          "${config.command} ${concatStringsSep " " (map escapeShellArg config.args)}"
        else
          config.command;

      # Combine preStart hook with main command
      fullCommand =
        if config.preStart != "" then
          ''
            #!/bin/sh
            set -e
            # preStart hook for ${serviceName}
            ${config.preStart}

            # Main service command
            exec ${baseCommand}
          ''
        else
          ''
            #!/bin/sh
            exec ${baseCommand}
          '';
    in
    fullCommand;

  # Convert service configuration to process-compose process entry
  serviceToProcess =
    serviceName: config:
    let
      # Build environment section
      envSection =
        if config.environment != { } then
          lib.mapAttrs (name: value: toString value) config.environment
        else
          { };

      # Build depends_on section
      after = config.after or [ ];
      dependsSection =
        if after != [ ] then
          lib.listToAttrs (
            map (dep: {
              name = dep;
              value = {
                condition = "process_started";
              };
            }) after
          )
        else
          { };

      # Build the process entry with all fields
      baseEntry = {
        command = buildCommand serviceName config;
        restart = translateRestartPolicy config.restartPolicy;
      };

      # Add optional fields
      withWorkingDir =
        if config.workingDirectory != null then
          baseEntry // { working_dir = config.workingDirectory; }
        else
          baseEntry;

      withEnvironment =
        if envSection != { } then withWorkingDir // { environment = envSection; } else withWorkingDir;

      processEntry =
        if dependsSection != { } then
          withEnvironment // { depends_on = dependsSection; }
        else
          withEnvironment;
    in
    processEntry;

  # Generate process-compose YAML from service configurations
  servicesToProcessCompose =
    services:
    let
      # Filter enabled services
      enabledServices = lib.filterAttrs (name: cfg: cfg.enable) services;

      # Convert each service to a process entry
      processes = lib.mapAttrs serviceToProcess enabledServices;

      # Build the complete configuration
      config = {
        version = "0.5";

        # Log configuration
        log_location = "./.dev/logs";
        log_level = "info";

        # Process definitions
        processes = processes;
      };
    in
    config;

  # Convert Nix attribute set to YAML string
  # This is a simplified YAML generator for our use case
  toYAML =
    attrs:
    let
      indent = level: lib.concatStrings (lib.genList (_: "  ") level);

      escapeString =
        str:
        if lib.hasInfix "\n" str then
          # Multi-line string
          "|\n" + lib.concatMapStringsSep "\n" (line: "  ${line}") (lib.splitString "\n" str)
        else if lib.hasInfix "\"" str || lib.hasInfix ":" str then
          "\"${lib.replaceStrings [ "\"" "\\" ] [ "\\\"" "\\\\" ] str}\""
        else
          str;

      toYAMLValue =
        level: value:
        if builtins.isAttrs value then
          toYAMLAttrs level value
        else if builtins.isList value then
          toYAMLList level value
        else if builtins.isBool value then
          if value then "true" else "false"
        else if builtins.isInt value then
          toString value
        else if builtins.isString value then
          escapeString value
        else
          toString value;

      toYAMLAttrs =
        level: attrs:
        let
          entries = lib.mapAttrsToList (
            name: value: "${indent level}${name}: ${toYAMLValue (level + 1) value}"
          ) attrs;
        in
        if level == 0 then lib.concatStringsSep "\n" entries else "\n" + lib.concatStringsSep "\n" entries;

      toYAMLList =
        level: list:
        let
          entries = map (value: "${indent level}- ${toYAMLValue (level + 1) value}") list;
        in
        "\n" + lib.concatStringsSep "\n" entries;
    in
    toYAMLValue 0 attrs;

  # Build a process-compose configuration file
  buildProcessComposeConfig =
    services:
    let
      config = servicesToProcessCompose services;
      yamlContent = toYAML config;
    in
    pkgs.writeTextFile {
      name = "process-compose.yaml";
      text = yamlContent;
    };

in
{
  inherit
    servicesToProcessCompose
    buildProcessComposeConfig
    toYAML
    ;
}
