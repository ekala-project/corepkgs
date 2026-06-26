# Haskell package override utilities.
# Ported from nixpkgs pkgs/development/haskell-modules/lib/compose.nix
#
# The derivation being overridden is always the last parameter,
# which permits more natural composition of several overrides.
{ pkgs, lib }:

rec {

  /*
    This function takes a file like `hackage-packages.nix` and constructs
    a full package set out of that.
  */
  makePackageSet = import ../make-package-set.nix;

  /*
    The function overrideCabal lets you alter the arguments to the
    mkDerivation function.
  */
  overrideCabal =
    f: drv:
    (drv.override (
      args:
      args
      // {
        mkDerivation = drv: (args.mkDerivation drv).override f;
      }
    ))
    // {
      overrideScope = scope: overrideCabal f (drv.overrideScope scope);
    };

  # : Map Name (Either Path VersionNumber) -> HaskellPackageOverrideSet
  # Given a set whose values are either paths or version strings, produces
  # a package override set (i.e. (self: super: { etc. })) that sets
  # the packages named in the input set to the corresponding versions
  packageSourceOverrides =
    overrides: self: super:
    lib.mapAttrs (
      name: src:
      let
        isPath = x: builtins.substring 0 1 (toString x) == "/";
        generateExprs = if isPath src then self.callCabal2nix else self.callHackage;
      in
      generateExprs name src { }
    ) overrides;

  doCoverage = overrideCabal (drv: {
    doCoverage = true;
  });

  dontCoverage = overrideCabal (drv: {
    doCoverage = false;
  });

  doHaddock = overrideCabal (drv: {
    doHaddock = true;
  });

  dontHaddock = overrideCabal (drv: {
    doHaddock = false;
  });

  doJailbreak = overrideCabal (drv: {
    jailbreak = true;
  });

  dontJailbreak = overrideCabal (drv: {
    jailbreak = false;
  });

  doCheck = overrideCabal (drv: {
    doCheck = true;
  });

  dontCheck = overrideCabal (drv: {
    doCheck = false;
  });

  dontCheckIf = condition: if condition then dontCheck else lib.id;

  doBenchmark = overrideCabal (drv: {
    doBenchmark = true;
  });

  dontBenchmark = overrideCabal (drv: {
    doBenchmark = false;
  });

  doDistribute = overrideCabal (drv: {
    hydraPlatforms = lib.subtractLists (drv.badPlatforms or [ ]) (drv.platforms or lib.platforms.all);
  });

  dontDistribute = overrideCabal (drv: {
    hydraPlatforms = [ ];
  });

  appendConfigureFlag = x: appendConfigureFlags [ x ];
  appendConfigureFlags =
    xs:
    overrideCabal (drv: {
      configureFlags = (drv.configureFlags or [ ]) ++ xs;
    });

  appendBuildFlag =
    x:
    overrideCabal (drv: {
      buildFlags = (drv.buildFlags or [ ]) ++ [ x ];
    });
  appendBuildFlags =
    xs:
    overrideCabal (drv: {
      buildFlags = (drv.buildFlags or [ ]) ++ xs;
    });

  removeConfigureFlag =
    x:
    overrideCabal (drv: {
      configureFlags = lib.remove x (drv.configureFlags or [ ]);
    });

  addBuildTool = x: addBuildTools [ x ];
  addBuildTools =
    xs:
    overrideCabal (drv: {
      buildTools = (drv.buildTools or [ ]) ++ xs;
    });

  addExtraLibrary = x: addExtraLibraries [ x ];
  addExtraLibraries =
    xs:
    overrideCabal (drv: {
      extraLibraries = (drv.extraLibraries or [ ]) ++ xs;
    });

  addBuildDepend = x: addBuildDepends [ x ];
  addBuildDepends =
    xs:
    overrideCabal (drv: {
      buildDepends = (drv.buildDepends or [ ]) ++ xs;
    });

  addTestToolDepend = x: addTestToolDepends [ x ];
  addTestToolDepends =
    xs:
    overrideCabal (drv: {
      testToolDepends = (drv.testToolDepends or [ ]) ++ xs;
    });

  addPkgconfigDepend = x: addPkgconfigDepends [ x ];
  addPkgconfigDepends =
    xs:
    overrideCabal (drv: {
      pkg-configDepends = (drv.pkg-configDepends or [ ]) ++ xs;
    });

  addSetupDepend = x: addSetupDepends [ x ];
  addSetupDepends =
    xs:
    overrideCabal (drv: {
      setupHaskellDepends = (drv.setupHaskellDepends or [ ]) ++ xs;
    });

  enableCabalFlag = x: drv: appendConfigureFlag "-f${x}" (removeConfigureFlag "-f-${x}" drv);
  disableCabalFlag = x: drv: appendConfigureFlag "-f-${x}" (removeConfigureFlag "-f${x}" drv);

  markBroken = overrideCabal (drv: {
    broken = true;
    hydraPlatforms = [ ];
  });
  unmarkBroken = overrideCabal (drv: {
    broken = false;
  });
  markBrokenVersion =
    version: drv:
    assert drv.version == version;
    markBroken drv;
  markUnbroken = overrideCabal (drv: {
    broken = false;
  });

  disableParallelBuilding = overrideCabal (drv: {
    enableParallelBuilding = false;
  });

  enableLibraryProfiling = overrideCabal (drv: {
    enableLibraryProfiling = true;
  });
  disableLibraryProfiling = overrideCabal (drv: {
    enableLibraryProfiling = false;
  });

  enableExecutableProfiling = overrideCabal (drv: {
    enableExecutableProfiling = true;
  });
  disableExecutableProfiling = overrideCabal (drv: {
    enableExecutableProfiling = false;
  });

  enableSharedExecutables = overrideCabal (drv: {
    enableSharedExecutables = true;
  });
  disableSharedExecutables = overrideCabal (drv: {
    enableSharedExecutables = false;
  });

  enableSharedLibraries = overrideCabal (drv: {
    enableSharedLibraries = true;
  });
  disableSharedLibraries = overrideCabal (drv: {
    enableSharedLibraries = false;
  });

  enableDeadCodeElimination = overrideCabal (drv: {
    enableDeadCodeElimination = true;
  });
  disableDeadCodeElimination = overrideCabal (drv: {
    enableDeadCodeElimination = false;
  });

  enableStaticLibraries = overrideCabal (drv: {
    enableStaticLibraries = true;
  });
  disableStaticLibraries = overrideCabal (drv: {
    enableStaticLibraries = false;
  });

  enableSeparateBinOutput = overrideCabal (drv: {
    enableSeparateBinOutput = true;
  });

  appendPatch = x: appendPatches [ x ];
  appendPatches =
    xs:
    overrideCabal (drv: {
      patches = (drv.patches or [ ]) ++ xs;
    });

  setBuildTargets =
    xs:
    overrideCabal (drv: {
      buildTarget = lib.concatStringsSep " " xs;
    });
  setBuildTarget = x: setBuildTargets [ x ];

  doHyperlinkSource = overrideCabal (drv: {
    hyperlinkSource = true;
  });
  dontHyperlinkSource = overrideCabal (drv: {
    hyperlinkSource = false;
  });

  disableHardening =
    flags:
    overrideCabal (drv: {
      hardeningDisable = flags;
    });

  doStrip = overrideCabal (drv: {
    dontStrip = false;
  });

  dontStrip = overrideCabal (drv: {
    dontStrip = true;
  });

  enableDWARFDebugging =
    drv:
    appendConfigureFlag "--ghc-options=-g --disable-executable-stripping --disable-library-stripping" (
      dontStrip drv
    );

  sdistTarball =
    pkg:
    lib.overrideDerivation pkg (drv: {
      name = "${drv.pname}-source-${drv.version}";
      outputs = [ "out" ];
      buildPhase = "./Setup sdist";
      haddockPhase = ":";
      checkPhase = ":";
      installPhase = "install -D dist/${drv.pname}-*.tar.gz $out/${drv.pname}-${drv.version}.tar.gz";
      fixupPhase = ":";
    });

  documentationTarball =
    pkg:
    lib.overrideDerivation pkg (drv: {
      name = "${drv.name}-docs";
      outputs = [ "out" ];
      buildPhase = ''
        runHook preHaddock
        ./Setup haddock --for-hackage
        runHook postHaddock
      '';
      haddockPhase = ":";
      checkPhase = ":";
      installPhase = ''
        runHook preInstall
        mkdir -p "$out"
        tar --format=ustar \
          -czf "$out/${drv.name}-docs.tar.gz" \
          -C dist/doc/html "${drv.name}-docs"
        runHook postInstall
      '';
    });

  linkWithGold = appendConfigureFlag "--ghc-option=-optl-fuse-ld=gold --ld-option=-fuse-ld=gold --with-ld=ld.gold";

  justStaticExecutables = overrideCabal (drv: {
    enableSharedExecutables = false;
    enableLibraryProfiling = drv.enableExecutableProfiling or false;
    isLibrary = false;
    doHaddock = false;
    postFixup = drv.postFixup or "" + ''

      # Remove every directory which could have links to other store paths.
      rm -rf $out/lib $out/nix-support $out/share/doc
    '';
    disallowGhcReference = true;
  });

  buildFromSdist =
    pkg:
    overrideCabal (drv: {
      src = "${sdistTarball pkg}/${pkg.pname}-${pkg.version}.tar.gz";
      revision = null;
      editedCabalFile = null;
      jailbreak = false;
      patches = [ ];
    }) pkg;

  buildStrictly = pkg: buildFromSdist (failOnAllWarnings pkg);

  disableOptimization = appendConfigureFlag "--disable-optimization";

  failOnAllWarnings = appendConfigureFlag "--ghc-option=-Wall --ghc-option=-Werror";

  checkUnusedPackages =
    {
      ignoreEmptyImports ? false,
      ignoreMainModule ? false,
      ignorePackages ? [ ],
    }:
    drv:
    overrideCabal (_drv: {
      postBuild =
        let
          args = lib.concatStringsSep " " (
            lib.optional ignoreEmptyImports "--ignore-empty-imports"
            ++ lib.optional ignoreMainModule "--ignore-main-module"
            ++ map (pkg: "--ignore-package ${pkg}") ignorePackages
          );
        in
        "${pkgs.haskellPackages.packunused}/bin/packunused" + lib.optionalString (args != "") " ${args}";
    }) (appendConfigureFlag "--ghc-option=-ddump-minimal-imports" drv);

  triggerRebuild =
    i:
    overrideCabal (drv: {
      postUnpack = drv.postUnpack or "" + ''

        # trigger rebuild ${toString i}
      '';
    });

  overrideSrc =
    {
      src,
      version ? null,
    }:
    drv:
    overrideCabal (_: {
      inherit src;
      version = if version == null then drv.version else version;
      editedCabalFile = null;
    }) drv;

  getBuildInputs = p: p.getBuildInputs;

  getHaskellBuildInputs = p: (getBuildInputs p).haskellBuildInputs;

  shellAware = p: if lib.inNixShell then p.env else p;

  packagesFromDirectory =
    { directory, ... }:

    self: super:
    let
      haskellPaths = lib.filter (lib.hasSuffix ".nix") (builtins.attrNames (builtins.readDir directory));

      toKeyVal = file: {
        name = builtins.replaceStrings [ ".nix" ] [ "" ] file;
        value = self.callPackage (directory + "/${file}") { };
      };

    in
    builtins.listToAttrs (map toKeyVal haskellPaths);

  # INTERNAL function for optparse-applicative completions
  __generateOptparseApplicativeCompletion =
    exeName:
    overrideCabal (drv: {
      postInstall = (drv.postInstall or "") + ''
        bashCompDir="''${!outputBin}/share/bash-completion/completions"
        zshCompDir="''${!outputBin}/share/zsh/vendor-completions"
        fishCompDir="''${!outputBin}/share/fish/vendor_completions.d"
        mkdir -p "$bashCompDir" "$zshCompDir" "$fishCompDir"
        "''${!outputBin}/bin/${exeName}" --bash-completion-script "''${!outputBin}/bin/${exeName}" >"$bashCompDir/${exeName}"
        "''${!outputBin}/bin/${exeName}" --zsh-completion-script "''${!outputBin}/bin/${exeName}" >"$zshCompDir/_${exeName}"
        "''${!outputBin}/bin/${exeName}" --fish-completion-script "''${!outputBin}/bin/${exeName}" >"$fishCompDir/${exeName}.fish"

        # Sanity check
        grep -F ${exeName} <$bashCompDir/${exeName} >/dev/null || {
          echo 'Could not find ${exeName} in completion script.'
          exit 1
        }
      '';
    });

  generateOptparseApplicativeCompletions =
    commands: pkg: lib.foldr __generateOptparseApplicativeCompletion pkg commands;

  allowInconsistentDependencies = overrideCabal (drv: {
    allowInconsistentDependencies = true;
  });

  __CabalEagerPkgConfigWorkaround =
    let
      propagatedPlainBuildInputs =
        drvs:
        map (i: i.val) (
          builtins.genericClosure {
            startSet = map (drv: {
              key = drv.outPath;
              val = drv;
            }) drvs;
            operator =
              { val, ... }:
              if !lib.isDerivation val then
                [ ]
              else
                builtins.concatMap (
                  drv:
                  if !lib.isDerivation drv then
                    [ ]
                  else
                    [
                      {
                        key = drv.outPath;
                        val = drv;
                      }
                    ]
                ) (val.buildInputs or [ ] ++ val.propagatedBuildInputs or [ ]);
          }
        );
    in
    overrideCabal (old: {
      benchmarkPkgconfigDepends = propagatedPlainBuildInputs old.benchmarkPkgconfigDepends or [ ];
      executablePkgconfigDepends = propagatedPlainBuildInputs old.executablePkgconfigDepends or [ ];
      libraryPkgconfigDepends = propagatedPlainBuildInputs old.libraryPkgconfigDepends or [ ];
      testPkgconfigDepends = propagatedPlainBuildInputs old.testPkgconfigDepends or [ ];
    });
}
