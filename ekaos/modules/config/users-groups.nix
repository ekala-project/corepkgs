# Adios port of ekaos/modules/config/users-groups.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, pkgs, ... }:

let
  filterAttrs =
    pred: set:
    builtins.listToAttrs (
      builtins.map (n: {
        name = n;
        value = set.${n};
      }) (builtins.filter (n: pred n set.${n}) (builtins.attrNames set))
    );

  optionalString = cond: s: if cond then s else "";

  concatMapStringsSep =
    sep: f: xs:
    builtins.concatStringsSep sep (builtins.map f xs);

  findFirst =
    pred: default: xs:
    let
      found = builtins.filter pred xs;
    in
    if found == [ ] then default else builtins.elemAt found 0;

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
    {
      name = "users";
      gid = 100;
    }
    {
      name = "nogroup";
      gid = 65534;
    }
  ];
in

{
  options = {
    users = {
      # TODO(adios-cutover): submodule validation lost. Legacy validated each
      # user (name/uid/group/extraGroups/homeDirectory/createHome/shell with
      # package-to-path apply, description, isSystemUser/isNormalUser with
      # mkDefault cross-defaults, hashedPassword/initialPassword,
      # openssh.authorizedKeys.keys). The shell and defaultUserShell apply
      # functions (package -> "/bin/<prog>") were dropped; pass strings.
      type = types.attrsOf types.attrs;
      default = { };
      example = {
        alice = {
          isNormalUser = true;
          homeDirectory = "/home/alice";
          description = "Alice User";
          extraGroups = [ "wheel" ];
          hashedPassword = "$6$rounds=656000$...";
        };
      };
      description = ''
        User account configuration.

        This option defines the user accounts on the system.
      '';
    };

    groups = {
      # TODO(adios-cutover): submodule validation lost. Legacy validated each
      # group (name/gid/members, name defaulting to the attribute name).
      type = types.attrsOf types.attrs;
      default = { };
      example = {
        developers = {
          gid = 1001;
          members = [
            "alice"
            "bob"
          ];
        };
      };
      description = ''
        Group configuration.

        This option defines the groups on the system.
      '';
    };

    mutableUsers = {
      type = types.bool;
      default = true;
      description = ''
        If true, users and groups can be modified with useradd, groupadd, etc.
        If false, the passwd and group files are read-only.
      '';
    };

    defaultUserShell = {
      # TODO(adios-cutover): option apply function dropped (package values
      # were resolved to "$pkg/bin/<mainProgram or pname or name>"); pass a
      # string path instead.
      type = types.either types.string types.derivation;
      default = "/run/current-system/sw/bin/bash";
      description = "The default shell for user accounts.";
    };
  };

  impl =
    { options, ... }:
    let
      users = builtins.attrValues options.users;
      groups = builtins.attrValues options.groups;

      # Merge system and user-defined users/groups
      allUsers = systemUsers ++ users;
      allGroups = systemGroups ++ groups;

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
          members = builtins.concatStringsSep "," (
            group.members or [ ]
            ++ (builtins.filter (m: m != "") (
              builtins.map (
                user: if builtins.elem group.name user.extraGroups or [ ] then user.name else ""
              ) allUsers
            ))
          );
        in
        "${group.name}:x:${gid}:${members}"
      ) allGroups;

      # Generate shadow file
      shadowContent = concatMapStringsSep "\n" (
        user:
        let
          hashedPass =
            if user.hashedPassword or null != null then
              user.hashedPassword
            else if user.initialPassword or null != null then
              # TODO(adios-cutover): legacy stored initialPassword verbatim
              # here (INSECURE); hash it before use in production.
              user.initialPassword
            else
              "!"; # Locked account
        in
        "${user.name}:${hashedPass}:1::::: "
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
          ${builtins.concatStringsSep "\n" keys}
          EOF
          chmod 0600 "${user.homeDirectory}/.ssh/authorized_keys"
          chown -R ${uid}:${gid} "${user.homeDirectory}/.ssh"
        ''
      ) allUsers;
    in
    {
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
      system.activationScripts.users = {
        deps = [ "etc" ];
        text = ''
          echo "Setting up user accounts..."

          # Create home directories
          ${createHomeDirs}

          # Set up SSH authorized keys
          ${setupSSHKeys}

          # Ensure /var/empty exists for system users
          mkdir -p /var/empty
          chmod 0555 /var/empty

          # Ensure /root exists
          mkdir -p /root
          chmod 0700 /root
        '';
      };

      # Add shadow package for user/group management tools
      environment.systemPackages = [ pkgs.shadow ];

      # Register default login shells
      environment.shells = [
        "/run/current-system/sw/bin/bash"
        "/run/current-system/sw/bin/nologin"
      ];
    };
}
