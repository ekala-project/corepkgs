# Local Hoogle database with packages
# Ported from nixpkgs pkgs/development/haskell-modules/hoogle.nix
{
  lib,
  stdenv,
  buildPackages,
  haskellPackages,
  writeText,
  runCommand,
}:

selectPackages:

let
  inherit (haskellPackages) ghc hoogle;
  packages = selectPackages haskellPackages;

  wrapper = ./hoogle-local-wrapper.sh;
  haddockExe = "haddock";
  ghcDocLibDir = ghc.doc + "/share/doc/ghc*/html/libraries";
  prologue = "${ghcDocLibDir}/prologue.txt";

  docPackages = lib.closePropagation (map (lib.getOutput "doc") packages);

  databasePath = "share/doc/hoogle/default.hoo";

in
buildPackages.stdenv.mkDerivation (finalAttrs: {
  name = "hoogle-with-packages";
  buildInputs = [
    ghc
    hoogle
  ];

  preferLocalBuild = true;
  allowSubstitutes = true;

  passAsFile = [ "buildCommand" ];

  buildCommand = ''
    ${
      let
        packages' = lib.filter (p: p != null) packages;
      in
      lib.optionalString (packages' != [ ] -> docPackages == [ ]) (
        "echo WARNING: localHoogle package list empty, even though"
        + " the following were specified: "
        + lib.concatMapStringsSep ", " (p: p.name) packages'
      )
    }
    mkdir -p $out/share/doc/hoogle

    echo importing builtin packages
    for docdir in ${ghcDocLibDir}"/"*; do
      name="$(basename $docdir)"
      if [[ -d $docdir ]]; then
        ln -sfn $docdir $out/share/doc/hoogle/$name
      fi
    done

    echo importing other packages
    ${lib.concatMapStringsSep "\n"
      (el: ''
        ln -sfn ${el.haddockDir} "$out/share/doc/hoogle/${el.name}"
      '')
      (
        lib.filter (el: el.haddockDir != null) (
          map (p: {
            haddockDir = if p ? haddockDir then p.haddockDir p else null;
            name = p.pname;
          }) docPackages
        )
      )
    }

    databasePath="$out/"${lib.escapeShellArg databasePath}

    echo building hoogle database
    hoogle generate --database "$databasePath" --local=$out/share/doc/hoogle

    echo building haddock index
    cd $out/share/doc/hoogle

    args=
    for hdfile in $(ls -1 *"/"*.haddock | grep -v '/ghc\.haddock' | sort); do
        name_version=`echo "$hdfile" | sed 's#/.*##'`
        args="$args --read-interface=$name_version,$hdfile"
    done

    ${ghc}/bin/${haddockExe} --gen-index --gen-contents -o . \
         -t "Haskell Hierarchical Libraries" \
         -p ${prologue} \
         $args

    echo finishing up
    mkdir -p $out/bin
    substitute ${wrapper} $out/bin/hoogle \
        --subst-var-by shell ${stdenv.shell} \
        --subst-var-by database "$databasePath" \
        --subst-var-by hoogle ${hoogle}
    chmod +x $out/bin/hoogle
  '';

  passthru = {
    isHaskellLibrary = false;
    inherit docPackages;
    database = "${finalAttrs.finalPackage}/${databasePath}";
  };

  meta = {
    description = "Local Hoogle database";
    platforms = ghc.meta.platforms;
    hydraPlatforms = lib.platforms.none;
    maintainers = [ ];
  };
})
