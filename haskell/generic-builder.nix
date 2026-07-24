# Haskell generic package builder.
# Ported from nixpkgs pkgs/development/haskell-modules/generic-builder.nix
#
# Stripped: GHCjs/emscripten, iserv-proxy cross-compilation, MicroHS.
{
  lib,
  stdenv,
  buildPackages,
  buildHaskellPackages,
  ghc,
  jailbreak-cabal,
  hscolour,
  cpphs,
  runCommandCC,
  ghcWithHoogle,
  ghcWithPackages,
  haskellLib,
}:

let
  isCross = stdenv.buildPlatform != stdenv.hostPlatform;

  # Pass the "wrong" C compiler rather than none at all so packages that just
  # use the C preproccessor still work, see
  # https://github.com/haskell/cabal/issues/6466 for details.
  cc = if stdenv.hasCC then "$CC" else "$CC_FOR_BUILD";

  inherit (buildPackages)
    fetchurl
    removeReferencesTo
    pkg-config
    coreutils
    ;

in

{
  pname,
  dontStrip ? false,
  version,
  revision ? null,
  sha256 ? null,
  src ? fetchurl {
    url = "mirror://hackage/${pname}-${version}.tar.gz";
    inherit sha256;
  },
  sourceRoot ? null,
  setSourceRoot ? null,
  env ? { },
  buildDepends ? [ ],
  setupHaskellDepends ? [ ],
  libraryHaskellDepends ? [ ],
  executableHaskellDepends ? [ ],
  buildTarget ? "",
  buildTools ? [ ],
  libraryToolDepends ? [ ],
  executableToolDepends ? [ ],
  testToolDepends ? [ ],
  benchmarkToolDepends ? [ ],
  configureFlags ? [ ],
  buildFlags ? [ ],
  haddockFlags ? [ ],
  description ? null,
  doCheck ? false,
  doBenchmark ? false,
  doHoogle ? true,
  doHaddockQuickjump ? doHoogle,
  doInstallIntermediates ? false,
  editedCabalFile ? null,
  enableLibraryProfiling ? true,
  enableExecutableProfiling ? false,
  profilingDetail ? "exported-functions",
  enableSharedExecutables ? false,
  enableSharedLibraries ? !stdenv.hostPlatform.isStatic && (ghc.enableShared or false),
  enableDeadCodeElimination ? (!stdenv.hostPlatform.isDarwin),
  enableStaticLibraries ? !stdenv.hostPlatform.isWindows,
  enableHsc2hsViaAsm ? stdenv.hostPlatform.isWindows,
  extraLibraries ? [ ],
  librarySystemDepends ? [ ],
  executableSystemDepends ? [ ],
  libraryFrameworkDepends ? [ ],
  executableFrameworkDepends ? [ ],
  homepage ? "https://hackage.haskell.org/package/${pname}",
  platforms ? lib.platforms.all,
  badPlatforms ? lib.platforms.none,
  hydraPlatforms ? null,
  hyperlinkSource ? true,
  isExecutable ? false,
  isLibrary ? !isExecutable,
  jailbreak ? false,
  license ? null,
  enableParallelBuilding ? true,
  maintainers ? null,
  teams ? null,
  changelog ? null,
  mainProgram ? null,
  doCoverage ? false,
  doHaddock ? !(ghc.isHaLVM or false) && (ghc.hasHaddock or true),
  doHaddockInterfaces ? doHaddock && lib.versionAtLeast ghc.version "9.0.1",
  passthru ? { },
  pkg-configDepends ? [ ],
  libraryPkgconfigDepends ? [ ],
  executablePkgconfigDepends ? [ ],
  testPkgconfigDepends ? [ ],
  benchmarkPkgconfigDepends ? [ ],
  testDepends ? [ ],
  testHaskellDepends ? [ ],
  testSystemDepends ? [ ],
  testFrameworkDepends ? [ ],
  benchmarkDepends ? [ ],
  benchmarkHaskellDepends ? [ ],
  benchmarkSystemDepends ? [ ],
  benchmarkFrameworkDepends ? [ ],
  testTarget ? "",
  testTargets ? lib.strings.splitString " " testTarget,
  testFlags ? [ ],
  broken ? false,
  preCompileBuildDriver ? null,
  postCompileBuildDriver ? null,
  preUnpack ? null,
  postUnpack ? null,
  patches ? null,
  patchPhase ? null,
  prePatch ? "",
  postPatch ? "",
  preConfigure ? null,
  postConfigure ? null,
  preBuild ? null,
  postBuild ? null,
  preHaddock ? null,
  postHaddock ? null,
  installPhase ? null,
  preInstall ? null,
  postInstall ? null,
  checkPhase ? null,
  preCheck ? null,
  postCheck ? null,
  preFixup ? null,
  postFixup ? null,
  shellHook ? "",
  coreSetup ? false,
  useCpphs ? false,
  hardeningDisable ? null,
  enableObjectDeterminism ? lib.versionAtLeast ghc.version "9.12",
  enableSeparateBinOutput ? false,
  enableSeparateDataOutput ? false,
  enableSeparateDocOutput ? doHaddock,
  enableSeparateIntermediatesOutput ? false,
  allowInconsistentDependencies ? false,
  maxBuildCores ? 16,
  enableLibraryForGhci ? false,
  previousIntermediates ? null,
  disallowedRequisites ? [ ],
  disallowGhcReference ? false,
  dontConvertCabalFileToUnix ? false,
  __propagatePkgConfigDepends ? lib.versionAtLeast ghc.version "9.3",
  __onlyPropagateKnownPkgConfigModules ? false,
  __darwinAllowLocalNetworking ? false,
}@args:

assert editedCabalFile != null -> revision != null;

# --enable-static does not work on windows
assert stdenv.hostPlatform.isWindows -> enableStaticLibraries == false;

let

  inherit (lib)
    optional
    optionals
    optionalString
    versionAtLeast
    concatStringsSep
    enableFeature
    optionalAttrs
    ;

  isHaLVM = ghc.isHaLVM or false;

  # GHC used for building Setup.hs
  nativeGhc = buildHaskellPackages.ghc;

  docdir = docoutput: docoutput + "/share/doc/" + pname + "-" + version;

  binDir = if enableSeparateBinOutput then "$bin/bin" else "$out/bin";

  newCabalFileUrl = "mirror://hackage/${pname}-${version}/revision/${revision}.cabal";
  newCabalFile = fetchurl {
    url = newCabalFileUrl;
    sha256 = editedCabalFile;
    name = "${pname}-${version}-r${revision}.cabal";
  };

  defaultSetupHs = builtins.toFile "Setup.hs" ''
    import Distribution.Simple
    main = defaultMain
  '';

  unprettyConf = builtins.toFile "unpretty-cabal-conf.awk" ''
    /^[^ ]+:/ {
      if (started == 1) print ""
      $1=$1
      printf "%s", $0
      started=1
    }

    /^ +/ {
      $1=$1
      printf " %s", $0
    }

    END { print "" }
  '';

  crossCabalFlags = [
    "--with-ghc=${ghcCommand}"
    "--with-ghc-pkg=${ghc.targetPrefix}ghc-pkg"
    "--with-gcc=${cc}"
  ]
  ++ optionals stdenv.hasCC [
    "--with-ld=${stdenv.cc.bintools.targetPrefix}ld"
    "--with-ar=${stdenv.cc.bintools.targetPrefix}ar"
    "--with-hsc2hs=${ghc.targetPrefix}hsc2hs"
    "--with-strip=${stdenv.cc.bintools.targetPrefix}strip"
  ]
  ++ optionals (!isHaLVM) [
    "--hsc2hs-option=--cross-compile"
    (optionalString enableHsc2hsViaAsm "--hsc2hs-option=--via-asm")
  ]
  ++ optional (allPkgconfigDepends != [ ]) "--with-pkg-config=${pkg-config.targetPrefix}pkg-config";

  makeGhcOptions = opts: lib.concatStringsSep " " (map (opt: "--ghc-option=${opt}") opts);

  defaultConfigureFlags = [
    "--verbose"
    "--prefix=$out"
    ("--libdir=\\$prefix/lib/\\$compiler" + lib.optionalString (ghc ? hadrian) "/lib")
    "--libsubdir=\\$abi/\\$libname"
    (optionalString enableSeparateDataOutput "--datadir=$data/share/${ghcNameWithPrefix}")
    (optionalString enableSeparateDocOutput "--docdir=${docdir "$doc"}")
  ]
  ++ optionals stdenv.hasCC [
    "--with-gcc=$CC"
  ]
  ++ [
    "--package-db=$packageConfDir"
    (optionalString (
      enableSharedExecutables && stdenv.hostPlatform.isLinux
    ) "--ghc-option=-optl=-Wl,-rpath=$out/${ghcLibdir}/${pname}-${version}")
    (optionalString (
      enableSharedExecutables && stdenv.hostPlatform.isDarwin
    ) "--ghc-option=-optl=-Wl,-headerpad_max_install_names")
    (optionalString enableParallelBuilding (makeGhcOptions [
      "-j$NIX_BUILD_CORES"
      "+RTS"
      "-A64M"
      "-RTS"
    ]))
    (optionalString useCpphs (
      "--with-cpphs=${cpphs}/bin/cpphs "
      + (makeGhcOptions [
        "-cpp"
        "-pgmP${cpphs}/bin/cpphs"
        "-optP--cpp"
      ])
    ))
    (enableFeature enableLibraryProfiling "library-profiling")
    (optionalString (
      enableExecutableProfiling || enableLibraryProfiling
    ) "--profiling-detail=${profilingDetail}")
    (enableFeature enableExecutableProfiling "profiling")
    (enableFeature enableSharedLibraries "shared")
    (enableFeature doCoverage "coverage")
    (enableFeature enableStaticLibraries "static")
    (enableFeature enableSharedExecutables "executable-dynamic")
    (enableFeature doCheck "tests")
    (enableFeature doBenchmark "benchmarks")
    "--enable-library-vanilla"
    (enableFeature enableLibraryForGhci "library-for-ghci")
    (enableFeature enableDeadCodeElimination "split-sections")
    (enableFeature (!dontStrip) "library-stripping")
    (enableFeature (!dontStrip) "executable-stripping")
  ]
  ++ optionals enableObjectDeterminism [
    "--ghc-option=-fobject-determinism"
  ]
  ++ optionals isCross (
    [
      "--configure-option=--host=${stdenv.hostPlatform.config}"
    ]
    ++ crossCabalFlags
  )
  ++ optionals enableSeparateBinOutput [
    "--bindir=${binDir}"
  ]
  ++ optionals (doHaddockInterfaces && isLibrary) [
    "--ghc-option=-haddock"
  ];

  postPhases = optional doInstallIntermediates "installIntermediatesPhase";

  setupCompileFlags = [
    (optionalString (!coreSetup) "-package-db=$setupPackageConfDir")
    "-threaded"
  ];

  isHaskellPkg = x: x ? isHaskellLibrary;

  allPkgconfigDepends =
    let
      propagateValue =
        drv: lib.isDerivation drv && (__onlyPropagateKnownPkgConfigModules -> drv ? meta.pkgConfigModules);

      propagatePlainBuildInputs =
        drvs:
        map (i: i.val) (
          builtins.genericClosure {
            startSet = map (drv: {
              key = drv.outPath;
              val = drv;
            }) (builtins.filter propagateValue drvs);
            operator =
              { val, ... }:
              builtins.concatMap (
                drv:
                if propagateValue drv then
                  [
                    {
                      key = drv.outPath;
                      val = drv;
                    }
                  ]
                else
                  [ ]
              ) (val.buildInputs or [ ] ++ val.propagatedBuildInputs or [ ]);
          }
        );
    in

    if __propagatePkgConfigDepends then
      propagatePlainBuildInputs allPkgconfigDepends'
    else
      allPkgconfigDepends';
  allPkgconfigDepends' =
    pkg-configDepends
    ++ libraryPkgconfigDepends
    ++ executablePkgconfigDepends
    ++ optionals doCheck testPkgconfigDepends
    ++ optionals doBenchmark benchmarkPkgconfigDepends;

  depsBuildBuild = [
    nativeGhc
  ]
  ++ lib.optionals (!stdenv.hasCC) [ buildPackages.stdenv.cc ];
  collectedToolDepends =
    buildTools
    ++ libraryToolDepends
    ++ executableToolDepends
    ++ optionals doCheck testToolDepends
    ++ optionals doBenchmark benchmarkToolDepends;
  nativeBuildInputs = [
    ghc
    removeReferencesTo
  ]
  ++ optional (allPkgconfigDepends != [ ]) (
    assert pkg-config != null;
    pkg-config
  )
  ++ setupHaskellDepends
  ++ collectedToolDepends;
  propagatedBuildInputs =
    buildDepends ++ libraryHaskellDepends ++ executableHaskellDepends ++ libraryFrameworkDepends;
  otherBuildInputsHaskell =
    optionals doCheck (testDepends ++ testHaskellDepends)
    ++ optionals doBenchmark (benchmarkDepends ++ benchmarkHaskellDepends);
  otherBuildInputsSystem =
    extraLibraries
    ++ librarySystemDepends
    ++ executableSystemDepends
    ++ executableFrameworkDepends
    ++ allPkgconfigDepends
    ++ optionals doCheck (testSystemDepends ++ testFrameworkDepends)
    ++ optionals doBenchmark (benchmarkSystemDepends ++ benchmarkFrameworkDepends);
  otherBuildInputs =
    extraLibraries
    ++ librarySystemDepends
    ++ executableSystemDepends
    ++ executableFrameworkDepends
    ++ allPkgconfigDepends
    ++ optionals doCheck (
      testDepends ++ testHaskellDepends ++ testSystemDepends ++ testFrameworkDepends
    )
    ++ optionals doBenchmark (
      benchmarkDepends ++ benchmarkHaskellDepends ++ benchmarkSystemDepends ++ benchmarkFrameworkDepends
    );

  setupCommand = "./Setup";

  ghcCommand' = "ghc";
  ghcCommand = "${ghc.targetPrefix}${ghcCommand'}";

  ghcNameWithPrefix = "${ghc.targetPrefix}${ghc.haskellCompilerName}";
  mkGhcLibdir =
    ghc:
    "lib/${ghc.targetPrefix}${ghc.haskellCompilerName}" + lib.optionalString (ghc ? hadrian) "/lib";
  ghcLibdir = mkGhcLibdir ghc;

  nativeGhcCommand = "${nativeGhc.targetPrefix}ghc";

  buildPkgDb = thisGhc: packageConfDir: ''
    if [ -d "$p/${mkGhcLibdir thisGhc}/package.conf.d" ] && [ "$p" != "${ghc}" ] && [ "$p" != "${nativeGhc}" ]; then
      cp -f "$p/${mkGhcLibdir thisGhc}/package.conf.d/"*.conf ${packageConfDir}/
      continue
    fi
  '';

  intermediatesDir = "share/haskell/${ghc.version}/${pname}-${version}/dist";

  testWrapperScript = buildPackages.writeShellScript "haskell-generic-builder-test-wrapper.sh" ''
    set -eu

    if [[ -n "''${NIX_GHC_PACKAGE_PATH_FOR_TEST}" ]]; then
      export GHC_PACKAGE_PATH="''${NIX_GHC_PACKAGE_PATH_FOR_TEST}"
    fi

    exec "$@"
  '';

  testTargetsString =
    lib.warnIf (testTarget != "")
      "haskellPackages.mkDerivation: testTarget is deprecated. Use testTargets instead"
      (lib.concatStringsSep " " testTargets);

  env' = {
    LANG = "en_US.UTF-8";
  }
  // env
  // optionalAttrs (lib.versionOlder ghc.version "9.6.5" && stdenv.hasCC && stdenv.cc.isClang) {
    NIX_CFLAGS_COMPILE =
      "-Wno-error=int-conversion"
      + lib.optionalString (env ? NIX_CFLAGS_COMPILE) (" " + env.NIX_CFLAGS_COMPILE);
  };

in
lib.fix (
  drv:

  stdenv.mkDerivation ({
    inherit pname version;

    outputs = [
      "out"
    ]
    ++ (optional enableSeparateDataOutput "data")
    ++ (optional enableSeparateDocOutput "doc")
    ++ (optional enableSeparateBinOutput "bin")
    ++ (optional enableSeparateIntermediatesOutput "intermediates");

    setOutputFlags = false;

    pos = builtins.unsafeGetAttrPos "pname" args;

    prePhases = [ "setupCompilerEnvironmentPhase" ];
    preConfigurePhases = [ "compileBuildDriverPhase" ];
    preInstallPhases = [ "haddockPhase" ];

    inherit src;

    inherit depsBuildBuild nativeBuildInputs;
    buildInputs = otherBuildInputs ++ optionals (!isLibrary) propagatedBuildInputs;
    propagatedBuildInputs = optionals isLibrary propagatedBuildInputs;

    env = {
      ${if (stdenv.buildPlatform.libc == "glibc") then "LOCALE_ARCHIVE" else null} =
        "${buildPackages.glibcLocales}/lib/locale/locale-archive";
    }
    // env';

    prePatch =
      optionalString (editedCabalFile != null) ''
        echo "Replace Cabal file with edited version from ${newCabalFileUrl}."
        cp ${newCabalFile} ${pname}.cabal
      ''
      + prePatch
      + "\n"
      + lib.optionalString (!dontConvertCabalFileToUnix) ''
        sed -i -e 's/\r$//' *.cabal
      '';

    postPatch =
      optionalString jailbreak ''
        echo "Run jailbreak-cabal to lift version restrictions on build inputs."
        ${jailbreak-cabal}/bin/jailbreak-cabal *.cabal
      ''
      + postPatch;

    setupCompilerEnvironmentPhase = ''
      NIX_BUILD_CORES=$(( NIX_BUILD_CORES < ${toString maxBuildCores} ? NIX_BUILD_CORES : ${toString maxBuildCores} ))
      runHook preSetupCompilerEnvironment

      echo "Build with ${ghc}."
      ${optionalString (
        isLibrary && hyperlinkSource && hscolour != null
      ) "export PATH=${hscolour}/bin:$PATH"}

      builddir="$(mktemp -d)"
      setupPackageConfDir="$builddir/setup-package.conf.d"
      mkdir -p $setupPackageConfDir
      packageConfDir="$builddir/package.conf.d"
      mkdir -p $packageConfDir

      setupCompileFlags="${concatStringsSep " " setupCompileFlags}"
      configureFlags="${concatStringsSep " " defaultConfigureFlags} $configureFlags"
    ''
    + ''
      for p in "''${pkgsBuildBuild[@]}" "''${pkgsBuildHost[@]}" "''${pkgsBuildTarget[@]}"; do
        ${buildPkgDb nativeGhc "$setupPackageConfDir"}
      done
      ${nativeGhcCommand}-pkg --package-db="$setupPackageConfDir" recache
    ''
    + ''
      for p in "''${pkgsHostHost[@]}" "''${pkgsHostTarget[@]}"; do
        ${buildPkgDb ghc "$packageConfDir"}
        if [ -d "$p/include" ]; then
          appendToVar configureFlags "--extra-include-dirs=$p/include"
        fi
        if [ -d "$p/lib" ]; then
          appendToVar configureFlags "--extra-lib-dirs=$p/lib"
        fi
        if [[ -d "$p/Library/Frameworks" ]]; then
          appendToVar configureFlags "--extra-framework-dirs=$p/Library/Frameworks"
        fi
    ''
    + ''
      done
    ''
    + (optionalString
      (
        stdenv.hostPlatform.isDarwin
        && (enableSharedLibraries || enableSharedExecutables)
        && !enableSeparateIntermediatesOutput
      )
      ''
        local dynamicLinksDir="$out/lib/links"
        mkdir -p $dynamicLinksDir

        for d in "$packageConfDir/"*; do
          gawk -f ${unprettyConf} "$d" > tmp
          mv tmp "$d"
        done

        for d in $(grep '^dynamic-library-dirs:' "$packageConfDir"/* | cut -d' ' -f2- | tr ' ' '\n' | sort -u); do
          for lib in "$d/"*.{dylib,so}; do
            ln -sf "$lib" "$dynamicLinksDir"
          done
        done
        for f in "$packageConfDir/"*.conf; do
          sed -i "s,dynamic-library-dirs: .*,dynamic-library-dirs: $dynamicLinksDir," "$f"
        done
      ''
    )
    + ''
      ${ghcCommand}-pkg --package-db="$packageConfDir" recache

      runHook postSetupCompilerEnvironment
    '';

    compileBuildDriverPhase = ''
      runHook preCompileBuildDriver

      for i in Setup.hs Setup.lhs ${defaultSetupHs}; do
        test -f $i && break
      done

      echo setupCompileFlags: $setupCompileFlags
      ${nativeGhcCommand} $setupCompileFlags --make -o Setup -odir $builddir -hidir $builddir $i

      runHook postCompileBuildDriver
    '';

    configurePlatforms = [ ];
    inherit configureFlags buildFlags;

    hardeningDisable =
      lib.optionals (args ? hardeningDisable) hardeningDisable
      ++ lib.optional (ghc.isHaLVM or false) "all";

    configurePhase = ''
      runHook preConfigure

      echo configureFlags: $configureFlags
      ${setupCommand} configure $configureFlags 2>&1 | ${coreutils}/bin/tee "$NIX_BUILD_TOP/cabal-configure.log"
      ${lib.optionalString (!allowInconsistentDependencies) ''
        if grep -E -q -z 'Warning:.*depends on multiple versions' "$NIX_BUILD_TOP/cabal-configure.log"; then
          echo >&2 "*** abort because of serious configure-time warning from Cabal"
          exit 1
        fi
      ''}

      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild
    ''
    + lib.optionalString (previousIntermediates != null) ''
      mkdir -p dist;
      rm -r dist/build
      cp -r ${previousIntermediates}/${intermediatesDir}/build dist/build
      find dist/build -exec chmod u+w {} +
      find dist/build -exec touch -d '1970-01-01T00:00:00Z' {} +
    ''
    + ''
      ${setupCommand} build ${buildTarget} $buildFlags
      runHook postBuild
    '';

    inherit doCheck;

    checkPhase = ''
      runHook preCheck
      checkFlagsArray+=(
        "--show-details=streaming"
        "--test-wrapper=${testWrapperScript}"
        ${lib.escapeShellArgs (map (opt: "--test-option=${opt}") testFlags)}
      )
      export NIX_GHC_PACKAGE_PATH_FOR_TEST="''${NIX_GHC_PACKAGE_PATH_FOR_TEST:-$packageConfDir:}"
      ${setupCommand} test ${testTargetsString} $checkFlags ''${checkFlagsArray:+"''${checkFlagsArray[@]}"}
      runHook postCheck
    '';

    haddockPhase = ''
      runHook preHaddock
      ${optionalString (doHaddock && isLibrary) ''
        ${setupCommand} haddock --html \
          ${optionalString doHoogle "--hoogle"} \
          ${optionalString doHaddockQuickjump "--quickjump"} \
          ${optionalString (isLibrary && hyperlinkSource) "--hyperlink-source"} \
          ${optionalString enableParallelBuilding "--haddock-option=-j$NIX_BUILD_CORES"} \
          --haddock-option=--no-tmp-comp-dir \
          ${lib.concatStringsSep " " haddockFlags}
      ''}
      runHook postHaddock
    '';

    installPhase = ''
      runHook preInstall

      ${
        if !isLibrary && buildTarget == "" then
          "${setupCommand} install"
        else if !isLibrary then
          "${setupCommand} copy ${buildTarget}"
        else
          ''
            ${setupCommand} copy ${buildTarget}
            local packageConfDir="$out/${ghcLibdir}/package.conf.d"
            local packageConfFile="$packageConfDir/${pname}-${version}.conf"
            mkdir -p "$packageConfDir"
            ${setupCommand} register --gen-pkg-config=$packageConfFile
            if [ -d "$packageConfFile" ]; then
              mv "$packageConfFile/"* "$packageConfDir"
              rmdir "$packageConfFile"
            fi
            for packageConfFile in "$packageConfDir/"*; do
              local pkgId=$(gawk -f ${unprettyConf} "$packageConfFile" \
                | grep '^id:' | cut -d' ' -f2)
              mv "$packageConfFile" "$packageConfDir/$pkgId.conf"
            done

            # delete confdir if there are no libraries
            find $packageConfDir -maxdepth 0 -empty -delete;
          ''
      }


      ${optionalString doCoverage "mkdir -p $out/share && cp -r dist/hpc $out/share"}

      ${optionalString enableSeparateDocOutput ''
        for x in ${docdir "$doc"}"/html/src/"*.html; do
          remove-references-to -t $out $x
        done
        mkdir -p $doc
      ''}
      ${optionalString enableSeparateDataOutput "mkdir -p $data"}

      runHook postInstall
    '';

    ${if doInstallIntermediates then "installIntermediatesPhase" else null} = ''
      runHook preInstallIntermediates
      intermediatesOutput=${if enableSeparateIntermediatesOutput then "$intermediates" else "$out"}
      installIntermediatesDir="$intermediatesOutput/${intermediatesDir}"
      mkdir -p "$installIntermediatesDir"
      cp -r dist/build "$installIntermediatesDir"
      runHook postInstallIntermediates
    '';

    passthru = passthru // rec {

      inherit pname version disallowGhcReference;

      compiler = ghc;

      getCabalDeps = {
        inherit
          buildDepends
          buildTools
          executableFrameworkDepends
          executableHaskellDepends
          executablePkgconfigDepends
          executableSystemDepends
          executableToolDepends
          extraLibraries
          libraryFrameworkDepends
          libraryHaskellDepends
          libraryPkgconfigDepends
          librarySystemDepends
          libraryToolDepends
          pkg-configDepends
          setupHaskellDepends
          ;
        ${if doCheck then "testDepends" else null} = testDepends;
        ${if doCheck then "testFrameworkDepends" else null} = testFrameworkDepends;
        ${if doCheck then "testHaskellDepends" else null} = testHaskellDepends;
        ${if doCheck then "testPkgconfigDepends" else null} = testPkgconfigDepends;
        ${if doCheck then "testSystemDepends" else null} = testSystemDepends;
        ${if doCheck then "testToolDepends" else null} = testToolDepends;
        ${if doBenchmark then "benchmarkDepends" else null} = benchmarkDepends;
        ${if doBenchmark then "benchmarkFrameworkDepends" else null} = benchmarkFrameworkDepends;
        ${if doBenchmark then "benchmarkHaskellDepends" else null} = benchmarkHaskellDepends;
        ${if doBenchmark then "benchmarkPkgconfigDepends" else null} = benchmarkPkgconfigDepends;
        ${if doBenchmark then "benchmarkSystemDepends" else null} = benchmarkSystemDepends;
        ${if doBenchmark then "benchmarkToolDepends" else null} = benchmarkToolDepends;
      };

      getBuildInputs = rec {
        inherit propagatedBuildInputs otherBuildInputs allPkgconfigDepends;
        haskellBuildInputs = isHaskellPartition.right;
        systemBuildInputs = isHaskellPartition.wrong;
        isHaskellPartition = lib.partition isHaskellPkg (
          propagatedBuildInputs ++ otherBuildInputs ++ depsBuildBuild ++ nativeBuildInputs
        );
      };

      isHaskellLibrary = isLibrary;

      haddockDir = self: if doHaddock then "${docdir self.doc}/html" else null;

      envFunc =
        {
          withHoogle ? false,
        }:
        let
          name = "ghc-shell-for-${drv.name}";

          withPackages = if withHoogle then ghcWithHoogle else ghcWithPackages;

          ghcEnvForBuild =
            assert isCross;
            buildHaskellPackages.ghcWithPackages (_: setupHaskellDepends);

          ghcEnv = withPackages (
            _: otherBuildInputsHaskell ++ propagatedBuildInputs ++ lib.optionals (!isCross) setupHaskellDepends
          );

          ghcCommandCaps = lib.toUpper ghcCommand';
        in
        runCommandCC name {
          inherit shellHook;

          depsBuildBuild = lib.optional isCross ghcEnvForBuild;
          nativeBuildInputs = [
            ghcEnv
          ]
          ++ optional (allPkgconfigDepends != [ ]) pkg-config
          ++ collectedToolDepends;
          buildInputs = otherBuildInputsSystem;

          env = {
            "NIX_${ghcCommandCaps}" = "${ghcEnv}/bin/${ghcCommand}";
            "NIX_${ghcCommandCaps}PKG" = "${ghcEnv}/bin/${ghcCommand}-pkg";
            "NIX_${ghcCommandCaps}_DOCDIR" = "${ghcEnv}/share/doc/ghc/html";
            "NIX_${ghcCommandCaps}_LIBDIR" =
              if ghc.isHaLVM or false then "${ghcEnv}/lib/HaLVM-${ghc.version}" else "${ghcEnv}/${ghcLibdir}";
            ${if (stdenv.buildPlatform.libc == "glibc") then "LOCALE_ARCHIVE" else null} =
              "${buildPackages.glibcLocales}/lib/locale/locale-archive";
          }
          // env';
        } "echo $nativeBuildInputs $buildInputs > $out";

      env = envFunc { };

    };

    meta = {
      inherit homepage platforms;
      ${if (args ? broken) then "broken" else null} = broken;
      ${if (args ? description) then "description" else null} = description;
      ${if (args ? license) then "license" else null} = license;
      ${if (args ? maintainers) then "maintainers" else null} = maintainers;
      ${if (args ? teams) then "teams" else null} = teams;
      ${if (args ? hydraPlatforms) then "hydraPlatforms" else null} = hydraPlatforms;
      ${if (args ? badPlatforms) then "badPlatforms" else null} = badPlatforms;
      ${if (args ? changelog) then "changelog" else null} = changelog;
      ${if (args ? mainProgram) then "mainProgram" else null} = mainProgram;
    };

    ${if (args ? sourceRoot) then "sourceRoot" else null} = sourceRoot;
    ${if (args ? setSourceRoot) then "setSourceRoot" else null} = setSourceRoot;
    ${if (args ? preCompileBuildDriver) then "preCompileBuildDriver" else null} = preCompileBuildDriver;
    ${if (args ? postCompileBuildDriver) then "postCompileBuildDriver" else null} =
      postCompileBuildDriver;
    ${if (args ? preUnpack) then "preUnpack" else null} = preUnpack;
    ${if (args ? postUnpack) then "postUnpack" else null} = postUnpack;
    ${if (args ? patches) then "patches" else null} = patches;
    ${if (args ? patchPhase) then "patchPhase" else null} = patchPhase;
    ${if (args ? preConfigure) then "preConfigure" else null} = preConfigure;
    ${if (args ? postConfigure) then "postConfigure" else null} = postConfigure;
    ${if (args ? preBuild) then "preBuild" else null} = preBuild;
    ${if (args ? postBuild) then "postBuild" else null} = postBuild;
    ${if (args ? doBenchmark) then "doBenchmark" else null} = doBenchmark;
    ${if (args ? checkPhase) then "checkPhase" else null} = checkPhase;
    ${if (args ? preCheck) then "preCheck" else null} = preCheck;
    ${if (args ? postCheck) then "postCheck" else null} = postCheck;
    ${if (args ? preHaddock) then "preHaddock" else null} = preHaddock;
    ${if (args ? postHaddock) then "postHaddock" else null} = postHaddock;
    ${if (args ? preInstall) then "preInstall" else null} = preInstall;
    ${if (args ? installPhase) then "installPhase" else null} = installPhase;
    ${if (args ? postInstall) then "postInstall" else null} = postInstall;
    ${if (args ? preFixup) then "preFixup" else null} = preFixup;
    ${if (args ? postFixup) then "postFixup" else null} = postFixup;
    ${if (args ? dontStrip) then "dontStrip" else null} = dontStrip;
    ${if (postPhases != [ ]) then "postPhases" else null} = postPhases;
    ${if (disallowedRequisites != [ ] || disallowGhcReference) then "disallowedRequisites" else null} =
      disallowedRequisites ++ (if disallowGhcReference then [ ghc ] else [ ]);
    ${
      if (__darwinAllowLocalNetworking || args ? __darwinAllowLocalNetworking) then
        "__darwinAllowLocalNetworking"
      else
        null
    } =
      __darwinAllowLocalNetworking;
  })
)
