# System-wide Git configuration
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.git;

  # Convert gitconfig attrs to INI format
  toGitINI =
    attrs:
    concatStringsSep "\n" (
      mapAttrsToList (
        section: values:
        "[${section}]\n"
        + concatStringsSep "\n" (mapAttrsToList (key: value: "\t${key} = ${toString value}") values)
      ) attrs
    )
    + "\n";

in

{
  options.programs.git = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to install and configure Git system-wide.";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.git;
      description = "Git package to use.";
    };

    config = mkOption {
      type = types.attrsOf (types.attrsOf types.anything);
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

    attributes = mkOption {
      type = types.lines;
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
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to install and configure Git LFS.";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ] ++ optional cfg.lfs.enable pkgs.git-lfs;

    # System-wide gitconfig
    environment.etc."gitconfig" = mkIf (cfg.config != { }) {
      text = toGitINI (
        cfg.config
        // optionalAttrs cfg.lfs.enable {
          filter.lfs = {
            clean = "git-lfs clean -- %f";
            smudge = "git-lfs smudge -- %f";
            process = "git-lfs filter-process";
            required = true;
          };
        }
      );
    };

    # System-wide gitattributes
    environment.etc."gitattributes" = mkIf (cfg.attributes != "") {
      text = cfg.attributes;
    };
  };
}
