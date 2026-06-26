# This expression takes a file like `hackage-packages.nix` and constructs
# a full package set out of that.
#
# Ported from nixpkgs pkgs/development/haskell-modules/make-package-set.nix
# Stripped: MicroHS, gnome2 scope injection.

{
  # package-set used for build tools (all of pkgs)
  buildPackages,

  # A haskell package set for Setup.hs, compiler plugins, and similar
  # build-time uses.
  buildHaskellPackages,

  # package-set used for non-haskell dependencies (all of pkgs)
  pkgs,

  # stdenv provides our build and host platforms
  stdenv,

  # this module provides the list of known licenses and maintainers
  lib,

  # needed for overrideCabal & packageSourceOverrides
  haskellLib,

  # hashes for downloading Hackage packages
  all-cabal-hashes ? null,

  # compiler to use
  ghc,

  # A function that takes `{ pkgs, lib, callPackage }` as the first arg and
  # `self` as second, and returns a set of haskell packages
  package-set,

  # The final, fully overridden package set usable with the nixpkgs fixpoint
  # overriding functionality
  extensible-self,
}:

# return value: a function from self to the package set
self:

let
  inherit (stdenv) buildPlatform hostPlatform;

  inherit (lib) fix' extends makeOverridable;
  inherit (haskellLib.compose) overrideCabal;

  mkDerivationImpl = pkgs.callPackage ./generic-builder.nix ({
    inherit stdenv;
    inherit (self)
      buildHaskellPackages
      ghc
      ;
    jailbreak-cabal = self.buildHaskellPackages.jailbreak-cabal or null;
    inherit haskellLib;
    inherit (self)
      ghcWithHoogle
      ghcWithPackages
      ;
    hscolour =
      let
        pkg = self.buildHaskellPackages.hscolour or null;
      in
      if pkg != null then
        overrideCabal (drv: {
          isLibrary = false;
          doHaddock = false;
          hyperlinkSource = false;
          postFixup = "rm -rf $out/lib $out/share $out/nix-support";
        }) pkg
      else
        null;
    cpphs =
      if (self ? cpphs) && self.cpphs != null then
        overrideCabal
          (drv: {
            isLibrary = false;
            postFixup = "rm -rf $out/lib $out/share $out/nix-support";
          })
          (
            self.cpphs.overrideScope (
              self: super: {
                mkDerivation =
                  drv:
                  super.mkDerivation (
                    drv
                    // {
                      enableSharedExecutables = false;
                      enableSharedLibraries = false;
                      doHaddock = false;
                      useCpphs = false;
                    }
                  );
              }
            )
          )
      else
        null;
  });

  # Wrap mkDerivation to:
  # 1. Default doCheck to false (tests are expensive and cause dependency cycles)
  # 2. Add passthru.tests.unit that rebuilds with doCheck = true
  mkDerivationWithTests =
    args:
    let
      # Default doCheck to false unless explicitly set
      args' = {
        doCheck = false;
      }
      // args;
      baseDrv = mkDerivationImpl args';
      # Create test derivation only if tests weren't explicitly disabled
      # and test dependencies exist
      hasTests =
        (args' ? testHaskellDepends && args'.testHaskellDepends != [ ])
        || (args' ? testDepends && args'.testDepends != [ ]);
      testDrv = mkDerivationImpl (
        args'
        // {
          doCheck = true;
          # Separate doc output is unnecessary for test runs
          doHaddock = false;
        }
      );
    in
    baseDrv
    // {
      passthru = baseDrv.passthru or { } // {
        tests =
          (baseDrv.passthru.tests or { })
          // lib.optionalAttrs hasTests {
            unit = testDrv;
          };
      };
    };

  mkDerivation = makeOverridable mkDerivationWithTests;

  callPackageWithScope =
    scope: fn: manualArgs:
    let
      drv = if lib.isFunction fn then fn else import fn;
      drvFunctionArgs = lib.functionArgs drv;
      auto = builtins.intersectAttrs drvFunctionArgs scope;

      ensureAttrs = v: if builtins.isFunction v then { __functor = _: v; } else v;

      drvScope = {
        __functor =
          _: allArgs:
          ensureAttrs (drv allArgs)
          // {
            inherit scope;
            overrideScope =
              f:
              let
                newScope = mkScope (fix' (extends f scope.__unfix__));
              in
              callPackageWithScope newScope drv manualArgs;
          };
        __functionArgs = drvFunctionArgs;
      };
    in
    lib.makeOverridable drvScope (auto // manualArgs);

  mkScope =
    scope:
    let
      ps = pkgs.__splicedPackages;
      scopeSpliced =
        pkgs.splicePackages {
          pkgsBuildBuild = scope.buildHaskellPackages.buildHaskellPackages;
          pkgsBuildHost = scope.buildHaskellPackages;
          pkgsBuildTarget = { };
          pkgsHostHost = { };
          pkgsHostTarget = scope;
          pkgsTargetTarget = { };
        }
        // {
          # Don't splice these
          inherit (scope) ghc buildHaskellPackages;
        };
    in
    ps // { inherit stdenv; } // scopeSpliced;
  defaultScope = mkScope self;
  callPackage = drv: args: callPackageWithScope defaultScope drv args;

  # Use cabal2nix to create a default.nix for the package sources found at 'src'.
  haskellSrc2nix =
    {
      name,
      src,
      sha256 ? null,
      extraCabal2nixOptions ? "",
    }:
    let
      sha256Arg = if sha256 == null then "--sha256=" else ''--sha256="${sha256}"'';
    in
    buildPackages.runCommand "cabal2nix-${name}"
      {
        nativeBuildInputs = [ buildPackages.cabal2nix-unwrapped ];
        preferLocalBuild = true;
        allowSubstitutes = false;
        env = {
          LANG = "en_US.UTF-8";
        }
        // lib.optionalAttrs (buildPlatform.libc == "glibc") {
          LOCALE_ARCHIVE = "${buildPackages.glibcLocales}/lib/locale/locale-archive";
        };
      }
      ''
        export HOME="$TMP"
        mkdir -p "$out"
        cabal2nix --compiler=${self.ghc.haskellCompilerName} --system=${hostPlatform.config} ${sha256Arg} "${src}" ${extraCabal2nixOptions} > "$out/default.nix"
      '';

  all-cabal-hashes-component =
    name: version:
    assert all-cabal-hashes != null;
    buildPackages.runCommand "all-cabal-hashes-component-${name}-${version}" { } ''
      mkdir -p $out
      if [ -d ${all-cabal-hashes} ]
      then
        cp ${all-cabal-hashes}/${name}/${version}/${name}.json $out
        cp ${all-cabal-hashes}/${name}/${version}/${name}.cabal $out
      else
        tar --wildcards -xzvf ${all-cabal-hashes} \*/${name}/${version}/${name}.{json,cabal}
        mv */${name}/${version}/${name}.{json,cabal} $out
      fi
    '';

  hackage2nix =
    name: version:
    let
      component = all-cabal-hashes-component name version;
    in
    self.haskellSrc2nix {
      name = "${name}-${version}";
      sha256 = ''$(sed -e 's/.*"SHA256":"//' -e 's/".*$//' "${component}/${name}.json")'';
      src = "${component}/${name}.cabal";
    };

  callPackageKeepDeriver =
    src: args:
    overrideCabal (orig: {
      passthru = orig.passthru or { } // {
        cabal2nixDeriver = src;
      };
    }) (self.callPackage src args);

in
package-set { inherit pkgs lib callPackage; } self
// {

  # Expose pkgs and lib so config.overlays.haskell extensions can use them
  # (e.g. for hackage-packages.nix which takes { pkgs, lib, callPackage })
  inherit pkgs lib;

  inherit
    mkDerivation
    callPackage
    haskellSrc2nix
    hackage2nix
    buildHaskellPackages
    ;

  inherit (haskellLib) packageSourceOverrides;

  callHackage = name: version: callPackageKeepDeriver (self.hackage2nix name version);

  callHackageDirect =
    {
      pkg,
      ver,
      sha256,
      candidate ? false,
      rev ? {
        revision = null;
        sha256 = null;
      },
    }:
    args:
    let
      pkgver = "${pkg}-${ver}";
      firstRevision = self.callCabal2nix pkg (pkgs.fetchzip {
        url =
          if candidate then
            "mirror://hackage/${pkgver}/candidate/${pkgver}.tar.gz"
          else
            "mirror://hackage/${pkgver}/${pkgver}.tar.gz";
        inherit sha256;
      }) args;
    in
    overrideCabal (orig: {
      revision = rev.revision;
      editedCabalFile = rev.sha256;
    }) firstRevision;

  callCabal2nixWithOptions =
    name: src: opts: args:
    let
      extraCabal2nixOptions = if builtins.isString opts then opts else opts.extraCabal2nixOptions or "";
      srcModifier = opts.srcModifier or null;
      defaultFilter = path: type: lib.hasSuffix ".cabal" path || baseNameOf path == "package.yaml";
      expr = self.haskellSrc2nix {
        inherit name extraCabal2nixOptions;
        src =
          if srcModifier != null then
            srcModifier src
          else if lib.canCleanSource src then
            lib.cleanSourceWith {
              inherit src;
              filter = defaultFilter;
            }
          else
            src;
      };
    in
    overrideCabal (orig: {
      inherit src;
    }) (callPackageKeepDeriver expr args);

  callCabal2nix =
    name: src: args:
    self.callCabal2nixWithOptions name src "" args;

  developPackage =
    {
      root,
      name ? lib.optionalString (builtins.typeOf root == "path") (baseNameOf root),
      source-overrides ? { },
      overrides ? self: super: { },
      modifier ? drv: drv,
      returnShellEnv ? lib.inNixShell,
      withHoogle ? returnShellEnv,
      cabal2nixOptions ? "",
    }:
    let
      drv =
        (extensible-self.extend (
          lib.composeExtensions (self.packageSourceOverrides source-overrides) overrides
        )).callCabal2nixWithOptions
          name
          root
          cabal2nixOptions
          { };
    in
    if returnShellEnv then (modifier drv).envFunc { inherit withHoogle; } else modifier drv;

  ghcWithPackages = buildHaskellPackages.callPackage ./with-packages-wrapper.nix {
    haskellPackages = self;
    inherit (self) hoogleWithPackages;
  };

  hoogleWithPackages = self.callPackage ./hoogle.nix {
    haskellPackages = self;
  };
  hoogleLocal =
    {
      packages ? [ ],
    }:
    lib.warn "hoogleLocal is deprecated, use hoogleWithPackages instead" (
      self.hoogleWithPackages (_: packages)
    );

  ghcWithHoogle = self.ghcWithPackages.override {
    withHoogle = true;
  };

  shellFor =
    {
      packages,
      withHoogle ? false,
      doBenchmark ? false,
      genericBuilderArgsModifier ? (args: args),
      extraDependencies ? p: { },
      ...
    }@args:
    let
      selected = packages self;

      cabalDepsForSelected = map (p: p.getCabalDeps) selected;

      isNotSelected = input: lib.all (p: input.outPath or null != p.outPath) selected;

      zipperCombinedPkgs = vals: lib.concatMap (drvList: lib.filter isNotSelected drvList) vals;

      packageInputs = lib.zipAttrsWith (_name: zipperCombinedPkgs) (
        cabalDepsForSelected ++ [ (extraDependencies self) ]
      );

      genericBuilderArgs = {
        pname = if lib.length selected == 1 then (lib.head selected).name else "packages";
        version = "0";
        license = null;
      }
      // packageInputs
      // lib.optionalAttrs doBenchmark {
        doBenchmark = true;
      };

      pkgWithCombinedDeps = self.mkDerivation (genericBuilderArgsModifier genericBuilderArgs);

      pkgWithCombinedDepsDevDrv = pkgWithCombinedDeps.envFunc { inherit withHoogle; };

      mkDerivationArgs = removeAttrs args [
        "genericBuilderArgsModifier"
        "packages"
        "withHoogle"
        "doBenchmark"
        "extraDependencies"
      ];

    in
    pkgWithCombinedDepsDevDrv.overrideAttrs (
      old:
      mkDerivationArgs
      // {
        nativeBuildInputs = old.nativeBuildInputs ++ mkDerivationArgs.nativeBuildInputs or [ ];
        buildInputs = old.buildInputs ++ mkDerivationArgs.buildInputs or [ ];
      }
    );

  ghc = ghc // {
    withPackages = self.ghcWithPackages;
    withHoogle = self.ghcWithHoogle;
  };

  cabalSdist =
    {
      src,
      name ? if src ? name then "${src.name}-sdist.tar.gz" else "source.tar.gz",
    }:
    pkgs.runCommandLocal name
      {
        inherit src;
        nativeBuildInputs = [
          buildHaskellPackages.cabal-install
        ];
        dontUnpack = false;
      }
      ''
        unpackPhase
        cd "''${sourceRoot:-.}"
        patchPhase
        mkdir out
        HOME=$PWD cabal sdist --output-directory out
        mv out/*.tar.gz $out
      '';

  buildFromCabalSdist =
    pkg:
    haskellLib.overrideCabal
      (_: {
        patches = [ ];
      })
      (
        haskellLib.overrideSrc {
          src = self.cabalSdist { src = pkgs.srcOnly pkg; };
          version = pkg.version;
        } pkg
      );

  generateOptparseApplicativeCompletions = self.callPackage (
    { stdenv }:

    commands: pkg:

    if stdenv.buildPlatform.canExecute stdenv.hostPlatform then
      lib.foldr haskellLib.__generateOptparseApplicativeCompletion pkg commands
    else
      pkg
  ) { };

  forceLlvmCodegenBackend = overrideCabal (drv: {
    configureFlags = drv.configureFlags or [ ] ++ [ "--ghc-option=-fllvm" ];
    buildTools =
      drv.buildTools or [ ]
      ++ [ self.ghc.llvmPackages.llvm ]
      ++ lib.optionals (lib.versionAtLeast self.ghc.version "9.10" || stdenv.hostPlatform.isDarwin) [
        self.ghc.llvmPackages.clang
      ];
  });
}
