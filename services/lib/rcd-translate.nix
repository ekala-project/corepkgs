# Translate common service options to BSD rc.d scripts
{ lib, pkgs }:

let
  inherit (lib)
    concatStringsSep
    concatMapStringsSep
    optionalString
    mapAttrsToList
    escapeShellArg
    ;

  # Generate rcorder metadata (PROVIDE/REQUIRE/BEFORE/KEYWORD)
  # OpenBSD ignores these, but they don't hurt
  mkRcOrderMetadata =
    config:
    let
      cfg = config.rcd or { };
      provide = concatStringsSep " " cfg.rcProvide;
      require = concatStringsSep " " cfg.rcRequire;
      before = optionalString (cfg.rcBefore != [ ])
        "# BEFORE: ${concatStringsSep " " cfg.rcBefore}";
      keywords = concatStringsSep " " cfg.rcKeywords;
    in
    ''
      # PROVIDE: ${provide}
      # REQUIRE: ${require}
      ${before}
      # KEYWORD: ${keywords}
    '';

  # Generate environment variable exports for shell script
  mkEnvironmentExports =
    env:
    concatStringsSep "\n    " (
      mapAttrsToList (
        name: value:
        let
          val =
            if lib.isDerivation value then
              value
            else if lib.isPath value then
              toString value
            else
              value;
        in
        "export ${name}=${escapeShellArg (toString val)}"
      ) env
    );

  # Generate PATH from package list
  mkPathExport =
    packages:
    let
      paths = map (pkg: "${pkg}/bin:${pkg}/sbin") packages;
    in
    if paths != [ ] then "export PATH=${concatStringsSep ":" paths}:$PATH" else "";

  # Generate variable declarations (variant-aware)
  mkVariableDeclarations =
    variant: name: config:
    let
      cfg = config.rcd or { };
      cmd = toString config.command;
      args = concatStringsSep " " (map escapeShellArg config.args);
      pidfileVal = if cfg.pidfile or null != null then cfg.pidfile else "/var/run/${name}.pid";
      procName = cfg.processName or null;
    in
    if variant == "openbsd" then ''
      daemon=${escapeShellArg cmd}
      ${optionalString (args != "") "daemon_flags=${escapeShellArg args}"}
      ${optionalString (config.user != "root") "daemon_user=${escapeShellArg config.user}"}
      ${optionalString (procName != null) "pexp=${escapeShellArg procName}"}
    '' else ''
      name="${name}"
      rcvar="${name}_enable"
      command=${escapeShellArg cmd}
      ${optionalString (args != "") "command_args=${escapeShellArg args}"}
      pidfile="${pidfileVal}"
      ${optionalString (procName != null) "procname=${escapeShellArg procName}"}
    '';

  # Generate preStart hook (variant-aware)
  mkPreStartHook =
    variant: name: config:
    let
      cfg = config.rcd or { };
      hasPreStart = config.preStart != "";
      hasWorkDir = config.workingDirectory != null;
      hasEnv = config.environment != { };
      hasPath = config.path != [ ];

      needsHook = hasPreStart || hasWorkDir || hasEnv || hasPath;

      precmdContent = ''
        ${optionalString hasWorkDir "cd ${escapeShellArg (toString config.workingDirectory)}"}
        ${optionalString hasEnv (mkEnvironmentExports config.environment)}
        ${optionalString hasPath (mkPathExport config.path)}
        ${optionalString hasPreStart config.preStart}
      '';
    in
    if !needsHook then "" else
    if variant == "openbsd" then ''
      rc_start() {
          ${precmdContent}
          ''${rcexec} "''${daemon} ''${daemon_flags}"
      }
    '' else ''
      start_precmd="${name}_precmd"
      ${name}_precmd() {
          ${precmdContent}
      }
    '';

  # Generate postStop hook (variant-aware)
  mkPostStopHook =
    variant: name: config:
    let
      hasPostStop = config.postStop != "";
    in
    if !hasPostStop then "" else
    if variant == "openbsd" then ''
      rc_stop() {
          ''${rcexec} "''${daemon_stop:-kill -TERM $(cat $pidfile)}"
          ${config.postStop}
      }
    '' else ''
      stop_postcmd="${name}_postcmd"
      ${name}_postcmd() {
          ${config.postStop}
      }
    '';

  # Generate user switching for non-OpenBSD systems
  # OpenBSD has daemon_user built-in
  mkUserSetup =
    variant: config:
    let
      needsUserSwitch = config.user != "root" && variant != "openbsd";
    in
    if !needsUserSwitch then "" else ''
      # User switching via command wrapper
      # Consider setting ${config.name}_user="${config.user}" in rc.conf
      # and using daemon(8) or defining custom start_cmd with su(1)
    '';

  # Generate additional rc.d variables from extraConfig
  mkExtraVariables =
    config:
    let
      cfg = config.rcd or { };
      extra = cfg.extraConfig or { };

      mkVar = name: value: "${name}=${escapeShellArg (toString value)}";

      vars = mapAttrsToList mkVar extra;
    in
    optionalString (vars != [ ]) (concatStringsSep "\n" vars);

  # Generate the complete rc.d script
  mkRcdScript =
    variant: name: config:
    let
      cfg = config.rcd or { };
      isOpenBSD = variant == "openbsd";

      shebang = if isOpenBSD then "#!/bin/ksh" else "#!/bin/sh";
      rcSubr = if isOpenBSD then ". /etc/rc.d/rc.subr" else ". /etc/rc.subr";
      runCommand = if isOpenBSD then "rc_cmd $1" else ''run_rc_command "$1"'';
      loadConfig = if isOpenBSD then "" else "load_rc_config $name";
    in
    pkgs.writeScript "${name}-rcd" ''
      ${shebang}
      ${optionalString (!isOpenBSD) (mkRcOrderMetadata config)}

      ${rcSubr}

      ${mkVariableDeclarations variant name config}
      ${mkExtraVariables config}
      ${mkUserSetup variant config}
      ${mkPreStartHook variant name config}
      ${mkPostStopHook variant name config}
      ${optionalString (cfg.extraRcScript != "") cfg.extraRcScript}

      ${loadConfig}
      ${runCommand}
    '';

  # Generate sample rc.conf entries
  mkRcConfSample =
    name: config:
    let
      cfg = config.rcd or { };
      variant = cfg.variant or "freebsd";
      isOpenBSD = variant == "openbsd";

      enableVar = if isOpenBSD then "pkg_scripts" else "${name}_enable";
      enableVal = if isOpenBSD then ''"''${pkg_scripts} ${name}"'' else ''"YES"'';

      envVars = if config.environment != { } then
        optionalString (!isOpenBSD) ''
          # Environment variables
          ${name}_env="${concatStringsSep " " (mapAttrsToList (k: v: "${k}=${toString v}") config.environment)}"
        ''
      else "";

      userVar = if config.user != "root" && !isOpenBSD then ''
        # Run as user (requires wrapper or custom start_cmd)
        ${name}_user="${config.user}"
      '' else "";
    in
    ''
      # Enable ${name}
      ${enableVar}=${enableVal}
      ${envVars}${userVar}${optionalString (cfg.extraRcConf != "") cfg.extraRcConf}
    '';

  # Build the complete service directory/files
  mkRcdService =
    variant: name: config:
    let
      rcdScript = mkRcdScript variant name config;
      rcConfSample = mkRcConfSample name config;
    in
    pkgs.runCommand "${name}-rcd-service" { } ''
      mkdir -p $out/etc/rc.d
      mkdir -p $out/etc/rc.conf.d

      # Install rc.d script
      cp ${rcdScript} $out/etc/rc.d/${name}
      chmod +x $out/etc/rc.d/${name}

      # Create sample rc.conf entries
      cat > $out/etc/rc.conf.d/${name}.sample <<'EOF'
      ${rcConfSample}
      EOF
    '';

in
{
  # Main translation function
  toRcdService = variant: name: config:
    mkRcdService variant name config;
}
