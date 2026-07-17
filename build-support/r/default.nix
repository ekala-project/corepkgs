{
  stdenv,
  lib,
  R,
  gettext,
  gfortran,
}:

{
  buildInputs ? [ ],
  ...
}@attrs:

stdenv.mkDerivation (
  {
    buildInputs = buildInputs ++ [
      R
      gettext
    ];

    enableParallelBuilding = true;

    configurePhase = ''
      runHook preConfigure
      export MAKEFLAGS+="''${enableParallelBuilding:+-j$NIX_BUILD_CORES}"
      export R_LIBS_SITE="$R_LIBS_SITE''${R_LIBS_SITE:+:}$out/library"
      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild
      runHook postBuild
    '';

    installFlags = if attrs.doCheck or true then [ ] else [ "--no-test-load" ];

    rCommand = "R";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/library
      $rCommand CMD INSTALL --built-timestamp='1970-01-01 00:00:00 UTC' $installFlags --configure-args="$configureFlags" -l $out/library .
      runHook postInstall
    '';

    postFixup = ''
      if test -e $out/nix-support/propagated-build-inputs; then
          ln -s $out/nix-support/propagated-build-inputs $out/nix-support/propagated-user-env-packages
      fi
    '';

    checkPhase = ''
      # noop since R CMD INSTALL tests packages
    '';
  }
  // attrs
  // {
    name = "r-${attrs.name or "${attrs.pname}-${attrs.version}"}";
  }
)
