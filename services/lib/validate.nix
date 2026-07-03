# Service configuration validation
# Checks for incompatible options, missing dependencies, and configuration conflicts
{ lib, pkgs }:

let
  inherit (lib)
    optional
    optionals
    concatStringsSep
    concatMapStringsSep
    attrNames
    hasAttr
    ;

  # Validation result type
  mkError = message: {
    type = "error";
    inherit message;
  };
  mkWarning = message: {
    type = "warning";
    inherit message;
  };

  # Check if a platform-specific option section has any actual values set
  # We need to filter out empty strings, empty lists, null, empty attrsets, and default scalars
  # This is complex because the module system creates default values for all options
  hasPlatformOptions =
    platformName: platformOpts:
    let
      # List of keys that commonly have non-empty defaults but shouldn't count as "user-specified"
      # These are set by the module system's default values
      ignoredKeys = {
        # systemd defaults
        systemd = [ "wantedBy" ]; # Has default ["default.target"] or ["multi-user.target"]
        # rcd defaults
        rcd = [
          "variant"
          "rcProvide"
          "rcRequire"
          "rcKeywords"
        ]; # All have non-trivial defaults
        # runit defaults
        runit = [ "superviseDirectory" ]; # Has default "/etc/sv/${name}"
        # launchd defaults
        launchd = [
          "runAtLoad"
          "keepAlive"
          "processType"
          "sessionCreate"
          "enableTransactions"
          "abandonProcessGroup"
          "label"
        ];
      };

      keysToIgnore = ignoredKeys.${platformName} or [ ];

      # Check if a key-value pair is meaningful (not a default)
      isMeaningful =
        key: value:
        # Ignore keys that have module-defined defaults
        if builtins.elem key keysToIgnore then
          false
        # Null, empty string, empty list, empty attrset are all "not set"
        else if value == null then
          false
        else if value == "" then
          false
        else if value == [ ] then
          false
        else if lib.isAttrs value then
          value != { }
        else
          true; # Non-empty scalar value

      # Check all key-value pairs
      meaningfulPairs = lib.filterAttrs isMeaningful platformOpts;
    in
    meaningfulPairs != { };

  # Check for platform-specific options used on wrong builder
  checkPlatformSpecificOptions =
    builder: config:
    let
      # Check each platform-specific section
      checkPlatform =
        platform:
        if platform == builder then
          [ ]
        else if hasAttr platform config then
          optional (hasPlatformOptions platform config.${platform}) (
            mkError "Using ${platform}.* options in ${builder} build - these options will be ignored"
          )
        else
          [ ];

      platforms = [
        "systemd"
        "launchd"
        "runit"
        "rcd"
      ];
    in
    lib.concatMap checkPlatform platforms;

  # Check for unsupported common options on specific platforms
  checkUnsupportedCommonOptions =
    builder: config:
    let
      warnings =
        [ ]
        # postStart/postStop warnings for launchd
        ++ optional (builder == "launchd" && config.postStart != "") (
          mkWarning "postStart hook has limited support on launchd - may need wrapper script"
        )
        ++ optional (builder == "launchd" && config.postStop != "") (
          mkWarning "postStop hook has limited support on launchd - may need wrapper script"
        )

        # restartPolicy warnings for rc.d
        ++ optional (builder == "rcd" && config.restartPolicy != "never") (
          mkWarning "restartPolicy '${config.restartPolicy}' not supported on BSD rc.d - services don't auto-restart on failure"
        )

        # User switching warnings (when not using platform with native support)
        ++
          optional
            (
              (config.user or "root") != "root"
              && builder == "rcd"
              && (config.rcd.variant or "freebsd") != "openbsd"
            )
            (
              mkWarning "User switching on ${builder} (${
                config.rcd.variant or "freebsd"
              }) may require manual setup with daemon(8) or su(1)"
            )

        # Working directory warnings
        ++ optional ((config.workingDirectory or null) != null && builder == "rcd") (
          mkWarning "Working directory requires cd in precmd on ${builder} - generated automatically"
        );
    in
    warnings;

  # Check port contract consistency for a single service
  checkPortContractConsistency =
    name: config:
    let
      portContracts = config.ports or { };
      httpTransports = [
        "http"
        "https"
        "http2"
        "grpc"
      ];
    in
    lib.concatLists (
      lib.mapAttrsToList (
        portName: pc:
        let
          prefix = "service '${name}' port '${portName}'";
        in
        [ ]
        # tls.acme requires hostname
        ++ optional (pc.tls.acme or false && pc.hostname or null == null) (
          mkError "${prefix}: tls.acme = true requires hostname to be set"
        )
        # tls.acme requires HTTP-family transport
        ++ optional (pc.tls.acme or false && !(builtins.elem (pc.transport or "http") httpTransports)) (
          mkError "${prefix}: tls.acme = true requires transport to be http, https, http2, or grpc"
        )
        # healthCheck.path requires HTTP-family transport
        ++ optional (
          pc.healthCheck.path or null != null && !(builtins.elem (pc.transport or "http") httpTransports)
        ) (mkWarning "${prefix}: healthCheck.path is set but transport '${pc.transport}' is not HTTP-based")
        # openFirewall + internal is contradictory
        ++ optional (pc.openFirewall or false && pc.internal or false) (
          mkWarning "${prefix}: openFirewall = true with internal = true is contradictory"
        )
      ) portContracts
    );

  # Check for port collisions across all services
  checkPortCollisions =
    services:
    let
      # Collect all (port, protocol, serviceName, portName) tuples
      allPorts = lib.concatLists (
        lib.mapAttrsToList (
          svcName: cfg:
          lib.mapAttrsToList (portName: pc: {
            inherit svcName portName;
            port = pc.port;
            protocol = pc.protocol or "tcp";
            key = "${toString pc.port}/${pc.protocol or "tcp"}";
          }) (cfg.ports or { })
        ) services
      );

      # Group by key
      grouped = lib.groupBy (p: p.key) allPorts;

      # Find collisions (groups with more than one entry)
      collisions = lib.filterAttrs (_: es: builtins.length es > 1) grouped;
    in
    lib.mapAttrsToList (
      key: entries:
      let
        serviceNames = map (e: "${e.svcName}.${e.portName}") entries;
      in
      mkError "Port collision on ${key}: claimed by ${lib.concatStringsSep ", " serviceNames}"
    ) collisions;

  # Check for missing required dependencies
  checkRequiredDependencies =
    config:
    let
      errors =
        [ ]
        # Check if command is empty
        ++ optional (config.command == "" || config.command == null) (
          mkError "command is required but not specified"
        )

      # Note: We can't easily check if command path exists at evaluation time
      # since it might be a store path that doesn't exist yet
      # This would require runtime validation
      ;
    in
    errors;

  # Check for configuration conflicts
  checkConfigConflicts =
    config:
    let
      errors =
        [ ]
        # Check for invalid restart policy
        ++
          optional
            (
              !(builtins.elem config.restartPolicy [
                "always"
                "on-failure"
                "on-abnormal"
                "on-abort"
                "on-watchdog"
                "never"
              ])
            )
            (
              mkError "Invalid restartPolicy '${config.restartPolicy}' - must be one of: always, on-failure, on-abnormal, on-abort, on-watchdog, never"
            )

        # Check for empty description
        ++ optional (config.description == "") (
          mkWarning "description is empty - consider adding a human-readable description"
        )

      # Check for missing args when they might be needed
      # (This is informational, not an error)
      ;
    in
    errors;

  # Main validation function for a single service
  validateService =
    builder: name: config:
    let
      # Run all validation checks
      issues =
        checkPlatformSpecificOptions builder config
        ++ checkUnsupportedCommonOptions builder config
        ++ checkRequiredDependencies config
        ++ checkConfigConflicts config
        ++ checkPortContractConsistency name config;

      # Separate errors and warnings
      errors = builtins.filter (issue: issue.type == "error") issues;
      warnings = builtins.filter (issue: issue.type == "warning") issues;
    in
    {
      inherit name errors warnings;
      hasErrors = errors != [ ];
      hasWarnings = warnings != [ ];
    };

  # Format a single validation result for display
  formatValidationResult =
    result:
    let
      errorLines = map (e: "  × ${e.message}") result.errors;
      warningLines = map (w: "  ⚠ ${w.message}") result.warnings;

      errorSection =
        if result.errors != [ ] then
          "ERRORS (build will fail):\n${concatStringsSep "\n" errorLines}\n"
        else
          "";

      warningSection =
        if result.warnings != [ ] then
          "WARNINGS (build continues):\n${concatStringsSep "\n" warningLines}\n"
        else
          "";

      summary =
        if result.hasErrors then
          "\nBuild failed due to ${toString (builtins.length result.errors)} error(s)"
        else if result.hasWarnings then
          "\nBuild succeeded with ${toString (builtins.length result.warnings)} warning(s)"
        else
          "";
    in
    if result.hasErrors || result.hasWarnings then
      "\nValidating service '${result.name}'...\n\n${errorSection}${warningSection}${summary}\n"
    else
      "";

  # Validate multiple services and throw on errors
  validateServices =
    builder: services:
    let
      # Validate each service
      results = lib.mapAttrsToList (name: config: validateService builder name config) services;

      # Cross-service port collision check
      portCollisionErrors = checkPortCollisions services;

      # Collect all results with issues
      resultsWithIssues = builtins.filter (r: r.hasErrors || r.hasWarnings) results;

      # Check if any have errors (per-service or cross-service)
      anyErrors = builtins.any (r: r.hasErrors) results || portCollisionErrors != [ ];

      # Format all results
      formattedResults = map formatValidationResult resultsWithIssues;
      portCollisionMessages = map (e: "  × ${e.message}") portCollisionErrors;
      portCollisionSection =
        if portCollisionErrors != [ ] then
          "\nPort Collisions:\n${concatStringsSep "\n" portCollisionMessages}\n"
        else
          "";
      allMessages = concatStringsSep "\n" formattedResults + portCollisionSection;
    in
    if anyErrors then
      throw ''

        ═══════════════════════════════════════════════════════════════
        SERVICE CONFIGURATION VALIDATION FAILED
        ═══════════════════════════════════════════════════════════════
        ${allMessages}
        ═══════════════════════════════════════════════════════════════

        Fix the errors above and try again.
      ''
    else if resultsWithIssues != [ ] then
      # Just warnings - use trace to display but continue
      builtins.trace ''

        ═══════════════════════════════════════════════════════════════
        SERVICE CONFIGURATION WARNINGS
        ═══════════════════════════════════════════════════════════════
        ${allMessages}
        ═══════════════════════════════════════════════════════════════
      '' services
    else
      services;

in
{
  inherit
    validateService
    validateServices
    formatValidationResult
    checkPortCollisions
    checkPortContractConsistency
    mkError
    mkWarning
    ;
}
