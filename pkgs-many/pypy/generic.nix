{
  sourceVersion,
  src-hash,
  pythonVersion,
  mkVariantPassthru,
  usePrebuiltBootstrap ? false,
  ...
}@variantArgs:

{
  lib,
  callPackage,
  stdenv,
  config,
  makeScopeWithSplicing',
  pythonPackagesExtensions ? [ ],
  packageOverrides ? (self: super: { }),
  __splicedPackages,
  db,
  ...
}@packageArgs:

let
  pythonAttr = "pypy${lib.substring 0 1 pythonVersion}${lib.substring 2 3 pythonVersion}";

  passthruFun = import ../../python/passthrufun.nix {
    inherit
      lib
      config
      makeScopeWithSplicing'
      stdenv
      callPackage
      pythonPackagesExtensions
      ;
  };

  bootstrapPython =
    if usePrebuiltBootstrap then
      __splicedPackages.pythonInterpreters.pypy27_prebuilt
    else
      __splicedPackages.pypy27;

  interpreter = callPackage ../../python/pypy {
    self = interpreter;
    inherit
      sourceVersion
      pythonVersion
      passthruFun
      packageOverrides
      ;
    hash = src-hash;
    db = db.override { dbmSupport = !stdenv.hostPlatform.isDarwin; };
    python = bootstrapPython;
  };
in
interpreter.overrideAttrs (oldAttrs: {
  passthru =
    (oldAttrs.passthru or { })
    // mkVariantPassthru variantArgs
    // {
      inherit variantArgs;
    };
})
