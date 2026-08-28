# Package manifest generation for SBOM support
#
# Produces a JSON file listing all packages in the system closure with
# authoritative metadata (name, version, license, description, homepage)
# and role classification (default, user, service, home, boot).
#
# The manifest is embedded at <toplevel>/package-manifest.json and consumed
# by `ekapkgs closure sbom` to produce CycloneDX SBOMs without the
# heuristic store-path-name parsing that tools like sbomnix rely on.
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  # Safely extract metadata from a package.
  # Uses tryEval because some packages have meta values that cannot be
  # serialized to JSON (thunks, infinite recursion, etc).
  extractMeta =
    pkg: role: source:
    let
      tryOr =
        default: expr:
        let
          result = builtins.tryEval expr;
        in
        if result.success then result.value else default;
      pname = tryOr (builtins.parseDrvName (pkg.name or "unknown")).name (
        pkg.pname or (builtins.parseDrvName pkg.name).name
      );
      version = tryOr (builtins.parseDrvName (pkg.name or "unknown")).version (
        pkg.version or (builtins.parseDrvName pkg.name).version
      );
      storePath = builtins.unsafeDiscardStringContext (toString pkg);
      outputPaths = tryOr { } (
        let
          raw = pkg.outputs or { };
        in
        if builtins.isList raw then
          listToAttrs (
            map (name: nameValuePair name (builtins.unsafeDiscardStringContext (toString pkg.${name}))) raw
          )
        else
          mapAttrs (_: v: builtins.unsafeDiscardStringContext (toString v)) raw
      );
      licenses =
        let
          raw = tryOr [ ] (toList (pkg.meta.license or [ ]));
        in
        map (l: {
          spdxId = tryOr null (l.spdxId or null);
          fullName = tryOr "unknown" (l.fullName or l.shortName or "unknown");
        }) raw;
      description = tryOr "" (pkg.meta.description or "");
      homepage = tryOr "" (
        let
          hp = pkg.meta.homepage or "";
        in
        if builtins.isList hp then builtins.head hp else hp
      );

      # CPE identifier for vulnerability matching (e.g., "cpe:2.3:a:gnu:hello:2.10:*:*:*:*:*:*:*")
      cpe = tryOr null (pkg.meta.identifiers.cpe or null);

      # PURL identifier for package identification (e.g., "pkg:nix/nixpkgs/hello@2.10")
      purl = tryOr null (pkg.meta.identifiers.purl or null);

      # Source provenance: list of source type names
      # e.g., ["fromSource"] or ["binaryNativeCode"]
      sourceProvenance = tryOr [ ] (
        map (t: t.shortName or (t.name or "unknown")) (pkg.meta.sourceProvenance or [ ])
      );

      # Known vulnerabilities: list of CVE identifiers
      knownVulnerabilities = tryOr [ ] (pkg.meta.knownVulnerabilities or [ ]);

      # Changelog URL
      changelog = tryOr "" (
        let
          cl = pkg.meta.changelog or "";
        in
        if builtins.isList cl then builtins.head cl else cl
      );

      # Main program name
      mainProgram = tryOr "" (pkg.meta.mainProgram or "");
    in
    {
      inherit
        pname
        version
        storePath
        licenses
        description
        homepage
        role
        source
        cpe
        purl
        sourceProvenance
        knownVulnerabilities
        changelog
        mainProgram
        ;
      outputs = outputPaths;
    };

  # Collect service packages from enabled services that have a .package option.
  # Uses tryEval because accessing options on disabled services may throw
  # (e.g., internal options like `command` that have no default value).
  tryGetServicePkg =
    name: svc:
    let
      result = builtins.tryEval (
        builtins.isAttrs svc
        && (svc.enable or false)
        && (svc ? package)
        && (builtins.isAttrs (svc.package or null) || lib.isDerivation (svc.package or null))
      );
    in
    if result.success && result.value then
      [
        {
          pkg = svc.package;
          source = "services.${name}";
        }
      ]
    else
      [ ];

  tryGetSubServicePkg =
    name: subName: subSvc:
    let
      result = builtins.tryEval (
        builtins.isAttrs subSvc
        && (subSvc.enable or false)
        && (subSvc ? package)
        && (builtins.isAttrs (subSvc.package or null) || lib.isDerivation (subSvc.package or null))
      );
    in
    if result.success && result.value then
      [
        {
          pkg = subSvc.package;
          source = "services.${name}.${subName}";
        }
      ]
    else
      [ ];

  servicePackages =
    let
      svcs = config.services or { };
      collected = concatLists (
        mapAttrsToList (
          name: svc:
          let
            direct = tryGetServicePkg name svc;
          in
          if direct != [ ] then
            direct
          else if builtins.isAttrs svc then
            # Check one level of nesting (e.g., services.networking.nginx)
            let
              subResult = builtins.tryEval (filterAttrs (_: v: builtins.isAttrs v) svc);
            in
            if subResult.success then
              concatLists (
                mapAttrsToList (subName: subSvc: tryGetSubServicePkg name subName subSvc) subResult.value
              )
            else
              [ ]
          else
            [ ]
        ) svcs
      );
    in
    collected;

  # Build store path sets for role classification.
  defaultPkgPaths = map (
    p: builtins.unsafeDiscardStringContext (toString p)
  ) config.environment.defaultPackages;
  servicePkgPaths = map (s: builtins.unsafeDiscardStringContext (toString s.pkg)) servicePackages;
  homePkgs = concatLists (
    mapAttrsToList (
      userName: userCfg:
      map (p: {
        pkg = p;
        source = "users.users.${userName}.packages";
      }) (userCfg.packages or [ ])
    ) (config.users.users or { })
  );
  homePkgPaths = map (h: builtins.unsafeDiscardStringContext (toString h.pkg)) homePkgs;

  # Classify a system package.
  classifySystemPkg =
    pkg:
    let
      path = builtins.unsafeDiscardStringContext (toString pkg);
    in
    if builtins.elem path defaultPkgPaths then
      {
        role = "default";
        source = "environment.defaultPackages";
      }
    else if builtins.elem path servicePkgPaths then
      let
        match = findFirst (
          s: builtins.unsafeDiscardStringContext (toString s.pkg) == path
        ) null servicePackages;
      in
      {
        role = "service";
        source = if match != null then match.source else "services";
      }
    else
      {
        role = "user";
        source = "environment.systemPackages";
      };

  # Collect all packages with classifications.
  systemPkgEntries = map (
    pkg:
    let
      cls = classifySystemPkg pkg;
    in
    extractMeta pkg cls.role cls.source
  ) config.environment.systemPackages;

  homePkgEntries = map (h: extractMeta h.pkg "home" h.source) homePkgs;

  bootPkgEntries =
    let
      kernel = config.boot.kernelPackages.kernel or null;
      systemd = config.systemd.package or null;
    in
    (optional (kernel != null) (extractMeta kernel "boot" "boot.kernelPackages.kernel"))
    ++ (optional (systemd != null) (extractMeta systemd "boot" "systemd.package"));

  # Deduplicate by store path, preferring entries with more specific roles.
  allEntries = systemPkgEntries ++ homePkgEntries ++ bootPkgEntries;

  # Convert to the JSON-friendly format (rename "licenses" to "license"
  # to match the schema the Rust side expects).
  toJsonEntry = entry: {
    inherit (entry)
      pname
      version
      storePath
      outputs
      description
      homepage
      role
      source
      cpe
      purl
      sourceProvenance
      knownVulnerabilities
      changelog
      mainProgram
      ;
    license = entry.licenses;
  };

  manifest = {
    version = 1;
    system = pkgs.stdenv.hostPlatform.system;
    ekaosVersion = config.system.ekaos.version;
    packages = map toJsonEntry allEntries;
  };

  manifestFile = pkgs.writeText "package-manifest.json" (builtins.toJSON manifest);

in

{
  options.system.build.packageManifest = mkOption {
    type = types.package;
    readOnly = true;
    description = ''
      JSON manifest of all packages in the system closure with metadata.

      Contains package name, version, license, description, homepage,
      and role classification for SBOM generation.

      The file is embedded at `<toplevel>/package-manifest.json`.
    '';
  };

  config = {
    system.build.packageManifest = manifestFile;
  };
}
