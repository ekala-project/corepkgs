# Kernel runtime parameters (sysctl)
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.boot.kernel.sysctl;

  sysctlOption = mkOptionType {
    name = "sysctl option value";
    check =
      val:
      let
        checkType = x: isBool x || isString x || isInt x || x == null;
      in
      checkType val || (val._type or "" == "override" && checkType val.content);
    merge = loc: defs: mergeOneOption loc defs;
  };

in

{
  options.boot.kernel.sysctl = mkOption {
    type =
      let
        highestValueType = types.ints.unsigned // {
          merge =
            loc: defs:
            foldl (a: b: if b.value == null then null else max a b.value) 0 defs;
        };
      in
      types.submodule {
        freeformType = types.attrsOf sysctlOption;
        options = {
          "net.core.rmem_max" = mkOption {
            type = types.nullOr highestValueType;
            default = null;
            description = "Maximum receive socket buffer size in bytes. Conflicting values resolve to the highest.";
          };

          "net.core.wmem_max" = mkOption {
            type = types.nullOr highestValueType;
            default = null;
            description = "Maximum send socket buffer size in bytes. Conflicting values resolve to the highest.";
          };
        };
      };
    default = { };
    example = literalExpression ''
      { "net.ipv4.tcp_syncookies" = false; "vm.swappiness" = 60; }
    '';
    description = ''
      Runtime parameters of the Linux kernel, as set by sysctl(8).
      Sysctl parameter names must be enclosed in quotes
      (e.g. "vm.swappiness" instead of vm.swappiness).
      Values may be a string, integer, boolean, or null
      (null means the parameter will not appear).
    '';
  };

  config = {
    # Generate sysctl.d configuration
    environment.etc."sysctl.d/60-ekaos.conf".text = concatStrings (
      mapAttrsToList (
        n: v: optionalString (v != null) "${n}=${if v == false then "0" else toString v}\n"
      ) cfg
    );

    # Apply sysctl settings at activation
    system.activationScripts.sysctl = stringAfter [ "etc" ] ''
      # Apply sysctl settings
      if [ -d /proc/sys ]; then
        for f in /etc/sysctl.d/*.conf; do
          [ -f "$f" ] && ${pkgs.systemd}/bin/systemctl restart systemd-sysctl.service 2>/dev/null && break || true
        done
      fi
    '';

    # Sensible defaults
    boot.kernel.sysctl = {
      # Hide kernel pointers for unprivileged users
      "kernel.kptr_restrict" = mkDefault 1;

      # Support applications that allocate a lot of memory
      "vm.max_map_count" = mkDefault 1048576;

      # Increase default inotify limits
      "fs.inotify.max_user_instances" = mkDefault 524288;
      "fs.inotify.max_user_watches" = mkDefault 524288;
    };
  };
}
