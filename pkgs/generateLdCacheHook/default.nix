{
  makeSetupHook,
  replaceVars,
  patchelf,
}:

makeSetupHook
  {
    name = "generate-ld-cache-hook";
  }
  (
    replaceVars ./generate-ld-cache.sh {
      patchelf = "${patchelf}/bin/patchelf";
    }
  )
