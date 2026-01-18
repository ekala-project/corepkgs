let
  x86_64_pkgs = import ../. {
    config = {
      allowAliases = true; # TODO(corepkgs): false
      allowUnfree = false;
      inHydra = true;
    };
  };

  inherit (x86_64_pkgs) lib;
in lib.recurseIntoAttrs {
  x86_64-linux = { inherit (x86_64_pkgs) clang stdenv; };
  muslStdenv = x86_64_pkgs.pkgsMusl.stdenv;
  # TODO(corepkgs): fix
  # staticStdenv = x86_64_pkgs.pkgsStatic.stdenv;
}
