{ stdenv, lib }:

let
  inherit (lib)
    findFirst
    isString
    mapAttrs
    optionalAttrs
    optional
    optionals
    ;

  isCross = stdenv.hostPlatform != stdenv.buildPlatform;

  cmakeFlags' = optionals isCross (
    [
      "-DCMAKE_SYSTEM_NAME=${
        findFirst isString "Generic" (
          optional (!stdenv.hostPlatform.isRedox) stdenv.hostPlatform.uname.system
        )
      }"
    ]
    ++ optionals (stdenv.hostPlatform.uname.processor != null) [
      "-DCMAKE_SYSTEM_PROCESSOR=${stdenv.hostPlatform.uname.processor}"
    ]
    ++ optionals (stdenv.hostPlatform.uname.release != null) [
      "-DCMAKE_SYSTEM_VERSION=${stdenv.hostPlatform.uname.release}"
    ]
    ++ optionals (stdenv.hostPlatform.isDarwin) [
      "-DCMAKE_OSX_ARCHITECTURES=${stdenv.hostPlatform.darwinArch}"
    ]
    ++ optionals (stdenv.buildPlatform.uname.system != null) [
      "-DCMAKE_HOST_SYSTEM_NAME=${stdenv.buildPlatform.uname.system}"
    ]
    ++ optionals (stdenv.buildPlatform.uname.processor != null) [
      "-DCMAKE_HOST_SYSTEM_PROCESSOR=${stdenv.buildPlatform.uname.processor}"
    ]
    ++ optionals (stdenv.buildPlatform.uname.release != null) [
      "-DCMAKE_HOST_SYSTEM_VERSION=${stdenv.buildPlatform.uname.release}"
    ]
    ++ optionals (stdenv.buildPlatform.canExecute stdenv.hostPlatform) [
      "-DCMAKE_CROSSCOMPILING_EMULATOR=env"
    ]
    ++ optionals (stdenv.hostPlatform.isNone) [
      "-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY"
    ]
    ++ optionals stdenv.hostPlatform.isStatic [
      "-DCMAKE_LINK_SEARCH_START_STATIC=ON"
    ]
  );

  # Cross-compilation entries as an attrset for cmakeEntries
  cmakeEntries' = optionalAttrs isCross {
    CMAKE_SYSTEM_NAME = findFirst isString "Generic" (
      optional (!stdenv.hostPlatform.isRedox) stdenv.hostPlatform.uname.system
    );
    ${if stdenv.hostPlatform.uname.processor != null then "CMAKE_SYSTEM_PROCESSOR" else null} =
      stdenv.hostPlatform.uname.processor;
    ${if stdenv.hostPlatform.uname.release != null then "CMAKE_SYSTEM_VERSION" else null} =
      stdenv.hostPlatform.uname.release;
    ${if stdenv.hostPlatform.isDarwin then "CMAKE_OSX_ARCHITECTURES" else null} =
      stdenv.hostPlatform.darwinArch;
    ${if stdenv.buildPlatform.uname.system != null then "CMAKE_HOST_SYSTEM_NAME" else null} =
      stdenv.buildPlatform.uname.system;
    ${if stdenv.buildPlatform.uname.processor != null then "CMAKE_HOST_SYSTEM_PROCESSOR" else null} =
      stdenv.buildPlatform.uname.processor;
    ${if stdenv.buildPlatform.uname.release != null then "CMAKE_HOST_SYSTEM_VERSION" else null} =
      stdenv.buildPlatform.uname.release;
    ${
      if stdenv.buildPlatform.canExecute stdenv.hostPlatform then
        "CMAKE_CROSSCOMPILING_EMULATOR"
      else
        null
    } =
      "env";
    ${if stdenv.hostPlatform.isNone then "CMAKE_TRY_COMPILE_TARGET_TYPE" else null} = "STATIC_LIBRARY";
    ${if stdenv.hostPlatform.isStatic then "CMAKE_LINK_SEARCH_START_STATIC" else null} = "ON";
  };

  makeCMakeFlags =
    {
      cmakeFlags ? [ ],
      ...
    }:
    cmakeFlags ++ cmakeFlags';

  # Canonicalize user cmakeEntries values (bools -> "ON"/"OFF", others -> toString)
  # and merge with cross-compilation entries (user values take precedence).
  makeCMakeEntries =
    attrs@{
      cmakeEntries ? { },
      ...
    }:
    # Skip canonicalization for non-cmake builds; avoids per-derivation overhead during evaluation.
    if !isCross && !(attrs ? cmakeEntries) then
      { }
    else
      let
        canonicalize = _: v: if builtins.isBool v then (if v then "ON" else "OFF") else builtins.toString v;
      in
      cmakeEntries' // (mapAttrs canonicalize cmakeEntries);

in
{
  inherit makeCMakeFlags makeCMakeEntries;
}
