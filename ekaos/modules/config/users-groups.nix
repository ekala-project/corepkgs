# User and group management
# Provides declarative user and group configuration
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.users;

  # User type definition
  userOpts =
    {
      name,
      config,
      ...
    }:
    {
      options = {
        name = mkOption {
          type = types.str;
          description = "The name of the user account. If undefined, the name of the attribute set will be used.";
        };

        uid = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "The user ID for the user. If null, an ID will be assigned automatically.";
        };

        group = mkOption {
          type = types.str;
          default = "nogroup";
          description = "The user's primary group.";
        };

        extraGroups = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "The user's auxiliary groups.";
        };

        homeDirectory = mkOption {
          type = types.str;
          default = if config.isSystemUser then "/var/empty" else "/home/${config.name}";
          description = "The user's home directory.";
        };

        createHome = mkOption {
          type = types.bool;
          default = !config.isSystemUser;
          description = "Whether to create the home directory if it doesn't exist.";
        };

        shell = mkOption {
          type = types.either types.str types.package;
          default =
            if config.isSystemUser then
              "/run/current-system/sw/bin/nologin"
            else
              "/run/current-system/sw/bin/bash";
          defaultText = literalExpression ''
            if isSystemUser then "/run/current-system/sw/bin/nologin"
            else "/run/current-system/sw/bin/bash"
          '';
          example = literalExpression "pkgs.zsh";
          description = ''
            The user's login shell.

            Can be a string path or a package. Packages are resolved
            to "$${pkg}/bin/$${pkg.meta.mainProgram or pkg.pname or name}".
          '';
          apply =
            v:
            if builtins.isString v then
              v
            else
              let
                name = v.meta.mainProgram or v.pname or (builtins.parseDrvName v.name).name;
              in
              "${v}/bin/${name}";
        };

        description = mkOption {
          type = types.str;
          default = "";
          description = "A short description of the user (GECOS field).";
        };

        isSystemUser = mkOption {
          type = types.bool;
          default = false;
          description = "Whether the user is a system user.";
        };

        isNormalUser = mkOption {
          type = types.bool;
          default = false;
          description = "Whether the user is a normal user (not a system user).";
        };

        hashedPassword = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "The user's hashed password. Use mkpasswd to generate.";
        };

        initialPassword = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            The user's initial password (plaintext). Only used if hashedPassword is null.
            WARNING: This is stored in the Nix store, which is world-readable.
          '';
        };

        openssh.authorizedKeys.keys = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "SSH public keys for the user.";
        };
      };

      config = {
        name = mkDefault name;
        isNormalUser = mkDefault (!config.isSystemUser);
        # Normal users should default to "users" group, not "nogroup"
        group = mkIf config.isNormalUser (mkDefault "users");
      };
    };

  # Group type definition
  groupOpts =
    {
      name,
      config,
      ...
    }:
    {
      options = {
        name = mkOption {
          type = types.str;
          description = "The name of the group. If undefined, the name of the attribute set will be used.";
        };

        gid = mkOption {
          type = types.nullOr types.int;
          default = null;
          description = "The group ID. If null, an ID will be assigned automatically.";
        };

        members = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "The group members.";
        };
      };

      config = {
        name = mkDefault name;
      };
    };

  # Get all users as a list
  users = attrValues cfg.users;
  groups = attrValues cfg.groups;

  # System users (predefined)
  systemUsers = [
    {
      name = "root";
      uid = 0;
      group = "root";
      homeDirectory = "/root";
      shell = "/run/current-system/sw/bin/bash";
      description = "System administrator";
    }
    {
      name = "nobody";
      uid = 65534;
      group = "nogroup";
      homeDirectory = "/var/empty";
      shell = "/run/current-system/sw/bin/nologin";
      description = "Unprivileged account";
      isSystemUser = true;
    }
  ];

  # System groups (predefined)
  systemGroups = [
    {
      name = "root";
      gid = 0;
    }
    {
      name = "wheel";
      gid = 1;
      members = [ ];
    }
    {
      name = "kmem";
      gid = 2;
    }
    {
      name = "tty";
      gid = 3;
    }
    {
      name = "messagebus";
      gid = 4;
    }
    {
      name = "systemd-journal";
      gid = 5;
    }
    {
      name = "disk";
      gid = 6;
    }
    {
      name = "audio";
      gid = 7;
    }
    {
      name = "video";
      gid = 8;
    }
    {
      name = "lp";
      gid = 9;
    }
    {
      name = "uucp";
      gid = 10;
    }
    {
      name = "cdrom";
      gid = 11;
    }
    {
      name = "tape";
      gid = 12;
    }
    {
      name = "dialout";
      gid = 13;
    }
    # Groups systemd's tmpfiles.d snippets and udev rules refer to
    {
      name = "utmp";
      gid = 29;
    }
    {
      name = "input";
      gid = 174;
    }
    {
      name = "kvm";
      gid = 302;
    }
    {
      name = "render";
      gid = 303;
    }
    {
      name = "sgx";
      gid = 304;
    }
    {
      name = "users";
      gid = 100;
    }
    {
      name = "nogroup";
      gid = 65534;
    }
  ];

  # Merge system and user-defined users/groups
  # The built-in users and groups are defined through the options below,
  # so a module's users.users.root or users.groups.wheel merges with them
  allUsers = users;
  allGroups = groups;

  # Built-in values yield to any definition. The user submodule already
  # sets group with mkDefault, so that one needs a higher priority.
  asDefaults =
    entry:
    mapAttrs (k: v: if k == "group" then mkOverride 900 v else mkDefault v) (
      removeAttrs entry [ "name" ]
    );
  builtinsOf = entries: listToAttrs (map (e: nameValuePair e.name (asDefaults e)) entries);

  # Generate passwd file
  passwdContent = concatMapStringsSep "\n" (
    user:
    let
      uid = if user.uid != null then toString user.uid else "1000";
      gid = toString (findFirst (g: g.name == user.group) { gid = 100; } allGroups).gid;
      home = user.homeDirectory or "/var/empty";
      shell = user.shell or "/run/current-system/sw/bin/bash";
      description = user.description or "";
    in
    "${user.name}:x:${uid}:${gid}:${description}:${home}:${shell}"
  ) allUsers;

  # Generate group file
  groupContent = concatMapStringsSep "\n" (
    group:
    let
      gid = if group.gid != null then toString group.gid else "1000";
      members = concatStringsSep "," (
        group.members or [ ]
        ++ (filter (m: m != "") (
          map (user: if elem group.name user.extraGroups or [ ] then user.name else "") allUsers
        ))
      );
    in
    "${group.name}:x:${gid}:${members}"
  ) allGroups;

  # Generate shadow file
  shadowContent = concatMapStringsSep "\n" (
    user:
    let
      # Hash password if initialPassword is set
      hashedPass =
        if user.hashedPassword or null != null then
          user.hashedPassword
        # initialPassword is hashed at activation (setInitialPasswords);
        # until then the account stays locked
        else
          "!"; # Locked account
    in
    "${user.name}:${hashedPass}:1::::: "
  ) allUsers;

  # Hash each initialPassword into /etc/shadow. A plaintext value in the
  # hash field never matches, and would sit in a root-readable file.
  setInitialPasswords = concatMapStringsSep "\n" (
    user:
    optionalString (user.hashedPassword or null == null && user.initialPassword or null != null) ''
      hash=$(printf '%s' ${escapeShellArg user.initialPassword} | ${pkgs.openssl}/bin/openssl passwd -6 -stdin)
      (umask 077; ${pkgs.gawk}/bin/awk -F: -v OFS=: -v user=${escapeShellArg user.name} -v hash="$hash" \
        '$1 == user { $2 = hash } { print }' /etc/shadow > /etc/shadow.new)
      chmod --reference=/etc/shadow /etc/shadow.new
      mv /etc/shadow.new /etc/shadow
    ''
  ) allUsers;

  # Generate home directory creation script
  createHomeDirs = concatMapStringsSep "\n" (
    user:
    let
      uid = if user.uid != null then toString user.uid else "1000";
      gid = toString (findFirst (g: g.name == user.group) { gid = 100; } allGroups).gid;
    in
    optionalString (user.createHome or false) ''
      if [ ! -d "${user.homeDirectory}" ]; then
        mkdir -p "${user.homeDirectory}"
        chown ${uid}:${gid} "${user.homeDirectory}"
        chmod 0700 "${user.homeDirectory}"
      fi
    ''
  ) allUsers;

  # Generate SSH authorized_keys setup
  setupSSHKeys = concatMapStringsSep "\n" (
    user:
    let
      keys = user.openssh.authorizedKeys.keys or [ ];
      uid = if user.uid != null then toString user.uid else "1000";
      gid = toString (findFirst (g: g.name == user.group) { gid = 100; } allGroups).gid;
    in
    optionalString (keys != [ ]) ''
      if [ ! -d "${user.homeDirectory}/.ssh" ]; then
        mkdir -p "${user.homeDirectory}/.ssh"
        chmod 0700 "${user.homeDirectory}/.ssh"
      fi
      cat > "${user.homeDirectory}/.ssh/authorized_keys" <<'EOF'
      ${concatStringsSep "\n" keys}
      EOF
      chmod 0600 "${user.homeDirectory}/.ssh/authorized_keys"
      chown -R ${uid}:${gid} "${user.homeDirectory}/.ssh"
    ''
  ) allUsers;

in

{
  options = {
    users.users = mkOption {
      type = types.attrsOf (types.submodule userOpts);
      default = { };
      description = ''
        User account configuration.

        This option defines the user accounts on the system.
      '';
      example = literalExpression ''
        {
          alice = {
            isNormalUser = true;
            homeDirectory = "/home/alice";
            description = "Alice User";
            extraGroups = [ "wheel" ];
            hashedPassword = "$6$rounds=656000$...";
          };
        }
      '';
    };

    users.groups = mkOption {
      type = types.attrsOf (types.submodule groupOpts);
      default = { };
      description = ''
        Group configuration.

        This option defines the groups on the system.
      '';
      example = literalExpression ''
        {
          developers = {
            gid = 1001;
            members = [ "alice" "bob" ];
          };
        }
      '';
    };

    users.mutableUsers = mkOption {
      type = types.bool;
      default = true;
      description = ''
        If true, users and groups can be modified with useradd, groupadd, etc.
        If false, the passwd and group files are read-only.
      '';
    };

    users.defaultUserShell = mkOption {
      type = types.either types.str types.package;
      default = "/run/current-system/sw/bin/bash";
      example = literalExpression "pkgs.zsh";
      description = "The default shell for user accounts.";
      apply =
        v:
        if builtins.isString v then
          v
        else
          let
            name = v.meta.mainProgram or v.pname or (builtins.parseDrvName v.name).name;
          in
          "${v}/bin/${name}";
    };
  };

  config = {
    users.users = builtinsOf systemUsers;
    users.groups = builtinsOf systemGroups;

    # Generate /etc/passwd, /etc/group, /etc/shadow
    environment.etc = {
      "passwd" = {
        text = passwdContent;
        mode = "0644";
      };

      "group" = {
        text = groupContent;
        mode = "0644";
      };

      "shadow" = {
        text = shadowContent;
        mode = "0600";
      };

      # Create /etc/login.defs for shadow suite
      "login.defs".text = ''
        # Login configuration
        MAIL_DIR /var/mail
        UMASK 022
        PASS_MAX_DAYS 99999
        PASS_MIN_DAYS 0
        PASS_MIN_LEN 5
        PASS_WARN_AGE 7
        UID_MIN 1000
        UID_MAX 60000
        GID_MIN 1000
        GID_MAX 60000
        SYS_UID_MIN 100
        SYS_UID_MAX 999
        SYS_GID_MIN 100
        SYS_GID_MAX 999
        CREATE_HOME yes
        USERGROUPS_ENAB yes
        ENCRYPT_METHOD SHA512
      '';
    };

    # Activation script to create home directories and set up SSH keys
    system.activationScripts.users = stringAfter [ "etc" ] ''
      echo "Setting up user accounts..."

      # Create home directories
      ${createHomeDirs}

      # Set up SSH authorized keys
      ${setupSSHKeys}

      # Hash the initial passwords into /etc/shadow
      ${setInitialPasswords}

      # Ensure /var/empty exists for system users
      mkdir -p /var/empty
      chmod 0555 /var/empty

      # Ensure /root exists
      mkdir -p /root
      chmod 0700 /root
    '';

    # Add shadow package for user/group management tools
    # su is in its own output; it needs to be setuid for non-root users
    environment.systemPackages = [
      pkgs.shadow
      pkgs.shadow.su
    ];
    security.wrappers.su = {
      source = "${pkgs.shadow.su}/bin/su";
      owner = "root";
      group = "root";
      setuid = true;
      permissions = "u+rx,g+x,o+x";
    };

    # Register default login shells
    environment.shells = [
      "/run/current-system/sw/bin/bash"
      "/run/current-system/sw/bin/nologin"
    ];
  };
}
