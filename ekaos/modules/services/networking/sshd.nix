# Adios port of ekaos/modules/services/networking/sshd.nix.
# TODO(adios-cutover): command/args were internal options set by the legacy
# config; they are computed in impl, not user options.
# TODO(adios-cutover): ports used the shared portContract submodule type
# (imported from services/lib/types.nix); submodule validation lost.
# NOTE: the legacy `userCfg = config.users` binding is dead (never read) and
# is dropped.
{ types, pkgs, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable the OpenSSH secure shell daemon.

        This allows secure remote login and file transfer.
      '';
    };

    description = {
      type = types.string;
      default = "OpenSSH Daemon";
      description = "Service description";
    };

    user = {
      type = types.string;
      default = "root";
      description = "User to run service as";
    };

    restartPolicy = {
      type = types.string;
      default = "always";
      description = "Restart policy";
    };

    systemd = {
      type = types.attrsOf types.any;
      default = { };
      description = "Systemd-specific options";
    };

    ports = {
      type = types.attrsOf types.attrs;
      default = { };
      description = "Port contracts for this service.";
    };

    settings = {
      options = {
        ports = {
          type = types.union [
            types.int
            (types.listOf types.int)
          ];
          default = 22;
          description = ''
            Port(s) for sshd to listen on.

            Can be a single port number or a list of ports.
          '';
        };

        listenAddresses = {
          type = types.listOf types.string;
          default = [ ];
          description = ''
            List of addresses for sshd to listen on.

            If empty, listens on all interfaces.
          '';
        };

        permitRootLogin = {
          type = types.enum "permitRootLogin" [
            "yes"
            "no"
            "prohibit-password"
            "forced-commands-only"
          ];
          default = "prohibit-password";
          description = ''
            Whether root can login via SSH.

            - "yes": Root can login with password
            - "no": Root cannot login at all
            - "prohibit-password": Root can only use key-based auth
            - "forced-commands-only": Root can only run forced commands
          '';
        };

        passwordAuthentication = {
          type = types.bool;
          default = true;
          description = ''
            Whether to allow password-based authentication.

            Set to false to require key-based authentication only.
          '';
        };

        x11Forwarding = {
          type = types.bool;
          default = false;
          description = ''
            Whether to allow X11 forwarding.
          '';
        };

        logLevel = {
          type = types.enum "logLevel" [
            "QUIET"
            "FATAL"
            "ERROR"
            "INFO"
            "VERBOSE"
            "DEBUG"
            "DEBUG1"
            "DEBUG2"
            "DEBUG3"
          ];
          default = "INFO";
          description = ''
            Logging verbosity level.
          '';
        };

        hostKeys = {
          type = types.listOf types.pathLike;
          default = [
            "/etc/ssh/ssh_host_rsa_key"
            "/etc/ssh/ssh_host_ed25519_key"
          ];
          description = ''
            List of paths to host key files.

            These keys identify the server to clients.
          '';
        };

        authorizedKeysFiles = {
          type = types.listOf types.string;
          default = [ ];
          description = ''
            Files to check for authorized keys.

            If empty, the OpenSSH default is used.
            Supports tokens: %h (home dir), %u (username), %% (literal %).
          '';
        };

        extraConfig = {
          type = types.string;
          default = "";
          description = ''
            Extra configuration to append to sshd_config.

            See sshd_config(5) for available options.
          '';
        };
      };
      description = "OpenSSH-specific configuration";
    };
  };

  assertions = [
    {
      verify =
        { options }:
        let
          ports =
            if builtins.isList (options.settings.ports or 22) then
              (options.settings.ports or [ 22 ])
            else
              [ (options.settings.ports or 22) ];
        in
        builtins.all (p: p >= 0 && p <= 65535) ports;
      explain =
        { options }: "sshd ports must each be 0-65535, got ${toString (options.settings.ports or 22)}";
    }
  ];

  impl =
    { options, ... }:
    if !options.enable then
      { }
    else
      let
        s = options.settings;
        portsList = if builtins.isList (s.ports or 22) then (s.ports or [ 22 ]) else [ (s.ports or 22) ];

        # Local replacement for lib.hasSuffix.
        hasSuffix =
          suffix: str:
          let
            sl = builtins.stringLength suffix;
            l = builtins.stringLength str;
          in
          l >= sl && builtins.substring (l - sl) sl str == suffix;

        sshdConfig = pkgs.writeText "sshd_config" ''
          # Generated by ekaos openssh module

          # Listening
          ${builtins.concatStringsSep "\n" (builtins.map (p: "Port ${toString p}") portsList)}
          ${
            if (s.listenAddresses or [ ]) != [ ] then
              (builtins.concatStringsSep "\n" (builtins.map (addr: "ListenAddress ${addr}") s.listenAddresses))
            else
              ""
          }

          # Host keys
          ${builtins.concatStringsSep "\n" (builtins.map (key: "HostKey ${key}") (s.hostKeys or [ ]))}

          # Logging
          SyslogFacility AUTH
          LogLevel ${s.logLevel or "INFO"}

          # Authentication
          PermitRootLogin ${s.permitRootLogin or "prohibit-password"}
          PasswordAuthentication ${if (s.passwordAuthentication or true) then "yes" else "no"}
          PubkeyAuthentication yes
          ChallengeResponseAuthentication no
          UsePAM yes

          # Authorized keys
          ${
            if (s.authorizedKeysFiles or [ ]) != [ ] then
              "AuthorizedKeysFile ${builtins.concatStringsSep " " s.authorizedKeysFiles}"
            else
              ""
          }

          # Security
          X11Forwarding ${if (s.x11Forwarding or false) then "yes" else "no"}
          PrintMotd no
          AcceptEnv LANG LC_*
          Subsystem sftp ${pkgs.openssh}/libexec/sftp-server

          # Performance
          UseDNS no

          ${s.extraConfig or ""}
        '';
      in
      {
        services.openssh = {
          inherit (options) enable description restartPolicy;
          # sshd drops privileges itself after binding.
          user = "root";
          command = "${pkgs.openssh}/bin/sshd";
          args = [
            "-D"
            "-f"
            "${sshdConfig}"
          ];
          ports = options.ports // {
            ssh = {
              port = builtins.elemAt portsList 0;
              protocol = "tcp";
              transport = "tcp";
              internal = true;
              openFirewall = true;
            };
          };
          systemd = {
            after = [ "network.target" ];
            wantedBy = [ "multi-user.target" ];
          }
          // options.systemd;
        };

        environment.etc."ssh/sshd_config".source = sshdConfig;

        environment.systemPackages = [ pkgs.openssh ];

        environment.etc."pam.d/sshd".text = ''
          # PAM configuration for sshd
          auth      substack     password-auth
          auth      include      postlogin
          account   required     pam_nologin.so
          account   include      password-auth
          password  include      password-auth
          session   required     pam_loginuid.so
          session   optional     pam_keyinit.so force revoke
          session   optional     pam_motd.so
          session   include      password-auth
          session   include      postlogin
        '';

        environment.etc."pam.d/password-auth".text = ''
          auth      required    pam_env.so
          auth      sufficient  pam_unix.so try_first_pass nullok
          auth      required    pam_deny.so

          account   required    pam_unix.so

          password  required    pam_unix.so try_first_pass nullok sha512 shadow
          password  required    pam_deny.so

          session   required    pam_limits.so
          session   required    pam_unix.so
          session   optional    pam_umask.so
        '';

        environment.etc."pam.d/postlogin".text = ''
          session   optional    pam_motd.so
          session   optional    pam_lastlog.so silent
        '';

        # TODO(adios-cutover): legacy ordering (after "etc" "users") lost; plain script.
        system.activationScripts.sshd = ''
          # Create SSH directories
          mkdir -p /etc/ssh
          mkdir -p /var/empty
          chmod 755 /etc/ssh
          chmod 711 /var/empty

          # Generate host keys if they don't exist
          ${builtins.concatStringsSep "\n" (
            builtins.map (
              keyPath:
              let
                keyType =
                  if hasSuffix "_rsa_key" keyPath then
                    "rsa"
                  else if hasSuffix "_ed25519_key" keyPath then
                    "ed25519"
                  else if hasSuffix "_ecdsa_key" keyPath then
                    "ecdsa"
                  else
                    "rsa";
              in
              ''
                if [ ! -f "${keyPath}" ]; then
                  echo "Generating SSH ${keyType} host key..."
                  # Set USER and HOME to work around NSS issues during disk image builds
                  USER=root HOME=/root ${pkgs.openssh}/bin/ssh-keygen -t ${keyType} -f "${keyPath}" -N "" -q || true
                  # Verify the key was created even if ssh-keygen complained
                  if [ -f "${keyPath}" ]; then
                    chmod 600 "${keyPath}"
                    chmod 644 "${keyPath}.pub"
                  fi
                fi
              ''
            ) (s.hostKeys or [ ])
          )}
        '';
      };
}
