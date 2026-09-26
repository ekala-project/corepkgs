# Adios port of ekaos/modules/config/shell-environment.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, pkgs, ... }:

{
  options = {
    environment = {
      options = {
        variables = {
          type = types.attrsOf (
            types.union [
              types.string
              types.pathLike
              types.derivation
            ]
          );
          default = {
            PAGER = "less";
            EDITOR = "vi";
          };
          example = {
            EDITOR = "vim";
            PAGER = "less";
            TERM = "xterm-256color";
          };
          description = ''
            System-wide environment variables.
            Set in /etc/profile for all users.
          '';
        };

        shell = {
          options = {
            init = {
              type = types.string;
              default = "";
              example = ''
                eval "$(direnv hook bash)"
              '';
              description = ''
                Shell initialization commands run for all shells.
                Sourced from /etc/profile.
              '';
            };

            loginInit = {
              type = types.string;
              default = "";
              description = ''
                Shell commands run only for login shells.
                Sourced from /etc/profile after shell.init.
              '';
            };
          };
          description = "System-wide shell initialization.";
        };

        binsh = {
          type = types.string;
          default = "${pkgs.bash}/bin/sh";
          description = ''
            The shell executable linked to /bin/sh. The system assumes this
            is a POSIX-compatible shell.
          '';
        };

        shells = {
          type = types.listOf (types.either types.derivation types.pathLike);
          default = [ ];
          description = ''
            A list of permissible login shells for user accounts.
            /bin/sh is placed into /etc/shells implicitly.
          '';
        };
      };
      description = "System-wide environment and shell settings.";
    };

    bash = {
      options = {
        shellAliases = {
          type = types.attrsOf types.string;
          default = {
            ls = "ls --color=auto";
            ll = "ls -lh";
            la = "ls -lah";
            grep = "grep --color=auto";
          };
          example = {
            ls = "ls --color=auto";
            ll = "ls -lah";
            vim = "nvim";
          };
          description = "System-wide bash aliases, set in /etc/bashrc.";
        };

        interactiveInit = {
          type = types.string;
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
      description = "System-wide bash settings (programs.bash).";
    };
  };

  impl =
    { options, ... }:
    let
      shellPath =
        s:
        if builtins.isString s || builtins.isPath s then
          toString s
        else
          "${s}${s.shellPath or "/bin/${s.pname or s.name}"}";
    in
    {
      # Create /bin/sh symlink
      system.activationScripts.binsh = {
        deps = [ "etc" ];
        text = ''
          mkdir -p /bin
          chmod 0755 /bin
          ln -sfn "${options.environment.binsh}" /bin/.sh.tmp
          mv /bin/.sh.tmp /bin/sh
        '';
      };

      # Generate /etc/shells from environment.shells
      environment.etc =
        if (options.environment.shells != [ ]) then
          {
            shells.text =
              builtins.concatStringsSep "\n" (builtins.map shellPath options.environment.shells) + "\n/bin/sh\n";
          }
        else
          { };
    };
}
