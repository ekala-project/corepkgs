# mkLanguageModule - Template function for languages.<name> modules
#
# Generates a NixOS module with common language options (enable, package,
# version, lsp) and wiring for both system-wide and per-user contexts.
# Each language module imports this and extends it with language-specific options.
{ lib }:

let
  inherit (lib)
    mkOption
    mkEnableOption
    mkDefault
    mkIf
    mkMerge
    types
    optional
    concatStringsSep
    splitString
    ;

  # Convert a version string like "0.15" or "0.15.2" to variant attr name "v0_15"
  versionToVariantName =
    version:
    let
      parts = splitString "." version;
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
      throw "languages.${name}: version \"${version}\" is not available. Known variants: ${concatStringsSep ", " availableNames}";

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
      parts = splitString "." version;
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
      # Type: config -> attrset of string
      environmentVariables ? _: { },

      # Optional: language-specific session path entries
      # Type: config -> list of string
      sessionPath ? _: [ ],

      # Optional: additional options to merge into languages.<name>
      extraOptions ? { },

      # Optional: additional NixOS modules to import. These receive the full
      # { config, lib, pkgs, ... } module arguments, giving them access to the
      # entire system/devshell config — not just the language's own config.
      imports ? [ ],
    }:

    let
      # Build the option set used for both system-level and per-user
      mkLanguageOptions =
        pkgs:
        let
          lspPkg = defaultLspPackage pkgs;
        in
        {
          enable = mkEnableOption "the ${name} programming language toolchain";

          package = mkOption {
            type = types.package;
            default = defaultPackage pkgs;
            description = "The ${name} compiler/toolchain package.";
          };

          version = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "0.15";
            description = ''
              Version of ${name} to use. When set, overrides `package` by
              resolving through the pkgs-many variant system.
              Uses major.minor matching (e.g. "0.15" matches variant v0_15).
            '';
          };

          lsp = {
            enable = mkOption {
              type = types.bool;
              default = lspPkg != null;
              description = "Whether to include the ${name} language server.";
            };

            package = mkOption {
              type = types.nullOr types.package;
              default = lspPkg;
              description = "The ${name} language server package.";
            };
          };
        }
        // extraOptions;
    in

    # Return a NixOS module function
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.languages.${name};

      # Collect packages for this language
      langPackages = [
        cfg.package
      ]
      ++ optional (cfg.lsp.enable && cfg.lsp.package != null) cfg.lsp.package;

      envVars = environmentVariables cfg;
      paths = sessionPath cfg;
    in

    {
      inherit imports;

      options.languages.${name} = mkLanguageOptions pkgs;

      # Extend per-user options with the same language options, and wire
      # per-user config within the submodule to avoid infinite recursion.
      options.users.users = mkOption {
        type = types.attrsOf (
          types.submodule (
            { config, ... }:
            let
              uCfg = config.languages.${name};
              uPkgs = [ uCfg.package ] ++ optional (uCfg.lsp.enable && uCfg.lsp.package != null) uCfg.lsp.package;
              uEnvVars = environmentVariables uCfg;
              uPaths = sessionPath uCfg;
            in
            {
              options.languages.${name} = mkLanguageOptions pkgs;

              config = mkMerge [
                # Per-user version resolution
                (mkIf (uCfg.enable && uCfg.version != null) {
                  languages.${name}.package = mkDefault (resolveVersion pkgs uCfg.version);
                })

                # Per-user packages and environment
                (mkIf uCfg.enable {
                  packages = uPkgs;
                  sessionVariables = builtins.mapAttrs (_: toString) uEnvVars;
                  sessionPath = uPaths;
                })
              ];
            }
          )
        );
      };

      config = mkMerge [
        # Version resolution: set package via mkDefault so explicit package overrides win
        (mkIf (cfg.enable && cfg.version != null) {
          languages.${name}.package = mkDefault (resolveVersion pkgs cfg.version);
        })

        # System-level config
        (mkIf cfg.enable {
          environment.packages = langPackages;
          environment.variables = envVars;
        })
      ];
    };
}
