# Build Docker images with runit supervision
{ lib, pkgs }:

let
  inherit (lib)
    concatStringsSep
    concatMapStringsSep
    mapAttrsToList
    filterAttrs
    optionalString
    ;

  runitTranslate = import ./runit-translate.nix { inherit lib pkgs; };
  validate = import ./validate.nix { inherit lib pkgs; };

  # Build all service directories from service definitions
  buildServiceDirectories =
    services:
    let
      enabledServices = filterAttrs (_: cfg: cfg.enable) services;
      validatedServices = validate.validateServices "runit" enabledServices;
    in
    mapAttrsToList (
      name: config:
      let
        serviceDir = runitTranslate.toRunitService name config;
      in
      {
        inherit name;
        path = serviceDir;
      }
    ) validatedServices;

  # Create a derivation with all service directories in /etc/sv
  mkServiceRoot =
    serviceDirs:
    pkgs.runCommand "runit-services-root" { } ''
      mkdir -p $out/etc/sv
      ${concatMapStringsSep "\n" (
        svc: ''
          cp -r ${svc.path} $out/etc/sv/${svc.name}
          chmod -R u+w $out/etc/sv/${svc.name}
        ''
      ) serviceDirs}
    '';

  # Generate the entrypoint script that sets up and runs runit
  mkEntrypoint =
    {
      serviceDirs,
      preStartCommands ? "",
      runitPackage ? pkgs.runit,
    }:
    pkgs.writeScript "runit-entrypoint" ''
      #!/bin/sh
      set -e

      echo "Initializing runit supervision..."

      # Create service directory for runsvdir
      mkdir -p /service

      # Create log directories for services
      ${concatMapStringsSep "\n" (svc: ''
        mkdir -p /var/log/${svc.name}
      '') serviceDirs}

      # Link service directories
      ${concatMapStringsSep "\n" (svc: ''
        ln -sf /etc/sv/${svc.name} /service/${svc.name}
      '') serviceDirs}

      # Run any pre-start commands
      ${preStartCommands}

      echo "Starting runit supervision of ${toString (builtins.length serviceDirs)} service(s)..."

      # Execute runsvdir as PID 1 (with -P flag to propagate signals properly)
      exec ${runitPackage}/bin/runsvdir -P /service
    '';

  # Extract users and groups from service definitions
  extractUsers =
    services:
    let
      enabledServices = filterAttrs (_: cfg: cfg.enable) services;
      userSpecs = mapAttrsToList (
        name: config:
        let
          user = config.user or "root";
          group = config.group or user;
        in
        if user != "root" then
          {
            inherit user group;
            uid = config.uid or null;
            gid = config.gid or null;
          }
        else
          null
      ) enabledServices;
    in
    builtins.filter (spec: spec != null) userSpecs;

  # Generate commands to create users and groups for fakeRootCommands
  mkUserCreationCommands =
    userSpecs:
    let
      uniqueUsers = lib.unique (map (spec: spec.user) userSpecs);
      uniqueGroups = lib.unique (map (spec: spec.group) userSpecs);

      # Find spec for a given user/group name
      findSpec = name: builtins.head (builtins.filter (spec: spec.user == name || spec.group == name) userSpecs);

      mkGroupLine =
        name:
        let
          spec = findSpec name;
          gid = if spec.gid != null then ":${toString spec.gid}:" else ":1000:";
        in
        "echo '${name}:x${gid}' >> etc/group";

      mkUserLine =
        name:
        let
          spec = findSpec name;
          uid = if spec.uid != null then toString spec.uid else "1000";
          gid = if spec.gid != null then toString spec.gid else "1000";
        in
        "echo '${name}:x:${uid}:${gid}:${name}:/home/${name}:/bin/sh' >> etc/passwd";

    in
    ''
      # Create minimal passwd and group files
      mkdir -p etc
      ${concatMapStringsSep "\n" mkGroupLine uniqueGroups}
      ${concatMapStringsSep "\n" mkUserLine uniqueUsers}
    '';

in
{
  # Main function: Build a Docker image with runit supervision
  # Arguments:
  #   services: Attribute set of service definitions (same format as mkRunitServices)
  #   name: Docker image name
  #   tag: Docker image tag (default: "latest")
  #   extraContents: Additional packages to include in the image
  #   exposedPorts: List of ports to expose (e.g., ["8080/tcp" "9090/tcp"])
  #   imageConfig: Additional Docker config options to merge
  #   preStartCommands: Shell commands to run before starting runsvdir
  #   runitPackage: Runit package to use (default: pkgs.runit)
  #   architecture: Target architecture (default: current system)
  mkRunitDockerImage =
    {
      services,
      name,
      tag ? "latest",
      extraContents ? [ ],
      exposedPorts ? [ ],
      imageConfig ? { },
      preStartCommands ? "",
      runitPackage ? pkgs.runit,
      architecture ? pkgs.stdenv.hostPlatform.system,
    }:
    let
      # Build service directories
      serviceDirs = buildServiceDirectories services;

      # Create service root with all /etc/sv/* directories
      serviceRoot = mkServiceRoot serviceDirs;

      # Create entrypoint script
      entrypoint = mkEntrypoint {
        inherit serviceDirs preStartCommands runitPackage;
      };

      # Extract user specifications
      userSpecs = extractUsers services;

      # Convert exposed ports to Docker format
      exposedPortsConfig = builtins.listToAttrs (
        map (port: {
          name = port;
          value = { };
        }) exposedPorts
      );

      # Determine if we're using nixpkgs dockerTools or need to import
      dockerTools = pkgs.dockerTools or (import <nixpkgs> { }).dockerTools;

    in
    dockerTools.buildLayeredImage {
      inherit name tag;

      # Include all necessary packages
      contents = [
        runitPackage
        pkgs.busybox # Provides /bin/sh and basic utilities
        serviceRoot
      ] ++ extraContents;

      # Set up users, groups, and directory structure
      fakeRootCommands =
        ''
          # Set up users and groups
          ${if userSpecs != [ ] then mkUserCreationCommands userSpecs else "# No custom users needed"}

          # Create standard directories
          mkdir -p service var/log tmp

          # Set permissions on log directory
          chmod 1777 tmp

          # Set ownership for user-specific log directories
          ${concatMapStringsSep "\n" (spec: ''
            if [ -d var/log/${spec.user} ]; then
              chown -R ${
                if spec.uid != null then toString spec.uid else "1000"
              }:${
                if spec.gid != null then toString spec.gid else "1000"
              } var/log/${spec.user}
            fi
          '') userSpecs}
        ''
        + optionalString ((imageConfig.extraFakeRootCommands or "") != "") ''
          # Extra fakeroot commands from imageConfig
          ${imageConfig.extraFakeRootCommands}
        '';

      # Docker image configuration
      config = lib.recursiveUpdate {
        Entrypoint = [ "${entrypoint}" ];

        # Working directory
        WorkingDir = "/";

        # Exposed ports
        ExposedPorts = exposedPortsConfig;

        # Environment variables
        Env = [
          "PATH=/bin:/usr/bin:/sbin:/usr/sbin"
        ];

        # Labels
        Labels = {
          "org.opencontainers.image.description" = "Runit-supervised multi-service container";
          "org.opencontainers.image.vendor" = "core-pkgs";
        };
      } imageConfig;
    };
}
