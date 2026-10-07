{
  lib,
  stdenv,
  zig,
}:

lib.extendMkDerivation {
  constructDrv = stdenv.mkDerivation;

  excludeDrvArgNames = [
    "zigHash"
    "fetchAll"
  ];

  extendDrvArgs =
    finalAttrs:
    {
      nativeBuildInputs ? [ ],

      # The SRI hash of the zig dependencies fetched by `zig build --fetch`.
      # If `null`, the project has no external dependencies.
      zigHash ? throw "buildZigPackage: zigHash is missing for ${finalAttrs.pname or finalAttrs.name}",

      # Whether to fetch all transitive dependencies (--fetch=all).
      fetchAll ? true,

      ...
    }@args:
    {
      inherit zigHash fetchAll;

      zigDeps =
        if finalAttrs.zigHash == null then
          null
        else
          zig.fetchDeps {
            inherit (finalAttrs) src pname version;
            inherit (finalAttrs) fetchAll;
            hash = finalAttrs.zigHash;
          };

      nativeBuildInputs = [ zig.hook ] ++ nativeBuildInputs;

      postConfigure =
        (args.postConfigure or "")
        + lib.optionalString (finalAttrs.zigDeps != null) ''
          ln -s ${finalAttrs.zigDeps} "$ZIG_GLOBAL_CACHE_DIR/p"
        '';

      meta = (args.meta or { }) // {
        platforms = (args.meta or { }).platforms or zig.meta.platforms;
      };
    };
}
