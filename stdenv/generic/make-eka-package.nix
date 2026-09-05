# mkEkaPackage — scope-based dependency declaration (EEP 0041)
#
# Unlike stdenv.mkDerivation, mkEkaPackage is a scope member, not attached to
# stdenv.  Dependencies are declared as functions that receive the correct
# package scope, eliminating the need for spliced packages.
#
# See: https://github.com/ekala-project/eeps/blob/jonringer/mkekapackage/eeps/0041-mkekapackage.md

{
  lib,
  config,
  stdenv,
  cc ? stdenv.cc,
  scopes,
}:

let
  defaultCC = cc;
in

let
  inherit (lib)
    attrValues
    concatLists
    extendDerivation
    filter
    filterAttrs
    getDev
    intersectAttrs
    isAttrs
    isBool
    isDerivation
    isFunction
    isInt
    isPath
    isString
    mapAttrs
    mapNullable
    optional
    optionalString
    optionals
    toFunction
    typeOf
    unsafeDiscardStringContext
    unsafeGetAttrPos
    warn
    ;

  inherit (lib.generators) toPretty;
  inherit (lib.strings) sanitizeDerivationName;

  checkMeta = import ./check-meta.nix {
    inherit lib config;
  };

  inherit (import ../../build-support/lib/cmake.nix { inherit lib stdenv; }) makeCMakeFlags;
  inherit (import ../../build-support/lib/meson.nix { inherit lib stdenv; }) makeMesonFlags;

  knownHardeningFlags = [
    "bindnow"
    "format"
    "fortify"
    "fortify3"
    "strictflexarrays1"
    "strictflexarrays3"
    "shadowstack"
    "nostrictaliasing"
    "pacret"
    "pic"
    "relro"
    "stackprotector"
    "glibcxxassertions"
    "libcxxhardeningfast"
    "libcxxhardeningextensive"
    "stackclashprotection"
    "strictoverflow"
    "trivialautovarinit"
    "zerocallusedregs"
  ];

  doCheckByDefault = config.doCheckByDefault or false;
  structuredAttrsByDefault = config.structuredAttrsByDefault or false;
  inherit (config) enableParallelBuildingByDefault contentAddressedByDefault;
  userHook = config.stdenv.userHook or null;

  inherit (stdenv)
    hostPlatform
    buildPlatform
    targetPlatform
    extraNativeBuildInputs
    extraBuildInputs
    extraSandboxProfile
    __extraImpureHostDeps
    ;

  buildPlatformSystem = buildPlatform.system;
  buildIsDarwin = buildPlatform.isDarwin;

  inherit (hostPlatform)
    isLinux
    isWindows
    isCygwin
    isStatic
    isMusl
    ;

  useDefaultConfigurePlatforms = hostPlatform != buildPlatform || config.configurePlatformsByDefault;
  defaultConfigurePlatforms = optionals useDefaultConfigurePlatforms [
    "build"
    "host"
  ];
  buildPlatformConfigureFlag = "--build=${buildPlatform.config}";
  hostPlatformConfigureFlag = "--host=${hostPlatform.config}";
  targetPlatformConfigureFlag = "--target=${targetPlatform.config}";
  defaultConfigurePlatformsFlags = optionals useDefaultConfigurePlatforms [
    buildPlatformConfigureFlag
    hostPlatformConfigureFlag
  ];

  defaultStrictDeps = if config.strictDepsByDefault then true else hostPlatform != buildPlatform;
  canExecuteHostOnBuild = buildPlatform.canExecute hostPlatform;

  stdenvHasCC = stdenv.hasCC;
  stdenvShell = stdenv.shell;
  hostSuffixNecessary = hostPlatform != buildPlatform && stdenvHasCC;
  stdenvHostSuffix = "-${hostPlatform.config}";
  stdenvStaticMarker = optionalString isStatic "-static";

  defaultBuilderArgs = [
    "-e"
    ./source-stdenv.sh
    ./default-builder.sh
  ];

  requiredSystemFeaturesShouldBeSet =
    buildPlatform ? gcc.arch
    && !(buildPlatform.isAarch64 && (buildPlatform.isDarwin || buildPlatform.gcc.arch == "armv8-a"));
  gccArchFeature = [ "gccarch-${buildPlatform.gcc.arch}" ];

  commonMeta = checkMeta.commonMeta hostPlatform;
  assertValidity = checkMeta.assertValidity hostPlatform;

  unsafeDerivationToUntrackedOutpath =
    drv:
    if isDerivation drv && (!drv.__contentAddressed or false) then
      unsafeDiscardStringContext drv.outPath
    else
      drv;

  makeOutputChecks = attrs: {
    ${if (attrs ? disallowedReferences) then "disallowedReferences" else null} =
      map unsafeDerivationToUntrackedOutpath attrs.disallowedReferences;
    ${if (attrs ? disallowedRequisites) then "disallowedRequisites" else null} =
      map unsafeDerivationToUntrackedOutpath attrs.disallowedRequisites;
    ${if (attrs ? allowedReferences) then "allowedReferences" else null} =
      mapNullable unsafeDerivationToUntrackedOutpath attrs.allowedReferences;
    ${if (attrs ? allowedRequisites) then "allowedRequisites" else null} =
      mapNullable unsafeDerivationToUntrackedOutpath attrs.allowedRequisites;
  };

  # Flatten a scope-receiving dependency function into a list.
  # Calls fn with the scope, filters out nulls, applies getDev.
  flattenDeps =
    scope: fn:
    let
      raw = fn scope;
      filtered = filterAttrs (_: v: v != null) raw;
      validated = mapAttrs (
        name: v:
        if isDerivation v || isPath v || isString v then
          v
        else
          throw "mkEkaPackage dependency '${name}' is not a derivation, path, or string (got ${typeOf v})"
      ) filtered;
    in
    map getDev (attrValues validated);

  mkEkaPackage = fnOrAttrs: makeDerivationExtensible (toFunction fnOrAttrs);

  # Resolve scope-receiving dependency functions so that finalAttrs.commands.foo
  # returns the actual package.  The raw function form is preserved in `prev`
  # inside overrideAttrs (via `rattrs final`), so composition still works:
  #   pkg.overrideAttrs (prev: { commands = scope: prev.commands scope // { ... }; })
  resolveScoped =
    attrs:
    let
      resolve =
        name: scopeKey:
        if attrs ? ${name} then
          {
            ${name} =
              let
                fn = attrs.${name};
              in
              if isFunction fn then fn scopes.${scopeKey} else fn;
          }
        else
          { };
    in
    resolve "commands" "buildHost"
    // resolve "libraries" "hostTarget"
    // resolve "propagatedCommands" "buildHost"
    // resolve "propagatedLibraries" "hostTarget"
    // resolve "depsBuildBuild" "buildBuild"
    // resolve "depsBuildTarget" "buildTarget"
    // resolve "depsHostHost" "hostHost"
    // resolve "depsTargetTarget" "targetTarget";

  makeDerivationExtensible =
    rattrs:
    let
      # rawArgs is the fixpoint: rattrs receives finalAttrs (with resolved deps)
      # but returns the user's attrs (with raw functions).
      rawArgs = rattrs (rawArgs // resolveScoped rawArgs // { inherit finalPackage overrideAttrs; });

      # What mkDerivationSimple receives — raw function forms for dep attrs.
      args = rawArgs;

      overrideAttrs =
        f0:
        makeDerivationExtensible (
          final:
          let
            prev = rattrs final;
            thisOverlay =
              if isFunction f0 then
                let
                  fPrev = f0 prev;
                in
                if isFunction fPrev then f0 final prev else fPrev
              else
                f0;
          in
          (
            if
              prev ? src
              && thisOverlay ? version
              && prev ? version
              && !(thisOverlay ? src)
              && !(thisOverlay.__intentionallyOverridingVersion or false)
            then
              warn (
                let
                  pos = unsafeGetAttrPos "version" thisOverlay;
                in
                ''
                  ${
                    args.name or "${args.pname or "<unknown name>"}-${args.version or "<unknown version>"}"
                  } was overridden with `version` but not `src` at ${pos.file or "<unknown file>"}:${
                    toString pos.line or "<unknown line>"
                  }:${toString pos.column or "<unknown column>"}.
                ''
              )
            else
              x: x
          )
            (prev // (removeAttrs thisOverlay [ "__intentionallyOverridingVersion" ]))
        );

      finalPackage = mkDerivationSimple overrideAttrs args;
    in
    finalPackage;

  mkDerivationSimple =
    overrideAttrs:
    {
      # Scope-based dependency attributes (EEP 0041)
      commands ? _: { },
      libraries ? _: { },
      propagatedCommands ? _: { },
      propagatedLibraries ? _: { },
      depsBuildBuild ? _: { },
      depsBuildTarget ? _: { },
      depsHostHost ? _: { },
      depsTargetTarget ? _: { },

      # CC attribute — per-package compiler selection
      cc ? "__default__",

      # Standard mkDerivation attributes
      configureFlags ? [ ],
      configurePlatforms ? defaultConfigurePlatforms,
      doCheck ? doCheckByDefault,
      doInstallCheck ? doCheckByDefault,
      strictDeps ? defaultStrictDeps,
      enableParallelBuilding ? enableParallelBuildingByDefault,
      separateDebugInfo ? false,
      outputs ? [ "out" ],
      hardeningEnable ? [ ],
      hardeningDisable ? [ ],
      patches ? [ ],
      __contentAddressed ? (!attrs ? outputHash) && contentAddressedByDefault,
      __structuredAttrs ? structuredAttrsByDefault,

      cmakeFlags ? [ ],
      mesonFlags ? [ ],
      meta ? { },
      passthru ? { },
      pos ? (
        if attrs.meta.description or null != null then
          unsafeGetAttrPos "description" attrs.meta
        else if attrs.version or null != null then
          unsafeGetAttrPos "version" attrs
        else
          unsafeGetAttrPos "name" attrs
      ),
      env ? { },

      ...
    }@attrs:
    let
      # Resolve the CC
      # Note: `cc` here is attrs.cc (the per-package override), while
      # `defaultCC` is the module-level default compiler (stdenv.cc).
      resolvedCC =
        if cc == "__default__" then
          defaultCC
        else if cc == null then
          null
        else if isFunction cc then
          cc scopes.buildHost
        else
          cc;

      actualCC = resolvedCC;

      hasCC = actualCC != null;

      defaultHardeningFlags =
        if hasCC then actualCC.defaultHardeningFlags or knownHardeningFlags else [ ];

      # Flatten scope-based dependencies
      commandsAttrs = commands scopes.buildHost;
      # Merge CC into commands (CC takes lowest priority — user commands win)
      mergedCommandsAttrs = (if hasCC then { cc = actualCC; } else { }) // commandsAttrs;
      flatCommands =
        map getDev (attrValues (filterAttrs (_: v: v != null) mergedCommandsAttrs))
        ++ optional separateDebugInfo' ../../build-support/setup-hooks/separate-debug-info.sh
        ++ optional isWindows ../../build-support/setup-hooks/win-dll-link.sh;

      librariesAttrs = libraries scopes.hostTarget;
      flatLibraries = map getDev (attrValues (filterAttrs (_: v: v != null) librariesAttrs));

      propagatedCommandsAttrs = propagatedCommands scopes.buildHost;
      flatPropagatedCommands = map getDev (
        attrValues (filterAttrs (_: v: v != null) propagatedCommandsAttrs)
      );

      propagatedLibrariesAttrs = propagatedLibraries scopes.hostTarget;
      flatPropagatedLibraries = map getDev (
        attrValues (filterAttrs (_: v: v != null) propagatedLibrariesAttrs)
      );

      flatDepsBuildBuild = flattenDeps scopes.buildBuild depsBuildBuild;
      flatDepsBuildTarget = flattenDeps scopes.buildTarget depsBuildTarget;
      flatDepsHostHost = flattenDeps scopes.hostHost depsHostHost;
      flatDepsTargetTarget = flattenDeps scopes.targetTarget depsTargetTarget;

      doCheck' = doCheck && canExecuteHostOnBuild;
      doInstallCheck' = doInstallCheck && canExecuteHostOnBuild;

      separateDebugInfo' = separateDebugInfo && isLinux;
      outputs' = if separateDebugInfo' then outputs ++ [ "debug" ] else outputs;

      attrsToRemove = [
        "commands"
        "libraries"
        "propagatedCommands"
        "propagatedLibraries"
        "depsBuildBuild"
        "depsBuildTarget"
        "depsHostHost"
        "depsTargetTarget"
        "cc"
        "meta"
        "passthru"
        "pos"
        "env"
        "cmakeFlags"
        "mesonFlags"
        "configureFlags"
        "configurePlatforms"
        "doCheck"
        "doInstallCheck"
        "strictDeps"
        "enableParallelBuilding"
        "separateDebugInfo"
        "outputs"
        "hardeningEnable"
        "hardeningDisable"
        "patches"
        "__contentAddressed"
        "__structuredAttrs"
      ];

      derivationArg = removeAttrs attrs attrsToRemove // {
        ${if (attrs ? name || (attrs ? pname && attrs ? version)) then "name" else null} =
          let
            hostSuffix = optionalString (hostSuffixNecessary && (!(attrs ? outputHash))) stdenvHostSuffix;
            staticMarker = stdenvStaticMarker;
          in
          sanitizeDerivationName (
            if attrs ? name then
              attrs.name + hostSuffix
            else
              assert
                (attrs ? version && attrs.version != null) || throw "The `version` attribute cannot be null.";
              "${attrs.pname}${staticMarker}${hostSuffix}-${attrs.version}"
          );

        builder = attrs.realBuilder or stdenvShell;
        args =
          attrs.args or (
            if attrs ? builder then
              [
                "-e"
                ./source-stdenv.sh
                attrs.builder
              ]
            else
              defaultBuilderArgs
          );
        inherit stdenv;
        system = buildPlatformSystem;
        inherit userHook;
        __ignoreNulls = true;
        inherit __structuredAttrs strictDeps;

        # Map scope-based deps to the standard derivation dependency slots
        depsBuildBuild = flatDepsBuildBuild;
        nativeBuildInputs = flatCommands;
        depsBuildTarget = flatDepsBuildTarget;
        depsHostHost = flatDepsHostHost;
        buildInputs = flatLibraries;
        depsTargetTarget = flatDepsTargetTarget;

        depsBuildBuildPropagated = [ ];
        propagatedNativeBuildInputs = flatPropagatedCommands;
        depsBuildTargetPropagated = [ ];
        depsHostHostPropagated = [ ];
        propagatedBuildInputs = flatPropagatedLibraries;
        depsTargetTargetPropagated = [ ];

        configureFlags =
          configureFlags
          ++ (
            if configurePlatforms == defaultConfigurePlatforms then
              defaultConfigurePlatformsFlags
            else
              optional (lib.elem "build" configurePlatforms) buildPlatformConfigureFlag
              ++ optional (lib.elem "host" configurePlatforms) hostPlatformConfigureFlag
              ++ optional (lib.elem "target" configurePlatforms) targetPlatformConfigureFlag
          );

        inherit patches;

        doCheck = doCheck';
        doInstallCheck = doInstallCheck';
        outputs = outputs';

        ${if __contentAddressed then "__contentAddressed" else null} = __contentAddressed;
        ${if __contentAddressed then "outputHashAlgo" else null} = attrs.outputHashAlgo or "sha256";
        ${if __contentAddressed then "outputHashMode" else null} = attrs.outputHashMode or "recursive";

        ${if enableParallelBuilding then "enableParallelBuilding" else null} = enableParallelBuilding;
        ${if enableParallelBuilding then "enableParallelChecking" else null} =
          attrs.enableParallelChecking or true;
        ${if enableParallelBuilding then "enableParallelInstalling" else null} =
          attrs.enableParallelInstalling or true;

        ${
          if (hardeningDisable != [ ] || hardeningEnable != [ ] || isMusl) then
            "NIX_HARDENING_ENABLE"
          else
            null
        } =
          lib.concatStringsSep " " (
            if lib.elem "all" hardeningDisable then
              [ ]
            else
              filter (
                flag:
                !(lib.elem flag hardeningDisable)
                && (flag == "fortify3" -> !lib.elem "fortify" hardeningDisable)
                && (flag == "strictflexarrays3" -> !lib.elem "strictflexarrays1" hardeningDisable)
                && (flag == "libcxxhardeningextensive" -> !lib.elem "libcxxhardeningfast" hardeningDisable)
              ) (defaultHardeningFlags ++ hardeningEnable)
          );

        ${if requiredSystemFeaturesShouldBeSet then "requiredSystemFeatures" else null} =
          attrs.requiredSystemFeatures or [ ] ++ gccArchFeature;

        # Darwin-specific
        ${if buildIsDarwin then "__darwinAllowLocalNetworking" else null} =
          attrs.__darwinAllowLocalNetworking or false;
        ${if buildIsDarwin then "__sandboxProfile" else null} =
          let
            allDeps = concatLists [
              flatDepsBuildBuild
              flatCommands
              flatDepsBuildTarget
              flatDepsHostHost
              flatLibraries
              flatDepsTargetTarget
            ];
            allPropDeps = concatLists [
              flatPropagatedCommands
              flatPropagatedLibraries
            ];
            computedSandboxProfile = lib.concatMap (input: input.__propagatedSandboxProfile or [ ]) (
              extraNativeBuildInputs ++ extraBuildInputs ++ allDeps
            );
            computedPropagatedSandboxProfile = lib.concatMap (
              input: input.__propagatedSandboxProfile or [ ]
            ) allPropDeps;
            profiles = [
              extraSandboxProfile
            ]
            ++ computedSandboxProfile
            ++ computedPropagatedSandboxProfile
            ++ [
              (attrs.propagatedSandboxProfile or "")
              (attrs.sandboxProfile or "")
            ];
          in
          lib.concatStringsSep "\n" (filter (x: x != "") (lib.unique profiles));
        ${if buildIsDarwin then "__impureHostDeps" else null} =
          let
            allDeps = concatLists [
              flatDepsBuildBuild
              flatCommands
              flatDepsBuildTarget
              flatDepsHostHost
              flatLibraries
              flatDepsTargetTarget
            ];
            allPropDeps = concatLists [
              flatPropagatedCommands
              flatPropagatedLibraries
            ];
          in
          lib.unique (
            lib.concatMap (input: input.__propagatedImpureHostDeps or [ ]) (
              extraNativeBuildInputs ++ extraBuildInputs ++ allDeps
            )
          )
          ++ lib.unique (lib.concatMap (input: input.__propagatedImpureHostDeps or [ ]) allPropDeps)
          ++ (attrs.__propagatedImpureHostDeps or [ ])
          ++ (attrs.__impureHostDeps or [ ])
          ++ __extraImpureHostDeps
          ++ [
            "/dev/zero"
            "/dev/random"
            "/dev/urandom"
            "/bin/sh"
          ];

        # Windows/Cygwin
        ${if isWindows || isCygwin then "allowedImpureDLLs" else null} =
          (attrs.allowedImpureDLLs or [ ]) ++ optionals isCygwin [ "KERNEL32.dll" ];

        # Structured attrs output checks
        ${if __structuredAttrs then "outputChecks" else null} =
          let
            attrsOutputChecks = makeOutputChecks attrs;
            attrsOutputChecksFiltered = filterAttrs (_: v: v != null) attrsOutputChecks;
          in
          if
            !attrs ? outputs
            && !attrs ? outputChecks
            && (attrsOutputChecks == { } || attrsOutputChecksFiltered == { })
          then
            if separateDebugInfo' then
              {
                out = { };
                debug = { };
              }
            else
              { out = { }; }
          else
            lib.listToAttrs (
              map (name: {
                inherit name;
                value =
                  let
                    raw = lib.zipAttrsWith (_: concatLists) [
                      attrsOutputChecksFiltered
                      (makeOutputChecks (attrs.outputChecks.${name} or { }))
                    ];
                  in
                  if separateDebugInfo' && name == "debug" then
                    removeAttrs raw [
                      "allowedReferences"
                      "allowedRequisites"
                      "disallowedReferences"
                      "disallowedRequisites"
                    ]
                  else
                    raw;
              }) outputs'
            );

        # Non-structured attrs output checks
        ${if !__structuredAttrs && attrs ? disallowedReferences then "disallowedReferences" else null} =
          map unsafeDerivationToUntrackedOutpath attrs.disallowedReferences;
        ${if !__structuredAttrs && attrs ? disallowedRequisites then "disallowedRequisites" else null} =
          map unsafeDerivationToUntrackedOutpath attrs.disallowedRequisites;
        ${if !__structuredAttrs && attrs ? allowedReferences then "allowedReferences" else null} =
          mapNullable unsafeDerivationToUntrackedOutpath attrs.allowedReferences;
        ${if !__structuredAttrs && attrs ? allowedRequisites then "allowedRequisites" else null} =
          mapNullable unsafeDerivationToUntrackedOutpath attrs.allowedRequisites;

        cmakeFlags = makeCMakeFlags attrs;
        mesonFlags = makeMesonFlags attrs;
      };

      env' =
        if attrs ? meta.mainProgram then env // { NIX_MAIN_PROGRAM = attrs.meta.mainProgram; } else env;

      checkedEnv =
        let
          overlappingArgs = intersectAttrs env' derivationArg;
        in
        assert
          (isAttrs env && !isDerivation env)
          || throw "`env` must be an attribute set of environment variables.";
        assert
          (overlappingArgs == { })
          || throw (
            let
              errors = lib.concatMapStringsSep "\n" (
                name:
                "  - ${name}: in `env`: ${toPretty { } env'.${name}}; in derivation arguments: ${
                    toPretty { } derivationArg.${name}
                  }"
              ) (lib.attrNames overlappingArgs);
            in
            "The `env` attribute set cannot contain any attributes passed to derivation. The following attributes are overlapping:\n${errors}"
          );
        mapAttrs (
          n: v:
          assert
            (isString v || isBool v || isInt v || isDerivation v)
            || throw "The `env` attribute set can only contain derivation, string, boolean or integer attributes. The `${n}` attribute is of type ${typeOf v}.";
          v
        ) env';

      validity = assertValidity { inherit meta attrs; };

      meta = commonMeta {
        inherit validity attrs pos;
        references = flatCommands ++ flatLibraries ++ flatPropagatedCommands ++ flatPropagatedLibraries;
      };

      # Expose the commands/libraries attrsets on finalPackage for introspection
      # and for use in build phases via finalAttrs.commands.foo
      commandsPassthru = {
        inherit commandsAttrs librariesAttrs;
      };

      attrsToRemoveLast = [
        "outputHashAlgo"
        "outputHash"
        "outputHashMode"
        "allowedReferences"
        "allowedRequisites"
        "disallowedReferences"
        "disallowedRequisites"
        "outputChecks"
      ];

    in
    extendDerivation validity.handled (
      {
        inputDerivation = derivation (
          removeAttrs derivationArg attrsToRemoveLast
          // {
            name = "inputDerivation" + optionalString (derivationArg ? name) "-${derivationArg.name}";
            outputs = [ "out" ];
            requiredSystemFeatures = [ ];
            _derivation_original_builder = derivationArg.builder;
            _derivation_original_args = derivationArg.args;
            builder = stdenvShell;
            args = [
              "-c"
              ''
                out="${builtins.placeholder "out"}"
                if [ -e "$NIX_ATTRS_SH_FILE" ]; then . "$NIX_ATTRS_SH_FILE"; fi
                declare -p > $out
                for var in $passAsFile; do
                    pathVar="''${var}Path"
                    printf "%s" "$(< "''${!pathVar}")" >> $out
                done
              ''
            ];
          }
        );

        inherit passthru overrideAttrs;
        inherit meta;
        # Expose dependency attrsets for introspection
        commands = mergedCommandsAttrs;
        libraries = librariesAttrs;
      }
      // passthru
    ) (derivation (derivationArg // checkedEnv));
in
{
  inherit mkEkaPackage;
}
