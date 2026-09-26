# Adios port of ekaos/modules/config/nsswitch.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, ... }:

{
  options = {
    nssDatabases = {
      options = {
        passwd = {
          type = types.listOf types.string;
          default = [ "files" ];
          description = "NSS passwd database entries for /etc/nsswitch.conf.";
        };

        group = {
          type = types.listOf types.string;
          default = [ "files" ];
          description = "NSS group database entries for /etc/nsswitch.conf.";
        };

        shadow = {
          type = types.listOf types.string;
          default = [ "files" ];
          description = "NSS shadow database entries for /etc/nsswitch.conf.";
        };

        hosts = {
          type = types.listOf types.string;
          default = [
            "files"
            "dns"
          ];
          description = "NSS hosts database entries for /etc/nsswitch.conf.";
        };

        services = {
          type = types.listOf types.string;
          default = [ "files" ];
          description = "NSS services database entries for /etc/nsswitch.conf.";
        };
      };
      description = "NSS database entries for /etc/nsswitch.conf.";
    };
  };

  impl =
    { options, ... }:
    {
      environment.etc."nsswitch.conf".text = ''
        passwd:    ${builtins.concatStringsSep " " options.nssDatabases.passwd}
        group:     ${builtins.concatStringsSep " " options.nssDatabases.group}
        shadow:    ${builtins.concatStringsSep " " options.nssDatabases.shadow}

        hosts:     ${builtins.concatStringsSep " " options.nssDatabases.hosts}
        networks:  files

        services:  ${builtins.concatStringsSep " " options.nssDatabases.services}
        protocols: files
        rpc:       files
        ethers:    files
      '';
    };
}
