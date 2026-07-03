# Cross-platform tmpfiles options
# Structured rules for declarative file/directory state management
{ lib }:

let
  inherit (lib) types mkOption;
in
{
  # A single tmpfile rule
  ruleOptions = {
    options = {
      type = mkOption {
        type = types.enum [
          "directory"
          "file"
          "symlink"
          "remove"
          "recursive-permissions"
        ];
        description = ''
          Rule type:
            directory — create directory (mkdir -p)
            file — create file with optional content
            symlink — create symbolic link
            remove — remove path
            recursive-permissions — recursively set ownership/permissions
        '';
      };

      path = mkOption {
        type = types.str;
        example = "/var/lib/myapp";
        description = "Target path for the rule.";
      };

      mode = mkOption {
        type = types.str;
        default = "0755";
        example = "0644";
        description = "File permissions (octal string).";
      };

      user = mkOption {
        type = types.str;
        default = "root";
        description = "Owner user.";
      };

      group = mkOption {
        type = types.str;
        default = "root";
        description = "Owner group.";
      };

      age = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "10d";
        description = ''
          Cleanup age. Files/dirs older than this are removed.
          Only used with directory type on systemd (tmpfiles.d age field).
          Format: number + suffix (s, m, h, d, w).
        '';
      };

      content = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "File content (for type = file).";
      };

      target = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "/actual/path";
        description = "Symlink target (for type = symlink).";
      };
    };
  };
}
