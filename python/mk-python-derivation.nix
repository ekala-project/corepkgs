# Generic builder.

{
  lib,
  config,
  python,
  # Allow passing in a custom stdenv to buildPython*.override
  stdenv,
  wrapPython,
  unzip,
  ensureNewerSourcesForZipFilesHook,
  # Whether the derivation provides a Python module or not.
  toPythonModule,
  namePrefix,
  nix-update-script,
  pypaBuildHook,
  pypaInstallHook,
  pythonCatchConflictsHook,
  pythonImportsCheckHook,
  pythonNamespacesHook,
  pythonOutputDistHook,
  pythonOutputTestSrcHook,
  pythonRelaxDepsHook,
  pythonRemoveBinBytecodeHook,
  pythonRemoveTestsDirHook,
  pythonRuntimeDepsCheckHook,
  setuptoolsBuildHook,
  wheelUnpackHook,
  eggUnpackHook,
  eggBuildHook,
  eggInstallHook,
}:

let
  inherit (builtins) unsafeGetAttrPos;
  inherit (lib)
    elem
    extendDerivation
    fixedWidthString
    flip
    getName
    hasSuffix
    head
    isBool
    max
    optional
    optionalAttrs
    optionals
    optionalString
    removePrefix
    splitString
    stringLength
    ;

  getOptionalAttrs =
    names: attrs: lib.getAttrs (lib.intersectLists names (lib.attrNames attrs)) attrs;

  leftPadName =
    name: against:
    let
      len = max (stringLength name) (stringLength against);
    in
    fixedWidthString len " " name;

  isPythonModule =
    drv:
    # all pythonModules have the pythonModule attribute
    (drv ? "pythonModule")
    # Some pythonModules are turned in to a pythonApplication by setting the field to false
    && (!isBool drv.pythonModule);

  isMismatchedPython = drv: drv.pythonModule != python;

  withDistOutput' = flip elem [
    "pyproject"
    "setuptools"
    "wheel"
  ];

  isBootstrapInstallPackage' = flip elem [
    "flit-core"
    "installer"
  ];

  isBootstrapPackage' = flip elem (
    [
      "build"
      "packaging"
      "pyproject-hooks"
      "wheel"
    ]
    ++ optionals (python.pythonOlder "3.11") [
      "tomli"
    ]
  );

  isSetuptoolsDependency' = flip elem [
    "setuptools"
    "wheel"
  ];

  cleanAttrs = flip removeAttrs [
    "disabled"
    "checkPhase"
    "checkInputs"
    "nativeCheckInputs"
    "doCheck"
    "doInstallCheck"
    "pyproject"
    "format"
    "stdenv"
    "dependencies"
    "optional-dependencies"
    "build-system"
  ];

  # Python-specific attrs that should be visible to the user's `finalAttrs`
  # fixed-point view but stripped from the underlying mkDerivation call so they
  # are not forwarded to the `derivation` builtin (which cannot coerce attrsets
  # like `optional-dependencies` to strings).
  pythonOnlyAttrNames = [
    "dependencies"
    "optional-dependencies"
    "build-system"
  ];

  # Wrap `stdenv.mkDerivation` so that the user's function sees a `finalAttrs`
  # value containing Python-specific attributes (e.g. `optional-dependencies`),
  # while the underlying `mkDerivation` receives a sanitised attrset.
  pythonMkDerivation =
    fn:
    stdenv.mkDerivation (
      drvFinalAttrs:
      let
        # Re-expose the Python-specific attrs that the inner `mkDerivation`
        # doesn't track. These reference the user's own returned attrs, so the
        # fixed-point still terminates as long as the user doesn't define them
        # in terms of `finalAttrs.<pythonOnlyAttr>` itself.
        userFinalAttrs = drvFinalAttrs // {
          dependencies = userAttrs.dependencies or [ ];
          optional-dependencies = userAttrs.optional-dependencies or { };
          build-system = userAttrs.build-system or [ ];
        };
        userAttrs = fn userFinalAttrs;
      in
      removeAttrs userAttrs pythonOnlyAttrNames
    );

in

lib.extendMkDerivation {
  constructDrv = pythonMkDerivation;

  excludeDrvArgNames = [
    "disabled"
    "checkPhase"
    "checkInputs"
    "nativeCheckInputs"
    "doCheck"
    "doInstallCheck"
    "pyproject"
    "format"
    "stdenv"
    "dependencies"
    "optional-dependencies"
    "build-system"
  ];

  extendDrvArgs =
    finalAttrs:
    {
      # Build-time dependencies for the package
      nativeBuildInputs ? [ ],

      # Run-time dependencies for the package
      buildInputs ? [ ],

      # Dependencies needed for running the checkPhase.
      # These are added to buildInputs when doCheck = true.
      checkInputs ? [ ],
      nativeCheckInputs ? [ ],

      # propagate build dependencies so in case we have A -> B -> C,
      # C can import package A propagated by B
      propagatedBuildInputs ? [ ],

      # Python module dependencies.
      # These are named after PEP-621.
      dependencies ? [ ],
      optional-dependencies ? { },

      # Python PEP-517 build systems.
      build-system ? [ ],

      # DEPRECATED: use propagatedBuildInputs
      pythonPath ? [ ],

      # Enabled to detect some (native)BuildInputs mistakes
      strictDeps ? true,

      outputs ? [ "out" ],

      # Files and/or directories (relative to the source root) to bundle into
      # the `test_src` output. When non-empty, a "test_src" output is created
      # and `passthru.tests.python` is auto-generated to run the package's
      # test suite against the installed package without rebuilding.
      #
      # Typical usage is `testPaths = [ "tests" ];`. Packages whose suites
      # reference sibling files (helper modules, fixture data, README files
      # used by doctests, etc.) should list those alongside the test
      # directory, e.g. `testPaths = [ "tests" "smartypants" "README.rst" ];`.
      #
      # The list is forwarded to the `pythonOutputTestSrcHook` as a
      # whitespace-separated environment variable; entries must therefore
      # not contain whitespace.
      testPaths ? [ ],

      # used to disable derivation, useful for specific python versions
      disabled ? false,

      # Raise an error if two packages are installed with the same name
      # TODO: For cross we probably need a different PYTHONPATH, or not
      # add the runtime deps until after buildPhase.
      catchConflicts ? (python.stdenv.hostPlatform == python.stdenv.buildPlatform),

      # Additional arguments to pass to the makeWrapper function, which wraps
      # generated binaries.
      makeWrapperArgs ? [ ],

      # Skip wrapping of python programs altogether
      dontWrapPythonPrograms ? false,

      # Don't use Pip to install a wheel
      # Note this is actually a variable for the pipInstallPhase in pip's setupHook.
      # It's included here to prevent an infinite recursion.
      dontUsePipInstall ? false,

      # Skip setting the PYTHONNOUSERSITE environment variable in wrapped programs
      permitUserSite ? false,

      # Remove bytecode from bin folder.
      # When a Python script has the extension `.py`, bytecode is generated
      # Typically, executables in bin have no extension, so no bytecode is generated.
      # However, some packages do provide executables with extensions, and thus bytecode is generated.
      removeBinBytecode ? true,

      # pyproject = true <-> format = "pyproject"
      # pyproject = false <-> format = "other"
      # https://github.com/NixOS/nixpkgs/issues/253154
      pyproject ? null,

      # Several package formats are supported.
      # "setuptools" : Install a common setuptools/distutils based package. This builds a wheel.
      # "wheel" : Install from a pre-compiled wheel.
      # "pyproject": Install a package using a ``pyproject.toml`` file (PEP517). This builds a wheel.
      # "egg": Install a package from an egg.
      # "other" : Provide your own buildPhase and installPhase.
      format ? null,

      meta ? { },

      doCheck ? false,

      ...
    }@attrs:
    let
      # The attributes that stdenv.mkDerivation will actually use
      # Keep extra attributes from `attrs`, e.g., `patchPhase', etc.
      getFinalPassthru =
        let
          pos = unsafeGetAttrPos "passthru" finalAttrs;
        in
        attrName:
        finalAttrs.passthru.${attrName} or (throw (
          ''
            ${finalAttrs.name}: passthru.${attrName} missing after overrideAttrs overriding.
          ''
          + optionalString (pos != null) ''
            Last overridden at ${pos.file}:${toString pos.line}
          ''
        ));

      format' =
        assert (getFinalPassthru "pyproject" != null) -> (format == null);
        if getFinalPassthru "pyproject" != null then
          if getFinalPassthru "pyproject" then "pyproject" else "other"
        else if format != null then
          format
        else
          throw "${name} does not configure a `format`. To build with setuptools as before, set `pyproject = true` and `build-system = [ setuptools ]`.`";

      withDistOutput = withDistOutput' format';

      withTestSrcOutput = testPaths != [ ];

      validatePythonMatches =
        let
          throwMismatch =
            attrName: drv:
            let
              myName = "'${finalAttrs.name}'";
              theirName = "'${drv.name}'";
              optionalLocation =
                let
                  pos = unsafeGetAttrPos (if attrs ? "pname" then "pname" else "name") attrs;
                in
                optionalString (pos != null) " at ${pos.file}:${toString pos.line}:${toString pos.column}";
            in
            throw ''
              Python version mismatch in ${myName}:

              The Python derivation ${myName} depends on a Python derivation
              named ${theirName}, but the two derivations use different versions
              of Python:

                  ${leftPadName myName theirName} uses ${python}
                  ${leftPadName theirName myName} uses ${toString drv.pythonModule}

              Possible solutions:

                * If ${theirName} is a Python library, change the reference to ${theirName}
                  in the ${attrName} of ${myName} to use a ${theirName} built from the same
                  version of Python

                * If ${theirName} is used as a tool during the build, move the reference to
                  ${theirName} in ${myName} from ${attrName} to nativeBuildInputs

                * If ${theirName} provides executables that are called at run time, pass its
                  bin path to makeWrapperArgs:

                      makeWrapperArgs = [ "--prefix PATH : ''${lib.makeBinPath [ ${getName drv} ] }" ];

              ${optionalLocation}
            '';

          checkDrv =
            attrName: drv:
            if (isPythonModule drv) && (isMismatchedPython drv) then throwMismatch attrName drv else drv;

        in
        attrName: inputs: map (checkDrv attrName) inputs;

      isBootstrapInstallPackage = isBootstrapInstallPackage' (finalAttrs.pname or null);

      isBootstrapPackage = isBootstrapInstallPackage || isBootstrapPackage' (finalAttrs.pname or null);

      isSetuptoolsDependency = isSetuptoolsDependency' (finalAttrs.pname or null);

      name = namePrefix + attrs.name or "${finalAttrs.pname}-${finalAttrs.version}";

    in
    (cleanAttrs attrs)
    // {
      inherit name;

      inherit catchConflicts;

      nativeBuildInputs = [
        python
        wrapPython
        ensureNewerSourcesForZipFilesHook # move to wheel installer (pip) or builder (setuptools, flit, ...)?
        pythonRemoveTestsDirHook
      ]
      ++ optionals (finalAttrs.catchConflicts && !isBootstrapPackage && !isSetuptoolsDependency) [
        #
        # 1. When building a package that is also part of the bootstrap chain, we
        #    must ignore conflicts after installation, because there will be one with
        #    the package in the bootstrap.
        #
        # 2. When a package is a dependency of setuptools, we must ignore conflicts
        #    because the hook that checks for conflicts uses setuptools.
        #
        pythonCatchConflictsHook
      ]
      ++
        optionals (finalAttrs.pythonRelaxDeps or [ ] != [ ] || finalAttrs.pythonRemoveDeps or [ ] != [ ])
          [
            pythonRelaxDepsHook
          ]
      ++ optionals removeBinBytecode [
        pythonRemoveBinBytecodeHook
      ]
      ++ optionals (hasSuffix "zip" (finalAttrs.src.name or "")) [
        unzip
      ]
      ++ optionals (format' == "setuptools") [
        setuptoolsBuildHook
      ]
      ++ optionals (format' == "pyproject") [
        (
          if isBootstrapPackage then
            pypaBuildHook.override {
              inherit (python.pythonOnBuildForHost.pkgs.bootstrap) build;
              wheel = null;
            }
          else
            pypaBuildHook
        )
        (
          if isBootstrapPackage then
            pythonRuntimeDepsCheckHook.override {
              inherit (python.pythonOnBuildForHost.pkgs.bootstrap) packaging;
            }
          else
            pythonRuntimeDepsCheckHook
        )
      ]
      ++ optionals (format' == "wheel") [
        wheelUnpackHook
      ]
      ++ optionals (format' == "egg") [
        eggUnpackHook
        eggBuildHook
        eggInstallHook
      ]
      ++ optionals (format' != "other") [
        (
          if isBootstrapInstallPackage then
            pypaInstallHook.override {
              inherit (python.pythonOnBuildForHost.pkgs.bootstrap) installer;
            }
          else
            pypaInstallHook
        )
      ]
      ++ optionals (stdenv.buildPlatform == stdenv.hostPlatform) [
        # This is a test, however, it should be ran independent of the checkPhase and checkInputs
        pythonImportsCheckHook
      ]
      ++ optionals (python.pythonAtLeast "3.3") [
        # Optionally enforce PEP420 for python3
        pythonNamespacesHook
      ]
      ++ optionals withDistOutput [
        pythonOutputDistHook
      ]
      ++ optionals withTestSrcOutput [
        pythonOutputTestSrcHook
      ]
      ++ nativeBuildInputs
      ++ getFinalPassthru "build-system";

      buildInputs = validatePythonMatches "buildInputs" (buildInputs ++ pythonPath);

      propagatedBuildInputs = validatePythonMatches "propagatedBuildInputs" (
        propagatedBuildInputs
        ++ getFinalPassthru "dependencies"
        ++ [
          # we propagate python even for packages transformed with 'toPythonApplication'
          # this pollutes the PATH but avoids rebuilds
          # see https://github.com/NixOS/nixpkgs/issues/170887 for more context
          python
        ]
      );

      inherit strictDeps;

      LANG = "${if python.stdenv.hostPlatform.isDarwin then "en_US" else "C"}.UTF-8";

      # Python packages don't have a checkPhase, only an installCheckPhase
      doCheck = false;
      doInstallCheck = doCheck;
      nativeInstallCheckInputs = nativeCheckInputs ++ attrs.nativeInstallCheckInputs or [ ];
      installCheckInputs = checkInputs ++ attrs.installCheckInputs or [ ];

      inherit dontWrapPythonPrograms;

      postFixup =
        optionalString (!finalAttrs.dontWrapPythonPrograms) ''
          wrapPythonPrograms
        ''
        + attrs.postFixup or "";

      # Python packages built through cross-compilation are always for the host platform.
      disallowedReferences = optionals (python.stdenv.hostPlatform != python.stdenv.buildPlatform) [
        python.pythonOnBuildForHost
      ];

      outputs = outputs ++ optional withDistOutput "dist" ++ optional withTestSrcOutput "test_src";
    }
    // {
      # Re-expose Python-specific attrs at the top-level of the returned
      # attrset so that they're visible in the user's `finalAttrs` fixed-point
      # view (see `pythonMkDerivation`). These are removed before being passed
      # to `stdenv.mkDerivation`, so they never reach the `derivation` builtin.
      inherit dependencies optional-dependencies build-system;
      ${if withTestSrcOutput then "testPaths" else null} = testPaths;
    }
    // {
      passthru =
        let
          userPassthru = attrs.passthru or { };
          # Forward test-related hooks from the parent derivation so that
          # patchShebangs, environment setup, fixture preparation, etc. all
          # apply in the auto-generated test derivation as well.
          forwardedTestHookNames = [
            "preCheck"
            "postCheck"
            "preInstallCheck"
            "postInstallCheck"
            "disabledTests"
            "disabledTestPaths"
            "enabledTestPaths"
            "pytestFlags"
            "pytestFlagsArray"
            "unittestFlagsArray"
            "PYTEST_DISABLE_PLUGIN_AUTOLOAD"
          ];
          forwardedTestHooks = lib.filterAttrs (n: _: attrs ? ${n}) (
            lib.genAttrs forwardedTestHookNames (n: attrs.${n} or null)
          );
          autoTests = optionalAttrs withTestSrcOutput {
            python = stdenv.mkDerivation (
              {
                name = "${name}-tests";
                src = finalAttrs.finalPackage.test_src;
                dontConfigure = true;
                dontBuild = true;
                # We still produce an empty `$out` because some preDist hooks
                # (e.g. pytest's `pytestcachePhase`) expect it to exist.
                installPhase = "mkdir -p $out";
                # Python check hooks (pytestCheckHook, unittestCheckHook, ...)
                # append themselves to preDistPhases, which runs after the
                # installCheckPhase. We enable both doCheck and doInstallCheck
                # so that any user-provided checkPhase / installCheckPhase
                # forwarded below also executes.
                doCheck = true;
                doInstallCheck = true;
                nativeBuildInputs = [
                  python
                  finalAttrs.finalPackage
                ]
                ++ nativeCheckInputs;
                buildInputs = checkInputs;
              }
              // forwardedTestHooks
              // {
                ${if (attrs ? checkPhase) then "installCheckPhase" else null} =
                  # Mirror the parent's handling: a user-supplied checkPhase is
                  # really an installCheckPhase in Python land.
                  attrs.checkPhase;
                ${if (attrs ? installCheckPhase) then "installCheckPhase" else null} = attrs.installCheckPhase;
              }
            );
          };
        in
        {
          inherit
            disabled
            pyproject
            build-system
            dependencies
            optional-dependencies
            ;
          updateScript = nix-update-script { };
          tests = autoTests // (userPassthru.tests or { });
        }
        // removeAttrs userPassthru [ "tests" ];

      meta = {
        # default to python's platforms
        platforms = python.meta.platforms;
        isBuildPythonPackage = python.meta.platforms;
      }
      // meta;
      # If given use the specified checkPhase, otherwise use the setup hook.
      # Longer-term we should get rid of `checkPhase` and use `installCheckPhase`.
      ${if (attrs ? checkPhase) then "installCheckPhase" else null} = attrs.checkPhase;
    }
    //
      lib.mapAttrs
        (
          name: value:
          lib.throwIf (
            attrs.${name} == [ ]
          ) "${lib.getName finalAttrs}: ${name} must be unspecified, null or a non-empty list." attrs.${name}
        )
        (
          getOptionalAttrs [
            "enabledTestMarks"
            "enabledTestPaths"
            "enabledTests"
          ] attrs
        );

  # This derivation transformation function must be independent to `attrs`
  # for fixed-point arguments support in the future.
  transformDrv =
    let
      # Workaround to make the `lib.extendDerivation`-based disabled functionality
      # respect `<pkg>.overrideAttrs`
      # It doesn't cover `<pkg>.<output>.overrideAttrs`.
      disablePythonPackage =
        drv:
        extendDerivation (
          drv.disabled
          -> throw "${removePrefix namePrefix drv.name} not supported for interpreter ${python.executable}"
        ) { } drv
        // {
          overrideAttrs = fdrv: disablePythonPackage (drv.overrideAttrs fdrv);
        };
    in
    drv: disablePythonPackage (toPythonModule drv);
}
