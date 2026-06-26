# GHC with-packages wrapper
# Ported from nixpkgs pkgs/development/haskell-modules/with-packages-wrapper.nix
{
  lib,
  stdenv,
  haskellPackages,
  symlinkJoin,
  makeWrapper,
  useLLVM ? false,
  withHoogle ? false,
  installDocumentation ? true,
  hoogleWithPackages,
  postBuild ? "",
}:

selectPackages:

let
  inherit (haskellPackages) ghc;

  hoogleWithPackages' = if withHoogle then hoogleWithPackages selectPackages else null;

  checkPackage =
    p:
    if p == null || lib.isDerivation p then
      p
    else
      throw ''
        ghcWithPackages: expected a derivation, got a ${builtins.typeOf p}.
        A common cause is missing parentheses around an override, e.g.
          (hp: [ dontCheck hp.foo ])
        should be written as
          (hp: [ (dontCheck hp.foo) ]).
      '';

  packages = map checkPackage (selectPackages haskellPackages ++ [ hoogleWithPackages' ]);

  isHaLVM = ghc.isHaLVM or false;
  ghcCommand' = "ghc";
  ghcCommand = "${ghc.targetPrefix}${ghcCommand'}";
  ghcCommandCaps = lib.toUpper ghcCommand';
  libDir =
    if isHaLVM then
      "$out/lib/HaLVM-${ghc.version}"
    else
      "$out/lib/${ghc.targetPrefix}${ghc.haskellCompilerName}"
      + lib.optionalString (ghc ? hadrian) "/lib";
  docDir = "$out/share/doc/ghc/html";
  packageCfgDir = "${libDir}/package.conf.d";
  paths = lib.concatLists (
    map (pkg: [ pkg ] ++ lib.optionals installDocumentation [ (lib.getOutput "doc" pkg) ]) (
      lib.filter (x: x ? isHaskellLibrary) (lib.closePropagation packages)
    )
  );
  hasLibraries = lib.any (x: x.isHaskellLibrary) paths;
  llvm = lib.makeBinPath (
    [ ghc.llvmPackages.llvm ]
    ++ lib.optionals (lib.versionAtLeast ghc.version "9.10" || stdenv.targetPlatform.isDarwin) [
      ghc.llvmPackages.clang
    ]
  );
in

if paths == [ ] && !useLLVM then
  ghc
else
  symlinkJoin {
    name = ghc.name + "-with-packages";
    paths = paths ++ [ ghc ] ++ lib.optionals installDocumentation [ (lib.getOutput "doc" ghc) ];
    nativeBuildInputs = [ makeWrapper ];
    postBuild = ''
      for prg in ${ghcCommand} ${ghcCommand}i ${ghcCommand}-${ghc.version} ${ghcCommand}i-${ghc.version}; do
        if [[ -x "${ghc}/bin/$prg" ]]; then
          rm -f $out/bin/$prg
          makeWrapper ${ghc}/bin/$prg $out/bin/$prg                           \
            --add-flags '"-B$NIX_${ghcCommandCaps}_LIBDIR"'                   \
            --set "NIX_${ghcCommandCaps}"        "$out/bin/${ghcCommand}"     \
            --set "NIX_${ghcCommandCaps}PKG"     "$out/bin/${ghcCommand}-pkg" \
            --set "NIX_${ghcCommandCaps}_DOCDIR" "${docDir}"                  \
            --set "NIX_${ghcCommandCaps}_LIBDIR" "${libDir}"                  \
            ${lib.optionalString useLLVM ''--prefix "PATH" ":" "${llvm}"''}
        fi
      done

      for prg in runghc runhaskell; do
        if [[ -x "${ghc}/bin/$prg" ]]; then
          rm -f $out/bin/$prg
          makeWrapper ${ghc}/bin/$prg $out/bin/$prg                           \
            --add-flags "-f $out/bin/${ghcCommand}"                           \
            --set "NIX_${ghcCommandCaps}"        "$out/bin/${ghcCommand}"     \
            --set "NIX_${ghcCommandCaps}PKG"     "$out/bin/${ghcCommand}-pkg" \
            --set "NIX_${ghcCommandCaps}_DOCDIR" "${docDir}"                  \
            --set "NIX_${ghcCommandCaps}_LIBDIR" "${libDir}"
        fi
      done

      for prg in ${ghcCommand}-pkg ${ghcCommand}-pkg-${ghc.version}; do
        if [[ -x "${ghc}/bin/$prg" ]]; then
          rm -f $out/bin/$prg
          makeWrapper ${ghc}/bin/$prg $out/bin/$prg --add-flags "--global-package-db=${packageCfgDir}"
        fi
      done

      if [[ -x "${ghc}/bin/haddock" ]]; then
        rm -f $out/bin/haddock
        makeWrapper ${ghc}/bin/haddock $out/bin/haddock    \
          --add-flags '"-B$NIX_${ghcCommandCaps}_LIBDIR"'  \
          --set "NIX_${ghcCommandCaps}_LIBDIR" "${libDir}"
      fi

    ''
    + (lib.optionalString (stdenv.targetPlatform.isDarwin && !stdenv.targetPlatform.isiOS or false) ''
      local packageConfDir="${packageCfgDir}";
      local dynamicLinksDir="$out/lib/links";
      mkdir -p $dynamicLinksDir
      rm -f $dynamicLinksDir/*

      dynamicLibraryDirs=()

      for pkg in $($out/bin/ghc-pkg list --simple-output); do
        dynamicLibraryDirs+=($($out/bin/ghc-pkg --simple-output field "$pkg" dynamic-library-dirs))
      done

      for dynamicLibraryDir in $(echo "''${dynamicLibraryDirs[@]}" | tr ' ' '\n' | sort -u); do
        echo "Linking $dynamicLibraryDir/*.dylib from $dynamicLinksDir"
        find "$dynamicLibraryDir" -name '*.dylib' -exec ln -s {} "$dynamicLinksDir" \;
      done

      for f in $packageConfDir/*.conf; do
        cp $f $f-tmp
        rm $f
        sed "N;s,dynamic-library-dirs:\s*.*\n,dynamic-library-dirs: $dynamicLinksDir\n," $f-tmp > $f
        rm $f-tmp
      done
    '')
    + ''
      ${lib.optionalString hasLibraries ''
        rm ${packageCfgDir}/package.cache.lock
        rm ${packageCfgDir}/package.cache

        $out/bin/${ghcCommand}-pkg recache
      ''}
      $out/bin/${ghcCommand}-pkg check
    ''
    + postBuild;
    preferLocalBuild = true;
    passthru = {
      inherit (ghc) version meta targetPrefix;
      hoogle = hoogleWithPackages';
    };
  }
