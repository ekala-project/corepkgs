# Adios port of ekaos/modules/programs/git.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, pkgs, ... }:

let
  # Local `mapAttrsToList` (no nixpkgs lib allowed).
  mapAttrsToList = f: set: builtins.map (n: f n set.${n}) (builtins.attrNames set);

  # Convert gitconfig attrs to INI format
  toGitINI =
    attrs:
    builtins.concatStringsSep "\n" (
      mapAttrsToList (
        section: values:
        "[${section}]\n"
        + builtins.concatStringsSep "\n" (
          mapAttrsToList (key: value: "\t${key} = ${toString value}") values
        )
      ) attrs
    )
    + "\n";
in

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = "Whether to install and configure Git system-wide.";
    };

    package = {
      type = types.derivation;
      default = pkgs.git;
      description = "Git package to use.";
    };

    config = {
      type = types.attrsOf (types.attrsOf types.any);
      default = { };
      example = {
        init.defaultBranch = "main";
        core.autocrlf = "input";
        pull.rebase = true;
      };
      description = ''
        System-wide Git configuration written to /etc/gitconfig.
        Attribute names are INI section names, values are key-value pairs.
      '';
    };

    attributes = {
      type = types.string;
      default = "";
      example = ''
        *.pdf diff=pdf
        *.gz binary
      '';
      description = ''
        System-wide gitattributes written to /etc/gitattributes.
      '';
    };

    lfs = {
      description = "Git LFS configuration.";
      options = {
        enable = {
          type = types.bool;
          default = false;
          description = "Whether to install and configure Git LFS.";
        };
      };
    };
  };

  impl =
    { options, ... }:
    if !options.enable then
      { }
    else
      {
        environment.systemPackages = [
          options.package
        ]
        ++ (if options.lfs.enable then [ pkgs.git-lfs ] else [ ]);

        # System-wide gitconfig / gitattributes (each emitted only when set).
        environment.etc =
          (
            if options.config != { } then
              {
                gitconfig.text = toGitINI (
                  options.config
                  // (
                    if options.lfs.enable then
                      {
                        filter.lfs = {
                          clean = "git-lfs clean -- %f";
                          smudge = "git-lfs smudge -- %f";
                          process = "git-lfs filter-process";
                          required = true;
                        };
                      }
                    else
                      { }
                  )
                );
              }
            else
              { }
          )
          // (
            if options.attributes != "" then
              {
                gitattributes.text = options.attributes;
              }
            else
              { }
          );
      };
}
