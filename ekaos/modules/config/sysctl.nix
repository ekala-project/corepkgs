# Adios port of ekaos/modules/config/sysctl.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, pkgs, ... }:

{
  options = {
    sysctl = {
      # TODO(adios-cutover): legacy type was a submodule with a freeform
      # attrsOf sysctlOption (bool/str/int/null, override-aware) plus named
      # "net.core.rmem_max"/"net.core.wmem_max" options whose custom merge
      # resolved conflicts to the highest value. Both the override/priority
      # handling and the highest-value merge are lost here.
      type = types.attrsOf types.any;
      default = { };
      example = {
        "net.ipv4.tcp_syncookies" = false;
        "vm.swappiness" = 60;
      };
      description = ''
        Runtime parameters of the Linux kernel, as set by sysctl(8).
        Sysctl parameter names must be enclosed in quotes
        (e.g. "vm.swappiness" instead of vm.swappiness).
        Values may be a string, integer, boolean, or null
        (null means the parameter will not appear).
      '';
    };
  };

  impl =
    { options, ... }:
    let
      optionalString = cond: s: if cond then s else "";
    in
    {
      # Generate sysctl.d configuration
      environment.etc."sysctl.d/60-ekaos.conf".text = builtins.concatStringsSep "" (
        builtins.map (
          n:
          let
            v = options.sysctl.${n};
          in
          optionalString (v != null) "${n}=${if v == false then "0" else toString v}\n"
        ) (builtins.attrNames options.sysctl)
      );

      # Apply sysctl settings at activation
      system.activationScripts.sysctl = {
        deps = [ "etc" ];
        text = ''
          # Apply sysctl settings
          if [ -d /proc/sys ]; then
            for f in /etc/sysctl.d/*.conf; do
              [ -f "$f" ] && ${pkgs.systemd}/bin/systemctl restart systemd-sysctl.service 2>/dev/null && break || true
            done
          fi
        '';
      };

      # Sensible defaults
      # TODO(adios-cutover): priority lost (each value was mkDefault).
      boot.kernel.sysctl = {
        # Hide kernel pointers for unprivileged users
        "kernel.kptr_restrict" = 1;

        # Support applications that allocate a lot of memory
        "vm.max_map_count" = 1048576;

        # Increase default inotify limits
        "fs.inotify.max_user_instances" = 524288;
        "fs.inotify.max_user_watches" = 524288;
      };
    };
}
