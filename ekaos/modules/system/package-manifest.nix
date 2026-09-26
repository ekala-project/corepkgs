# Adios port of ekaos/modules/system/package-manifest.nix.
#
# Tree path: system/package-manifest is parent.system.package-manifest.
#
# Produces a JSON file listing all packages in the system closure with
# authoritative metadata (name, version, license, description, homepage)
# and role classification (default, user, service, home, boot), embedded
# at <toplevel>/package-manifest.json and consumed by `ekapkgs closure
# sbom` for CycloneDX SBOM generation.
#
# Reads service packages via inputs.services (parent.services), system
# packages + ekaos version via inputs.sysenv (parent.system.toplevel),
# home packages via inputs.home (parent.config."users-groups"), and boot
# packages via inputs.bootKernel (parent.boot.kernel) + inputs.sysenv
# (systemd.package).
# TODO(adios-cutover): AGGREGATION GAP (load-bearing). Legacy scans
# config.services / config.users.users via the global fixpoint (with
# tryEval guards for disabled services). Adios inputs resolve to whatever
# the tree wires; arbitrary service/user modules outside the tree are
# invisible, so service/home roles may be misclassified as user/default.
# TODO(adios-cutover): lib.isDerivation / lib.toList / lib.findFirst have
# no adios.lib equivalents; smallest local reimplementations below.
{ types, pkgs, ... }:

let
  filterAttrs =
    pred: set:
    builtins.listToAttrs (
      builtins.map (n: {
        name = n;
        value = set.${n};
      }) (builtins.filter (n: pred n set.${n}) (builtins.attrNames set))
    );
  mapAttrsToList = f: attrs: builtins.map (n: f n attrs.${n}) (builtins.attrNames attrs);
  toList = x: if builtins.isList x then x else [ x ];
  isDerivation = x: builtins.isAttrs x && (x.type or "") == "derivation";
  findFirst =
    pred: default: list:
    builtins.foldl' (
      acc: x:
      if acc != default then
        acc
      else if pred x then
        x
      else
        default
    ) default list;

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
          builtins.listToAttrs (
            builtins.map (name: {
              inherit name;
              value = builtins.unsafeDiscardStringContext (toString pkg.${name});
            }) raw
          )
        else
          builtins.mapAttrs (_: v: builtins.unsafeDiscardStringContext (toString v)) raw
      );
      licenses =
        let
          raw = tryOr [ ] (toList (pkg.meta.license or [ ]));
        in
        builtins.map (l: {
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
        builtins.map (t: t.shortName or (t.name or "unknown")) (pkg.meta.sourceProvenance or [ ])
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
        && (builtins.isAttrs (svc.package or null) || isDerivation (svc.package or null))
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
        && (builtins.isAttrs (subSvc.package or null) || isDerivation (subSvc.package or null))
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

  collectServicePackages =
    services:
    builtins.concatLists (
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
            builtins.concatLists (
              mapAttrsToList (subName: subSvc: tryGetSubServicePkg name subName subSvc) subResult.value
            )
          else
            [ ]
        else
          [ ]
      ) services
    );

  # Build the manifest derivation from explicitly passed package sets.
  buildManifest =
    {
      services,
      defaultPackages,
      systemPackages,
      users,
      kernel,
      systemdPkg,
      ekaosVersion,
      system,
    }:
    let
      servicePackages = collectServicePackages services;

      # Build store path sets for role classification.
      defaultPkgPaths = builtins.map (
        p: builtins.unsafeDiscardStringContext (toString p)
      ) defaultPackages;
      servicePkgPaths = builtins.map (
        s: builtins.unsafeDiscardStringContext (toString s.pkg)
      ) servicePackages;
      homePkgs = builtins.concatLists (
        mapAttrsToList (
          userName: userCfg:
          builtins.map (p: {
            pkg = p;
            source = "users.users.${userName}.packages";
          }) (userCfg.packages or [ ])
        ) users
      );
      homePkgPaths = builtins.map (h: builtins.unsafeDiscardStringContext (toString h.pkg)) homePkgs;

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
      systemPkgEntries = builtins.map (
        pkg:
        let
          cls = classifySystemPkg pkg;
        in
        extractMeta pkg cls.role cls.source
      ) systemPackages;

      homePkgEntries = builtins.map (h: extractMeta h.pkg "home" h.source) homePkgs;

      bootPkgEntries =
        (if kernel != null then [ (extractMeta kernel "boot" "boot.kernelPackages.kernel") ] else [ ])
        ++ (if systemdPkg != null then [ (extractMeta systemdPkg "boot" "systemd.package") ] else [ ]);

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
        inherit system;
        inherit ekaosVersion;
        packages = builtins.map toJsonEntry allEntries;
      };
    in
    pkgs.writeText "package-manifest.json" (builtins.toJSON manifest);
in

{
  options = {
    # Exposed as an option (via defaultFunc) so sibling modules can consume it
    # through adios inputs, which only see OPTIONS, never impl results.
    buildPackageManifest = {
      type = types.derivation;
      defaultFunc = { options, inputs }:
        buildManifest {
          services = inputs.services;
          defaultPackages = inputs.sysenv.environment.defaultPackages;
          systemPackages = inputs.sysenv.environment.systemPackages;
          users = inputs.home.users.users or { };
          kernel = inputs.bootKernel.kernelPackages.kernel or null;
          systemdPkg = inputs.sysenv.systemd.package or null;
          ekaosVersion = inputs.sysenv.ekaos.version;
          system = pkgs.stdenv.hostPlatform.system;
        };
      description = ''
        JSON manifest of all packages in the system closure with metadata.

        Contains package name, version, license, description, homepage,
        and role classification for SBOM generation.

        The file is embedded at `<toplevel>/package-manifest.json`.
        Read-only output; value comes from the defaultFunc.
      '';
    };
  };

  inputs = {
    services.from = { root }: root.services;
    sysenv.from = { parent }: parent.toplevel;
    home.from = { root }: root.config."users-groups";
    bootKernel.from = { root }: root.boot.kernel;
  };

  impl =
    { options, inputs }:
    {
      system.build.packageManifest = options.buildPackageManifest;
    };
}
