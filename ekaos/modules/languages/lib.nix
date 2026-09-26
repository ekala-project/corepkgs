# Adios port of ekaos/modules/languages/lib.nix.
#
# Adios-aware helper consumed via relative import by each
# ekaos/adios/modules/languages/<name>.nix module:
#   langLib = import ./lib.nix { inherit types; };
#   langLib.mkLanguageModule { inherit pkgs; name = "..."; ... }
#
# Takes `{ types, ... }:` (korora/adios types only, never nixpkgs lib) and
# exposes the pkgs-many version resolvers plus `mkLanguageModule`, which
# RETURNS AN ADIOS MODULE (`{ options, impl }`) for one language.
#
# TODO(adios-cutover): per-user wiring (`users.users.<u>.languages.<lang>`
# with packages/sessionVariables/sessionPath, including version resolution
# via mkDefault) from the legacy helper is dropped; there is no adios users
# module to attach it to yet. `sessionPath` args are still accepted (each
# language file preserves its expr verbatim) but currently unused --
# sessionPath only ever fed per-user config in the legacy helper.
# TODO(adios-cutover): `imports` passthrough dropped; legacy imports are
# covered by tree node parent.<path> (none of the language modules use it).
# TODO(adios-cutover): version-resolution priority lost (was `mkDefault`):
# when `version` is set the resolved package always wins; an explicit
# `package` no longer takes precedence.
# TODO(adios-cutover): `extraOptions` (legacy nixpkgs `mkOption` sets) are
# merged verbatim and may reference nixpkgs types; none of the current
# language modules use them.
{ types, ... }:

let
  # Local split-on-"." (no nixpkgs lib allowed). `builtins.split` keeps the
  # separators (as strings or empty group lists), so keep only the parts.
  splitDot =
    s:
    builtins.filter (p: builtins.isString p && builtins.match "[.]" p == null) (builtins.split "[.]" s);

  # Convert a version string like "0.15" or "0.15.2" to variant attr name "v0_15"
  versionToVariantName =
    version:
    let
      parts = splitDot version;
      major = builtins.elemAt parts 0;
      minor = builtins.elemAt parts 1;
    in
    "v${major}_${minor}";

  # Generic resolver: try a variant name, list available on failure
  resolveVariant =
    name: variantPattern: pkgs: version: variantName:
    let
      pkg = pkgs.${name} or (throw "languages.${name}: package pkgs.${name} does not exist");
      variant = pkg.${variantName} or null;
    in
    if variant != null then
      variant
    else
      let
        availableNames = builtins.filter (n: builtins.match variantPattern n != null) (
          builtins.attrNames pkg
        );
      in
      throw "languages.${name}: version \"${version}\" is not available. Known variants: ${builtins.concatStringsSep ", " availableNames}";

  # Standard resolver: "0.15" or "0.15.2" -> v0_15 (major.minor)
  mkVersionResolver =
    name: pkgs: version:
    let
      variantName = versionToVariantName version;
    in
    resolveVariant name "v[0-9]+_[0-9]+" pkgs version variantName;

  # Major-only resolver: "24" or "24.20" -> v24 (for nodejs, java)
  mkMajorVersionResolver =
    name: pkgs: version:
    let
      parts = splitDot version;
      major = builtins.elemAt parts 0;
      variantName = "v${major}";
    in
    resolveVariant name "v[0-9]+" pkgs version variantName;

  # Compact resolver: "8.4" or "84" -> v84 (for php, no separator)
  mkCompactVersionResolver =
    name: pkgs: version:
    let
      # Accept "8.4" -> "84" or "84" -> "84"
      stripped = builtins.replaceStrings [ "." ] [ "" ] version;
      variantName = "v${stripped}";
    in
    resolveVariant name "v[0-9]+" pkgs version variantName;
in

{
  inherit mkVersionResolver mkMajorVersionResolver mkCompactVersionResolver;

  mkLanguageModule =
    {
      # pkgs for default-package / version-resolver evaluation (module args).
      pkgs,

      # Required: language name (e.g. "zig", "rust", "go")
      name,

      # Required: how to get the default package
      # Type: pkgs -> package
      defaultPackage,

      # Optional: custom version resolver (overrides the default mkVersionResolver)
      # Type: pkgs -> string -> package
      resolveVersion ? (mkVersionResolver name),

      # Optional: default LSP package
      # Type: pkgs -> package | null
      defaultLspPackage ? _: null,

      # Optional: language-specific environment variables
      # Type: options -> attrset of string
      environmentVariables ? _: { },

      # Optional: language-specific session path entries (per-user only in
      # legacy; accepted but unused here, see header TODO).
      # Type: options -> list of string
      sessionPath ? _: [ ],

      # Optional: additional options to merge into the module options
      extraOptions ? { },

      # Optional (legacy): additional NixOS modules to import. Dropped in
      # adios (see header TODO); accepted so call sites stay verbatim.
      imports ? [ ],
    }:

    let
      lspPkg = defaultLspPackage pkgs;
    in

    # Return an adios module. Tree path: languages/<name> is
    # parent.languages.<name>.
    {
      options = {
        enable = {
          type = types.bool;
          default = false;
          description = "Whether to enable the ${name} programming language toolchain.";
        };

        package = {
          type = types.derivation;
          default = defaultPackage pkgs;
          description = "The ${name} compiler/toolchain package.";
        };

        version = {
          type = types.nullOr types.string;
          default = null;
          example = "0.15";
          description = ''
            Version of ${name} to use. When set, overrides `package` by
            resolving through the pkgs-many variant system.
            Uses major.minor matching (e.g. "0.15" matches variant v0_15).
          '';
        };

        lsp = {
          description = "The ${name} language server.";
          options = {
            enable = {
              type = types.bool;
              default = lspPkg != null;
              description = "Whether to include the ${name} language server.";
            };

            package = {
              type = types.nullOr types.derivation;
              default = lspPkg;
              description = "The ${name} language server package.";
            };
          };
        };
      }
      # TODO(adios-cutover): legacy extraOptions were nixpkgs mkOption sets;
      # merged verbatim, may reference nixpkgs types.
      // extraOptions;

      impl =
        { options, ... }:
        let
          # TODO(adios-cutover): priority lost (was `mkDefault`): an explicit
          # `package` no longer wins over `version`.
          pkg = if options.version != null then resolveVersion pkgs options.version else options.package;
          langPackages = [
            pkg
          ]
          ++ (if options.lsp.enable && options.lsp.package != null then [ options.lsp.package ] else [ ]);
          envVars = environmentVariables (options // { package = pkg; });
          # Accepted-for-parity only; feeds nothing at system level (see
          # header TODO about dropped per-user wiring).
          _paths = sessionPath (options // { package = pkg; });
        in
        if !options.enable then
          { }
        else
          {
            environment.packages = langPackages;
            environment.variables = envVars;
          };
    };
}
