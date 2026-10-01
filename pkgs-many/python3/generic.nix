{
  version,
  src-hash,
  suffix ? "",
  packageOlder,
  packageAtLeast,
  mkVariantPassthru,
  withMinimalDeps ? false,
  pythonAttr ? null,
  ...
}@variantArgs:

let
  inherit (builtins) elemAt;
  dotParts = builtins.filter builtins.isString (builtins.split "\\." version);
  sourceVersion = {
    major = elemAt dotParts 0;
    minor = elemAt dotParts 1;
    patch = builtins.replaceStrings [ suffix ] [ "" ] (elemAt dotParts 2);
    inherit suffix;
  };
  pythonAttr' =
    if pythonAttr != null then pythonAttr else "python${sourceVersion.major}${sourceVersion.minor}";
in

{
  lib,
  callPackage,
  stdenv,
  config,
  makeScopeWithSplicing',
  pythonPackagesExtensions ? [ ],
  packageOverrides ? (self: super: { }),
  __splicedPackages,
  pkgsBuildBuild,
  pkgsBuildHost,
  pkgsBuildTarget,
  pkgsHostHost,
  pkgsTargetTarget,
  python-setup-hook,

  # CPython-specific overridable parameters
  enableGIL ? true,
  enableOptimizations ? false,
  enableLTO ?
    !withMinimalDeps
    && (stdenv.hostPlatform.isDarwin || (stdenv.hostPlatform.is64bit && stdenv.hostPlatform.isLinux)),
  enableFramework ? false,
  enableDebug ? false,
  enableNoSemanticInterposition ? true,
  static ? stdenv.hostPlatform.isStatic,
  stripBytecode ? true,
  rebuildBytecode ? !withMinimalDeps,
  reproducibleBuild ? false,
  stripConfig ? withMinimalDeps,
  stripIdlelib ? withMinimalDeps,
  stripTests ? withMinimalDeps,
  stripTkinter ? withMinimalDeps,
  includeSiteCustomize ? !withMinimalDeps,
  bluezSupport ? !withMinimalDeps && stdenv.hostPlatform.isLinux,
  mimetypesSupport ? !withMinimalDeps,
  withExpat ? !withMinimalDeps,
  withGdbm ? !withMinimalDeps && !stdenv.hostPlatform.isWindows,
  withMpdecimal ? !withMinimalDeps,
  withOpenssl ? !withMinimalDeps,
  withReadline ? !withMinimalDeps && !stdenv.hostPlatform.isWindows,
  withSqlite ? !withMinimalDeps,
  ...
}@packageArgs:

let
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

  cpythonInterpreter = callPackage ../../python/cpython {
    self = cpythonInterpreter;
    inherit
      sourceVersion
      passthruFun
      packageOverrides
      enableGIL
      withMinimalDeps
      enableOptimizations
      enableLTO
      enableFramework
      enableDebug
      enableNoSemanticInterposition
      static
      stripBytecode
      rebuildBytecode
      reproducibleBuild
      stripConfig
      stripIdlelib
      stripTests
      stripTkinter
      includeSiteCustomize
      bluezSupport
      mimetypesSupport
      withExpat
      withGdbm
      withMpdecimal
      withOpenssl
      withReadline
      withSqlite
      ;
    pythonAttr = pythonAttr';
    hash = src-hash;
  };
in
cpythonInterpreter.overrideAttrs (oldAttrs: {
  ${if withMinimalDeps then "pname" else null} = "python3-minimal";
  passthru =
    (oldAttrs.passthru or { })
    // mkVariantPassthru variantArgs
    // {
      inherit variantArgs;
    };
})
