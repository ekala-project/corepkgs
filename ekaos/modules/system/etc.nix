# Adios port of ekaos/modules/system/etc.nix.
#
# Tree path: system/etc is parent.system.etc.
# Reads ekaos version via inputs.toplevel (parent.system.toplevel, option
# ekaos.version), hostname via inputs.networking (parent.networking,
# option hostName), and shell environment via inputs.shellEnv
# (parent.config."shell-environment": variables, shellAliases,
# interactiveInit, shell.init, shell.loginInit).
# TODO(adios-cutover): etc is types.attrsOf types.attrs; legacy per-file
# submodule validation lost (expected keys: enable bool default true,
# target default attr name, text/source null, mode null).
# TODO(adios-cutover): priority lost (was mkDefault): the hostname file
# no longer yields to user overrides; essentials win over options.etc on
# key collision (legacy merged per-file submodule fields instead).
# TODO(adios-cutover): impl returns environment.etc essentials and
# system.build.etc; the tree must merge impl outputs back (NixOS
# module-merge semantics). buildEtc is additionally exposed as an option
# (via defaultFunc) so siblings can read it through adios inputs.
{ types, pkgs, ... }:

let
  mapAttrsToList = f: attrs: builtins.map (n: f n attrs.${n}) (builtins.attrNames attrs);
  # Local escapeShellArg (no nixpkgs lib allowed).
  escapeShellArg = s: "'${builtins.replaceStrings [ "'" ] [ "'\\''" ] (toString s)}'";

  # Build the /etc directory from an enabled file list.
  buildEtcDir =
    files:
    pkgs.runCommand "etc"
      {
        preferLocalBuild = true;
      }
      ''
        mkdir -p $out/etc

        ${builtins.concatStringsSep "\n" (
          builtins.map (
            file:
            let
              source =
                if (file.source or null) != null then
                  file.source
                else if (file.text or null) != null then
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
          ) files
        )}
      '';

  # Essential /etc files for a bootable system.
  mkEssential =
    {
      ekaosVersion,
      hostName,
      shellAliases,
      interactiveInit,
      envVars,
      shellInit,
      loginInit,
    }:
    {
      # fstab is now managed by tasks/filesystems.nix

      "os-release".text = ''
        NAME="ekaos"
        ID=ekaos
        VERSION="${ekaosVersion}"
        VERSION_ID="${ekaosVersion}"
        PRETTY_NAME="ekaos ${ekaosVersion}"
        HOME_URL="https://github.com/your-org/ekaos"
      '';

      "issue".text = ''
        ekaos ${ekaosVersion} \n \l

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
        ${builtins.concatStringsSep "\n" (
          mapAttrsToList (name: value: "alias ${name}=${escapeShellArg value}") shellAliases
        )}

        # Interactive shell initialization
        ${interactiveInit}

        # Source user's bashrc if it exists
        [ -f ~/.bashrc ] && source ~/.bashrc
      '';

      "profile".text = ''
        # /etc/profile: system-wide environment and startup programs

        # Set up PATH
        export PATH="/run/current-system/sw/bin:/run/wrappers/bin:/usr/bin:/bin"

        # Locale (from i18n.defaultLocale)
        if [ -f /etc/locale.conf ]; then
          . /etc/locale.conf
          export LANG
        fi

        # User-defined environment variables
        ${builtins.concatStringsSep "\n" (
          mapAttrsToList (name: value: "export ${name}=${escapeShellArg (toString value)}") envVars
        )}

        # XDG base directories
        export XDG_DATA_DIRS="/run/current-system/sw/share''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
        export XDG_CONFIG_DIRS="/etc/xdg''${XDG_CONFIG_DIRS:+:$XDG_CONFIG_DIRS}"

        # System shell initialization
        ${shellInit}

        # Source bash-specific profile
        if [ -n "$BASH_VERSION" ]; then
          [ -f /etc/bashrc ] && source /etc/bashrc
        fi

        # Login shell initialization
        ${loginInit}

        # Source user's profile if it exists
        [ -f ~/.profile ] && source ~/.profile
      '';

      # Hostname configuration
      "hostname".text = "${hostName}";

      # Hosts file
      "hosts".text = ''
        127.0.0.1 localhost
        ::1 localhost
        127.0.1.1 ${hostName}
      '';
    };

  # Shared computation used by both the buildEtc defaultFunc (so sibling
  # modules can read this module's output via inputs) and impl below.
  computeEnabled =
    { options, inputs }:
    let
      essentials = mkEssential {
        ekaosVersion = inputs.toplevel.ekaos.version;
        hostName = inputs.networking.hostName or "ekaos";
        shellAliases =
          inputs.shellEnv.shellAliases or {
            ls = "ls --color=auto";
            ll = "ls -lh";
            la = "ls -lah";
            grep = "grep --color=auto";
          };
        interactiveInit = inputs.shellEnv.interactiveInit or "";
        envVars = inputs.shellEnv.variables or { };
        shellInit = inputs.shellEnv.shell.init or "";
        loginInit = inputs.shellEnv.shell.loginInit or "";
      };
      merged = options.etc // essentials;
      withTargets = builtins.mapAttrs (
        name: f: if builtins.isAttrs f then f // { target = f.target or name; } else f
      ) merged;
    in
    {
      inherit essentials;
      enabled = builtins.filter (f: (f.enable or true)) (builtins.attrValues withTargets);
    };
in

{
  options = {
    etc = {
      type = types.attrsOf types.attrs;
      default = { };
      example = {
        "hostname".text = "myhost";
        "hosts".text = ''
          127.0.0.1 localhost
          ::1 localhost
        '';
      };
      description = ''
        Files to include in /etc.

        Each attribute defines a file in /etc with its content or source.
      '';
    };

    # Read-only output exposed as an option (via defaultFunc, not impl) so
    # sibling modules can consume it through adios inputs, which only see
    # options — never impl results.
    buildEtc = {
      type = types.derivation;
      defaultFunc = { options, inputs }: buildEtcDir (computeEnabled { inherit options inputs; }).enabled;
      description = ''
        The /etc directory for the system.
        Read-only output computed from options + inputs.
      '';
    };
  };

  inputs = {
    toplevel.from = { parent }: parent.toplevel;
    networking.from = { root }: root.networking;
    shellEnv.from = { root }: root.config."shell-environment";
  };

  impl =
    { options, inputs }:
    let
      computed = computeEnabled { inherit options inputs; };
    in
    {
      # Essential /etc files contribution (tree merges with user files).
      environment.etc = computed.essentials;

      system.build.etc = buildEtcDir computed.enabled;
    };
}
