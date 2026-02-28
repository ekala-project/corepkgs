# Translate common service options to launchd plist files
{ lib, pkgs }:

let
  inherit (lib)
    concatStringsSep
    concatMapStringsSep
    optionalString
    optionalAttrs
    mapAttrs
    mapAttrsToList
    filterAttrs
    escapeShellArg
    attrValues
    flatten
    isList
    ;

  # Convert Nix attrset to XML plist format
  # This is a simplified plist generator - for production use, consider using pkgs.formats.plist
  toPlist = value:
    let
      indent = depth: concatStringsSep "" (lib.genList (_: "  ") depth);

      valueToPlist = depth: val:
        if lib.isBool val then
          if val then "<true/>" else "<false/>"
        else if lib.isInt val then
          "<integer>${toString val}</integer>"
        else if lib.isString val then
          "<string>${val}</string>"
        else if lib.isList val then
          ''
            <array>
            ${concatMapStringsSep "\n" (v: "${indent (depth + 1)}${valueToPlist (depth + 1) v}") val}
            ${indent depth}</array>''
        else if lib.isAttrs val then
          ''
            <dict>
            ${concatStringsSep "\n" (mapAttrsToList (k: v: ''
              ${indent (depth + 1)}<key>${k}</key>
              ${indent (depth + 1)}${valueToPlist (depth + 1) v}'') val)}
            ${indent depth}</dict>''
        else
          throw "Unsupported type in plist: ${builtins.typeOf val}";
    in
    ''
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      ${valueToPlist 0 value}
      </plist>
    '';

  # Generate ProgramArguments array from command and args
  mkProgramArguments = { command, args, preStart ? "", ... }:
    let
      cmd = toString command;
      # If we have preStart commands, wrap everything in a shell script
      needsWrapper = preStart != "";
      wrapperScript = pkgs.writeScript "launchd-wrapper" ''
        #!${pkgs.bash}/bin/bash
        set -e

        # Run preStart commands
        ${preStart}

        # Execute main command
        exec ${cmd} ${concatStringsSep " " (map escapeShellArg args)}
      '';
    in
    if needsWrapper then
      [ (toString wrapperScript) ]
    else
      [ cmd ] ++ args;

  # Generate EnvironmentVariables dict
  mkEnvironmentVariables = env: path:
    let
      # Convert package list to PATH string
      pathString =
        let
          paths = map (pkg: "${pkg}/bin:${pkg}/sbin") path;
        in
        if paths != [] then concatStringsSep ":" paths else "";

      # Convert environment values to strings
      envStrings = mapAttrs (name: value:
        let
          val = if lib.isDerivation value then
                  value
                else if lib.isPath value then
                  toString value
                else
                  value;
        in
        toString val
      ) env;

      # Add PATH if we have packages
      withPath = if pathString != "" then
        envStrings // { PATH = pathString; }
      else
        envStrings;
    in
    if withPath != {} then withPath else null;

  # Convert restart policy to KeepAlive
  mkKeepAlive = policy:
    {
      always = true;
      on-failure = { SuccessfulExit = false; };
      on-abnormal = { SuccessfulExit = false; };  # Similar to on-failure for launchd
      on-abort = { SuccessfulExit = false; };      # Similar to on-failure for launchd
      on-watchdog = { SuccessfulExit = false; };   # Similar to on-failure for launchd
      never = false;
    }.${policy};

  # Convert launchd keepAlive option (might override restart policy)
  mkKeepAliveFromConfig = launchdConfig: defaultKeepAlive:
    if launchdConfig ? keepAlive then
      if lib.isBool launchdConfig.keepAlive then
        launchdConfig.keepAlive
      else
        # Build conditional keepAlive dict, filtering out null values
        let
          conditions = filterAttrs (n: v: v != null) {
            SuccessfulExit = launchdConfig.keepAlive.successfulExit or null;
            NetworkState = launchdConfig.keepAlive.networkState or null;
            PathState = launchdConfig.keepAlive.pathState or null;
            OtherJobEnabled = launchdConfig.keepAlive.otherJobEnabled or null;
          };
        in
        if conditions != {} then conditions else true
    else
      defaultKeepAlive;

  # Convert StartCalendarInterval to plist format
  mkStartCalendarInterval = interval:
    if interval == null then
      null
    else if isList interval then
      # Multiple intervals
      map (i: filterAttrs (n: v: v != null) {
        Minute = i.minute or null;
        Hour = i.hour or null;
        Day = i.day or null;
        Weekday = i.weekday or null;
        Month = i.month or null;
      }) interval
    else
      # Single interval
      filterAttrs (n: v: v != null) {
        Minute = interval.minute or null;
        Hour = interval.hour or null;
        Day = interval.day or null;
        Weekday = interval.weekday or null;
        Month = interval.month or null;
      };

  # Build the complete plist dict
  buildPlistDict = config:
    let
      launchdCfg = config.launchd or {};

      # Base KeepAlive from common restart policy
      baseKeepAlive = mkKeepAlive config.restartPolicy;

      # Override with launchd-specific keepAlive if present
      keepAlive = mkKeepAliveFromConfig launchdCfg baseKeepAlive;

      # Environment variables
      envVars = mkEnvironmentVariables config.environment config.path;

      # Program arguments
      programArgs = mkProgramArguments {
        inherit (config) command args preStart;
      };

      # Start calendar interval
      calendarInterval = mkStartCalendarInterval (launchdCfg.startCalendarInterval or null);

      # Resource limits
      softLimits = launchdCfg.softResourceLimits or {};
      hardLimits = launchdCfg.hardResourceLimits or {};

      # Build the base plist
      basePlist = filterAttrs (n: v: v != null) {
        # Required
        Label = launchdCfg.label or "org.nixos.${config.description}";
        ProgramArguments = programArgs;

        # Common options
        RunAtLoad = if launchdCfg ? runAtLoad then launchdCfg.runAtLoad else null;
        KeepAlive = if keepAlive == false then null else keepAlive;  # Omit if false

        # Working directory
        WorkingDirectory = if config.workingDirectory != null
          then toString config.workingDirectory
          else null;

        # User context
        UserName = if config.user != "root" then config.user else null;
        GroupName = if config.group != "root" then config.group else null;

        # Environment
        EnvironmentVariables = envVars;

        # I/O redirection
        StandardOutPath = config.stdout or null;
        StandardErrorPath = config.stderr or null;
        StandardInPath = launchdCfg.standardInPath or null;

        # Event triggers
        WatchPaths = if (launchdCfg.watchPaths or []) != []
          then map toString launchdCfg.watchPaths
          else null;
        QueueDirectories = if (launchdCfg.queueDirectories or []) != []
          then map toString launchdCfg.queueDirectories
          else null;

        # Scheduling
        StartInterval = launchdCfg.startInterval or null;
        StartCalendarInterval = calendarInterval;

        # Process management
        ProcessType = if launchdCfg.processType != "Standard"
          then launchdCfg.processType
          else null;
        Nice = launchdCfg.nice or null;

        # Resource limits
        SoftResourceLimits = if softLimits != {} then softLimits else null;
        HardResourceLimits = if hardLimits != {} then hardLimits else null;

        # Timeout
        ExitTimeOut = launchdCfg.exitTimeout or null;

        # Security
        Umask = launchdCfg.umask or null;
        SessionCreate = if launchdCfg.sessionCreate then true else null;

        # Additional options
        EnableTransactions = if launchdCfg.enableTransactions then true else null;
        AbandonProcessGroup = if launchdCfg.abandonProcessGroup then true else null;
      };

      # Merge with extraConfig
      extraCfg = launchdCfg.extraConfig or {};
    in
    basePlist // extraCfg;

  # Generate postStart script if needed
  mkPostStartScript = config:
    if config.postStart != "" then
      pkgs.writeScript "poststart" ''
        #!${pkgs.bash}/bin/bash
        set -e
        ${config.postStart}
      ''
    else
      null;

  # Generate postStop script if needed
  mkPostStopScript = config:
    if config.postStop != "" then
      pkgs.writeScript "poststop" ''
        #!${pkgs.bash}/bin/bash
        set -e
        ${config.postStop}
      ''
    else
      null;

  # Main translation function
  toLaunchdPlist = config:
    let
      plistDict = buildPlistDict config;
      plistContent = toPlist plistDict;

      # Note: postStart and postStop are not directly supported by launchd
      # They need to be handled by wrapper scripts or external tools
      postStartScript = mkPostStartScript config;
      postStopScript = mkPostStopScript config;

      # Warning message if postStart/postStop are used
      warnings =
        lib.optional (config.postStart != "")
          "WARNING: postStart is not natively supported by launchd for service '${config.description}'. Consider using a wrapper script." ++
        lib.optional (config.postStop != "")
          "WARNING: postStop is not natively supported by launchd for service '${config.description}'. Consider using a wrapper script.";
    in
    {
      inherit plistContent postStartScript postStopScript warnings;
    };

in
{
  inherit toLaunchdPlist;

  # Helper to generate just the plist content
  toPlistFile = config: (toLaunchdPlist config).plistContent;
}
