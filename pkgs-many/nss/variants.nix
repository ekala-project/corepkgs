{
  esr = {
    version = "3.112.2";
    hash = "sha256-hK0TovR0LrVkB96BwCnhwaljDSElR85fnobzCa9+uKo=";
    versionRegex = "NSS_(3)_(112)(?:_(\\d+))?_RTM";
  };

  latest = {
    version = "3.121";
    hash = "sha256-zloUvwiaT/ivyhMrEzPKHOKySgGFUzV1Kr9pEC0g3w=";
    versionRegex = "NSS_(\\d+)_(\\d+)(?:_(\\d+))?_RTM";
    extraMeta = {
      # NOTE: Whenever you updated this version check if the `cacert` package also
      #       needs an update. You can run the regular updater script for cacerts.
      #       It will rebuild itself using the version of this package (NSS) and if
      #       an update is required do the required changes to the expression.
      #       Example: nix-shell ./maintainers/scripts/update.nix --argstr package cacert
    };
  };
}
