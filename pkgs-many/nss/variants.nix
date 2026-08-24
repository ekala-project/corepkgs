{
  esr = {
    version = "3.112.5";
    hash = "sha256-+u29CbE5IyapF5w4IeBXDiiNK7usVn30C08G5FWVC88=";
    versionRegex = "NSS_(3)_(112)(?:_(\\d+))?_RTM";
  };

  latest = {
    version = "3.127";
    hash = "sha256-SiaKDkDTHqhTCs/pcwOAk0lgIayeMKOwGLAZr9WKS4Q=";
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
