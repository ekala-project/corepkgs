# Generate structured JSON schemas for service configuration options.
#
# Produces a machine-readable representation of service options that preserves
# type structure (enum values, submodule nesting, list element types, etc.)
# for use by CLI tools that need to prompt users for configuration.
#
# The output format uses tagged type unions so the consumer can pattern-match
# on `kind` to render appropriate input widgets.
#
# Two schemas are produced:
#
#   `base`     — the universal service interface from services/lib/service-module.nix.
#                Describes options available to ANY arbitrarily-defined service.
#
#   `services` — per-service schemas discovered by evaluating a concrete configuration.
#                Each entry includes the base options PLUS any service-specific
#                extensions (e.g. openssh's `settings.*`, postgresql's `ensureUsers`).
#                Only populated when a configuration is provided.
#
# The CLI should cache the full output and use `services.<name>` when available,
# falling back to `base` for services not in the evaluated configuration.
#
# Usage:
#   # Base schema only (no configuration needed)
#   nix eval --json --impure --expr 'import ./ekaos/lib/generate-service-options.nix {}'
#
#   # Base + all discovered services from a configuration
#   nix eval --json --impure --expr 'import ./ekaos/lib/generate-service-options.nix { configuration = ./my-config.nix; }'
#
#   # Filter platform-specific options
#   nix eval --json --impure --expr 'import ./ekaos/lib/generate-service-options.nix { platform = "systemd"; }'
#
# Output shape:
#   {
#     "base": { "options": [ ... ] },
#     "services": {
#       "<name>": {
#         "description": "...",
#         "options": [ { path, description, type: { kind, ... }, default?, example?, required } ]
#       }
#     }
#   }
#
# Type schema kinds:
#   bool, str, int, port, path, lines, float, number, package,
#   enum { values }, listOf { element }, attrsOf { element },
#   nullOr { inner }, either { variants }, submodule { options },
#   anything, unspecified { description? }
{
  pkgs ? import ../../. { },
  lib ? pkgs.lib,
  configuration ? { },
  # Optional: restrict platform-specific options to a single platform.
  # "all" (default) | "systemd" | "launchd" | "runit" | "rcd"
  platform ? "all",
}:

let
  inherit (lib)
    types
    isOption
    filterAttrs
    mapAttrs
    mapAttrsToList
    concatMap
    collect
    optional
    optionalAttrs
    showOption
    hasPrefix
    ;

  inherit (builtins)
    tryEval
    toJSON
    isAttrs
    isBool
    isInt
    isFloat
    isString
    isList
    hasAttr
    attrNames
    length
    head
    filter
    map
    elem
    any
    ;

  # ===================================================================
  # Base schema — introspect the canonical service type directly
  # ===================================================================

  serviceLib = import ../../services/lib/service-module.nix { inherit lib pkgs; };

  serviceEval = lib.evalModules {
    modules = [
      {
        options.services = serviceLib.mkServicesOption;
      }
    ];
  };

  servicesType = serviceEval.options.services.type;
  serviceSubOpts = servicesType.getSubOptions [ ];

  # ===================================================================
  # Evaluated schema — discover per-service options from a configuration
  # ===================================================================

  configEval =
    (import ../eval-config.nix {
      inherit lib pkgs;
    })
      {
        modules = [ configuration ];
      };

  # ---------------------------------------------------------------------------
  # Type introspection — convert a Nix option type into a tagged JSON object
  # ---------------------------------------------------------------------------

  # Nix module-system type names (from `type.name`) differ from the
  # user-facing names in some cases. This mapping handles them:
  #   types.port / types.ints.u16 → name = "unsignedInt16"
  #   types.ints.positive         → name = "positiveInt"
  #   types.ints.unsigned         → name = "unsignedInt"
  #   types.lines                 → name = "separatedString"

  # Convert a Nix module-system type to a structured { kind, ... } representation.
  # `depth` guards against infinite recursion in deeply nested or recursive types.
  typeToSchema =
    depth: type:
    if depth > 8 then
      { kind = "unspecified"; }
    else
      let
        name = type.name or "unspecified";
        next = depth + 1;
      in
      if name == "bool" then
        { kind = "bool"; }
      else if name == "str" || name == "string" then
        { kind = "str"; }
      else if name == "int" || name == "integer" then
        { kind = "int"; }
      else if name == "positiveInt" then
        {
          kind = "int";
          positive = true;
        }
      else if name == "unsignedInt" then
        {
          kind = "int";
          unsigned = true;
        }
      else if name == "unsignedInt16" then
        { kind = "port"; }
      else if name == "path" then
        { kind = "path"; }
      else if name == "separatedString" then
        { kind = "lines"; }
      else if name == "float" then
        { kind = "float"; }
      else if name == "number" then
        { kind = "number"; }
      else if name == "package" then
        { kind = "package"; }
      else if name == "anything" || name == "unspecified" || name == "raw" then
        { kind = "anything"; }
      else if name == "enum" then
        let
          payload = type.functor.payload or { };
          values = payload.values or [ ];
          safeValues = filter (v: isString v || isInt v || isBool v) values;
        in
        {
          kind = "enum";
          values = safeValues;
        }
      else if name == "listOf" || name == "nonEmptyListOf" then
        let
          elemType = type.nestedTypes.elemType or null;
        in
        {
          kind = "listOf";
          element = if elemType != null then typeToSchema next elemType else { kind = "unspecified"; };
        }
        // optionalAttrs (name == "nonEmptyListOf") { nonEmpty = true; }
      else if name == "attrsOf" || name == "lazyAttrsOf" then
        let
          elemType = type.nestedTypes.elemType or null;
        in
        {
          kind = "attrsOf";
          element = if elemType != null then typeToSchema next elemType else { kind = "unspecified"; };
        }
      else if name == "nullOr" then
        let
          elemType = type.nestedTypes.elemType or null;
        in
        {
          kind = "nullOr";
          inner = if elemType != null then typeToSchema next elemType else { kind = "unspecified"; };
        }
      else if name == "either" then
        let
          left = type.nestedTypes.left or null;
          right = type.nestedTypes.right or null;
          flattenEither =
            t:
            let
              n = t.name or "";
            in
            if n == "either" then
              (flattenEither (t.nestedTypes.left or t)) ++ (flattenEither (t.nestedTypes.right or t))
            else
              [ (typeToSchema next t) ];
          variants =
            (if left != null then flattenEither left else [ ])
            ++ (if right != null then flattenEither right else [ ]);
        in
        {
          kind = "either";
          inherit variants;
        }
      else if name == "submodule" then
        let
          subOpts = type.getSubOptions [ ];
          # Nested submodules don't need path stripping — paths are relative
          identity = x: x;
          options = optionsToSchemaList (depth + 1) identity subOpts;
        in
        {
          kind = "submodule";
          inherit options;
        }
      # Catch remaining integer subtypes (signedInt8, unsignedInt8, etc.)
      else if
        hasPrefix "signedInt" name || hasPrefix "unsignedInt" name || hasPrefix "positiveInt" name
      then
        { kind = "int"; }
      else
        {
          kind = "unspecified";
          description = type.description or name;
        };

  # ---------------------------------------------------------------------------
  # Option introspection
  # ---------------------------------------------------------------------------

  isModuleInternal = path: hasPrefix "_module." path || hasPrefix "_freeformOptions." path;

  platformGroups = [
    "systemd"
    "launchd"
    "runit"
    "rcd"
  ];

  shouldIncludeOption =
    path:
    if platform == "all" then
      true
    else
      let
        matchesPlatform = any (pg: hasPrefix "${pg}." path || path == pg) platformGroups;
      in
      if matchesPlatform then hasPrefix "${platform}." path || path == platform else true;

  isDrv = v: isAttrs v && (v._type or "" == "derivation" || hasAttr "outPath" v);

  safeToJSON =
    v:
    if v == null then
      "null"
    else if isDrv v then
      let
        nameResult = tryEval (v.pname or v.name or "<package>");
      in
      builtins.toJSON (if nameResult.success then "<${nameResult.value}>" else "<package>")
    else
      let
        result = tryEval (builtins.unsafeDiscardStringContext (toJSON v));
      in
      if result.success then result.value else null;

  safeEval =
    v:
    let
      result = tryEval v;
    in
    if result.success then result.value else null;

  # Build a schema entry from an option declaration.
  # `stripPrefix` is applied to the raw option path.
  optionToSchema =
    depth: stripFn: opt:
    let
      optName = showOption opt.loc;
      visible = opt.visible or true;
      internal = opt.internal or false;

      path = stripFn optName;

      skip =
        internal || (isBool visible && !visible) || isModuleInternal path || !(shouldIncludeOption path);

      optType = opt.type or null;

      typeSchema = if optType != null then typeToSchema depth optType else { kind = "unspecified"; };

      hasDefault = hasAttr "default" opt || hasAttr "defaultText" opt;
      hasExample = hasAttr "example" opt;

      defaultJson =
        if hasAttr "defaultText" opt then
          safeToJSON (safeEval opt.defaultText)
        else if hasAttr "default" opt then
          safeToJSON opt.default
        else
          null;

      exampleJson = if hasExample then safeToJSON opt.example else null;

      entry = {
        inherit path;
        description = opt.description or "";
        type = typeSchema;
        required = !hasDefault;
      }
      // optionalAttrs (defaultJson != null) { default = defaultJson; }
      // optionalAttrs (exampleJson != null) { example = exampleJson; };
    in
    if skip then [ ] else [ entry ];

  optionsToSchemaList =
    depth: stripFn: options:
    if depth > 8 then
      [ ]
    else
      concatMap (opt: optionToSchema depth stripFn opt) (collect isOption options);

  # ---------------------------------------------------------------------------
  # Prefix stripping helpers
  # ---------------------------------------------------------------------------

  # Strip a literal prefix string from a path
  mkStripPrefix =
    prefix:
    let
      plen = builtins.stringLength prefix;
    in
    path:
    let
      slen = builtins.stringLength path;
    in
    if hasPrefix prefix path && slen > plen then builtins.substring plen (slen - plen) path else path;

  # For the base schema: strip the "<name>." prefix added by attrsOf
  baseStripFn = mkStripPrefix "<name>.";

  # ---------------------------------------------------------------------------
  # Base schema
  # ---------------------------------------------------------------------------

  baseAllOptions = optionsToSchemaList 0 baseStripFn serviceSubOpts;
  baseOptions = filter (opt: !(isModuleInternal opt.path)) baseAllOptions;

  # ---------------------------------------------------------------------------
  # Per-service schemas from evaluated configuration
  # ---------------------------------------------------------------------------

  evalServicesOptions = configEval.options.services or { };

  # Identify services: attrsets under services.* that contain an `enable` option
  discoveredServiceNames = filter (
    name:
    let
      v = evalServicesOptions.${name} or null;
    in
    v != null && isAttrs v && !(isOption v) && isOption (v.enable or null)
  ) (attrNames evalServicesOptions);

  mkServiceSchema =
    name:
    let
      serviceOpts = evalServicesOptions.${name};
      prefix = "services.${name}.";
      stripFn = mkStripPrefix prefix;

      rawOptions = optionsToSchemaList 0 stripFn serviceOpts;
      options = filter (opt: !(isModuleInternal opt.path)) rawOptions;

      # Extract description from the service's description option default,
      # falling back to the enable option's description
      descriptionOpt =
        let
          r = tryEval (
            if hasAttr "description" serviceOpts && isOption serviceOpts.description then
              serviceOpts.description.default or ""
            else
              ""
          );
        in
        if r.success then r.value else "";

      enableDesc =
        let
          r = tryEval (serviceOpts.enable.description or "");
        in
        if r.success then r.value else "";

      description = if descriptionOpt != "" then descriptionOpt else enableDesc;
    in
    {
      inherit description options;
    };

  discoveredServices = builtins.listToAttrs (
    map (name: {
      inherit name;
      value = mkServiceSchema name;
    }) discoveredServiceNames
  );

in
{
  base.options = baseOptions;
  services = discoveredServices;
}
