{ lib, ... }:

let
  inherit (lib)
    literalExpression
    mkOption
    types
    ;
in
{
  options = {
    allowAliases = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to expose old attribute names for compatibility.

        The recommended setting is to enable this, as it
        improves backward compatibility, easing updates.

        The only reason to disable aliases is for continuous
        integration purposes. For instance, Nixpkgs should
        not depend on aliases in its internal code. Projects
        that aren't Nixpkgs should be cautious of instantly
        removing all usages of aliases, as migrating too soon
        can break compatibility with the stable Nixpkgs releases.
      '';
    };

    allowUnfree = mkOption {
      type = types.bool;
      default = false;
      # getEnv part is in check-meta.nix
      defaultText = literalExpression ''false || builtins.getEnv "NIXPKGS_ALLOW_UNFREE" == "1"'';
      description = ''
        Whether to allow unfree packages.

        See [Installing unfree packages](https://nixos.org/manual/nixpkgs/stable/#sec-allow-unfree) in the NixOS manual.
      '';
    };

    allowBroken = mkOption {
      type = types.bool;
      default = false;
      # getEnv part is in check-meta.nix
      defaultText = literalExpression ''false || builtins.getEnv "NIXPKGS_ALLOW_BROKEN" == "1"'';
      description = ''
        Whether to allow broken packages.

        See [Installing broken packages](https://nixos.org/manual/nixpkgs/stable/#sec-allow-broken) in the NixOS manual.
      '';
    };

    allowUnsupportedSystem = mkOption {
      type = types.bool;
      default = false;
      # getEnv part is in check-meta.nix
      defaultText = literalExpression ''false || builtins.getEnv "NIXPKGS_ALLOW_UNSUPPORTED_SYSTEM" == "1"'';
      description = ''
        Whether to allow unsupported packages.

        See [Installing packages on unsupported systems](https://nixos.org/manual/nixpkgs/stable/#sec-allow-unsupported-system) in the NixOS manual.
      '';
    };

    allowVariants = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to expose the nixpkgs variants.

        Variants are instances of the current nixpkgs instance with different stdenvs or other applied options.
        This allows for using different toolchains, libcs, or global build changes across nixpkgs.
        Disabling can ensure nixpkgs is only building for the platform which you specified.
      '';
    };

    showDerivationWarnings = mkOption {
      type = types.listOf (types.enum [ "has-maintainers" ]);
      default = [ "has-maintainers" ];
      description = ''
        Which warnings to display for potentially dangerous
        or deprecated values passed into `stdenv.mkDerivation`.

        A list of warnings can be found in
        [/pkgs/stdenv/generic/check-meta.nix](https://github.com/NixOS/nixpkgs/blob/master/pkgs/stdenv/generic/check-meta.nix).

        This is not a stable interface; warnings may be added, changed
        or removed without prior notice.
      '';
    };

    checkMeta = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to check that the `meta` attribute of derivations are correct during evaluation time.
      '';
    };

    hashedMirrors = mkOption {
      type = types.listOf types.str;
      # This does not exist for ekapkgs yet
      default = [ ];
      description = ''
        The set of content-addressed/hashed mirror URLs used by [`pkgs.fetchurl`](#sec-pkgs-fetchers-fetchurl).
        In case `pkgs.fetchurl` can't download from the given URLs,
        it will try the hashed mirrors based on the expected output hash.
        See [`copy-tarballs.pl`](https://github.com/NixOS/nixpkgs/blob/a2d829eaa7a455eaa3013c45f6431e705702dd46/maintainers/scripts/copy-tarballs.pl)
        for more details on how hashed mirrors are constructed.
      '';
    };

    rewriteURL = mkOption {
      type = types.functionTo (types.nullOr types.str);
      description = ''
        A hook to rewrite/filter URLs before they are fetched.

        The function is passed the URL as a string, and is expected to return a new URL, or null if the given URL should not be attempted.

        This function is applied _prior_ to resolving mirror:// URLs.

        The intended use is to allow URL rewriting to insert company-internal mirrors, or work around company firewalls and similar network restrictions.
      '';
      default = lib.id;
      defaultText = literalExpression "(url: url)";
      example = literalExpression ''
        {
          # Use Nix like it's 2024! ;-)
          rewriteURL = url: "https://web.archive.org/web/2024/''${url}";
        }
      '';
    };
  };
}
