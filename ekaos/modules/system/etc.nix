# /etc file management
# Builds the /etc directory for the system
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  etc' = filter (f: f.enable) (attrValues config.environment.etc);

  # Build the /etc directory
  etcDir =
    pkgs.runCommand "etc"
      {
        preferLocalBuild = true;
      }
      ''
        mkdir -p $out/etc

        ${concatMapStringsSep "\n" (
          file:
          let
            # If text is provided but source is not, create a source file
            source =
              if file.source != null then
                file.source
              else if file.text != null then
                pkgs.writeText file.target file.text
              else
                null;
          in
          ''
            mkdir -p $out/etc/$(dirname ${escapeShellArg file.target})
            ${
              if source != null then
                ''
                  ln -s ${source} $out/etc/${escapeShellArg file.target}
                ''
              else
                throw "etc file ${file.target} has neither source nor text"
            }
          ''
        ) etc'}
      '';

in

{
  options = {
    environment.etc = mkOption {
      type = types.attrsOf (
        types.submodule (
          { name, config, ... }:
          {
            options = {
              enable = mkOption {
                type = types.bool;
                default = true;
                description = "Whether this /etc file should be generated.";
              };

              target = mkOption {
                type = types.str;
                default = name;
                description = "Name of the file in /etc (relative path).";
              };

              text = mkOption {
                type = types.nullOr types.lines;
                default = null;
                description = "Text content of the file.";
              };

              source = mkOption {
                type = types.nullOr types.path;
                default = null;
                description = "Source file to symlink.";
              };

              mode = mkOption {
                type = types.nullOr types.str;
                default = null;
                example = "0600";
                description = "File mode (permissions).";
              };
            };

            config = {
              # No auto-conversion needed - handled in etcDir build
            };
          }
        )
      );
      default = { };
      description = ''
        Files to include in /etc.

        Each attribute defines a file in /etc with its content or source.
      '';
      example = literalExpression ''
        {
          "hostname".text = "myhost";
          "hosts".text = '''
            127.0.0.1 localhost
            ::1 localhost
          ''';
        }
      '';
    };

    system.build.etc = mkOption {
      type = types.package;
      internal = true;
      description = "The /etc directory for the system.";
    };
  };

  config = {
    system.build.etc = etcDir;

    # Essential /etc files for a bootable system
    environment.etc = {
      "fstab".text = ''
        # Static file system configuration
        # Managed by ekaos

        # Special filesystems
        proc /proc proc defaults 0 0
        sysfs /sys sysfs defaults 0 0
        devtmpfs /dev devtmpfs mode=0755,nosuid 0 0
        devpts /dev/pts devpts mode=0620,gid=3,nosuid,noexec 0 0
        tmpfs /run tmpfs mode=0755,nosuid,nodev,size=25% 0 0
        tmpfs /dev/shm tmpfs mode=1777,nosuid,nodev 0 0
      '';

      "os-release".text = ''
        NAME="ekaos"
        ID=ekaos
        VERSION="${config.system.ekaos.version}"
        VERSION_ID="${config.system.ekaos.version}"
        PRETTY_NAME="ekaos ${config.system.ekaos.version}"
        HOME_URL="https://github.com/your-org/ekaos"
      '';

      "issue".text = ''
        ekaos ${config.system.ekaos.version} \n \l

      '';

      # Shell configuration
      "bashrc".text = ''
        # /etc/bashrc: system-wide bash configuration
        # shellcheck shell=bash

        # If not running interactively, don't do anything
        [[ $- != *i* ]] && return

        # Set up secure PATH
        export PATH="/run/current-system/sw/bin:/usr/bin:/bin"

        # Basic shell options
        shopt -s checkwinsize
        shopt -s histappend

        # Command prompt
        if [ "$EUID" -eq 0 ]; then
          PS1='\[\033[01;31m\]\h\[\033[01;34m\] \w \$\[\033[00m\] '
        else
          PS1='\[\033[01;32m\]\u@\h\[\033[01;34m\] \w \$\[\033[00m\] '
        fi

        # Aliases
        alias ls='ls --color=auto'
        alias ll='ls -lh'
        alias la='ls -lah'
        alias grep='grep --color=auto'

        # Source user's bashrc if it exists
        [ -f ~/.bashrc ] && source ~/.bashrc
      '';

      "profile".text = ''
        # /etc/profile: system-wide environment and startup programs

        # Set up PATH
        export PATH="/run/current-system/sw/bin:/run/wrappers/bin:/usr/bin:/bin"

        # Set up default environment variables
        export LANG="C.UTF-8"
        export PAGER="less"
        export EDITOR="vi"

        # XDG base directories
        export XDG_DATA_DIRS="/run/current-system/sw/share''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
        export XDG_CONFIG_DIRS="/etc/xdg''${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}"

        # Source bash-specific profile
        if [ -n "$BASH_VERSION" ]; then
          [ -f /etc/bashrc ] && source /etc/bashrc
        fi

        # Source user's profile if it exists
        [ -f ~/.profile ] && source ~/.profile
      '';

      "nsswitch.conf".text = ''
        # /etc/nsswitch.conf: Name Service Switch configuration

        passwd:    files
        group:     files
        shadow:    files

        hosts:     files dns
        networks:  files

        services:  files
        protocols: files
        rpc:       files
        ethers:    files
        netmasks:  files
        netgroup:  files
        bootparams: files

        automount: files
        aliases:   files
      '';

      # Hostname configuration
      "hostname".text = mkDefault "${config.networking.hostName or "ekaos"}";

      # Hosts file
      "hosts".text = ''
        127.0.0.1 localhost
        ::1 localhost
        127.0.1.1 ${config.networking.hostName or "ekaos"}
      '';
    };
  };
}
