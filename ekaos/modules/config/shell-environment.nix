# Environment variables and shell configuration
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    environment.variables = mkOption {
      type = types.attrsOf (
        types.oneOf [
          types.str
          types.path
          types.package
        ]
      );
      default = {
        PAGER = "less";
        EDITOR = "vi";
      };
      example = literalExpression ''
        {
          EDITOR = "vim";
          PAGER = "less";
          TERM = "xterm-256color";
        }
      '';
      description = ''
        System-wide environment variables.
        Set in /etc/profile for all users.
      '';
    };

    environment.shell = {
      init = mkOption {
        type = types.lines;
        default = "";
        example = ''
          eval "$(direnv hook bash)"
        '';
        description = ''
          Shell initialization commands run for all shells.
          Sourced from /etc/profile.
        '';
      };

      loginInit = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Shell commands run only for login shells.
          Sourced from /etc/profile after shell.init.
        '';
      };
    };

    environment.shells = mkOption {
      type = types.listOf (types.either types.package types.path);
      default = [ ];
      example = literalExpression "[ pkgs.bash pkgs.dash ]";
      description = ''
        A list of permissible login shells for user accounts.
        /bin/sh is placed into /etc/shells implicitly.
      '';
    };

    programs.bash = {
      shellAliases = mkOption {
        type = types.attrsOf types.str;
        default = {
          ls = "ls --color=auto";
          ll = "ls -lh";
          la = "ls -lah";
          grep = "grep --color=auto";
        };
        example = literalExpression ''
          {
            ls = "ls --color=auto";
            ll = "ls -lah";
            vim = "nvim";
          }
        '';
        description = "System-wide bash aliases, set in /etc/bashrc.";
      };

      interactiveInit = mkOption {
        type = types.lines;
        default = "";
        example = ''
          bind '"\e[A": history-search-backward'
        '';
        description = ''
          Bash commands run for interactive shells.
          Sourced from /etc/bashrc.
        '';
      };
    };
  };

  config = {
    # Generate /etc/shells from environment.shells
    environment.etc.shells = mkIf (config.environment.shells != [ ]) {
      text =
        let
          shellPath =
            s: if isString s || isPath s then toString s else "${s}${s.shellPath or "/bin/${s.pname or s.name}"}";
        in
        concatStringsSep "\n" (map shellPath config.environment.shells)
        + "\n/bin/sh\n";
    };
  };
}
