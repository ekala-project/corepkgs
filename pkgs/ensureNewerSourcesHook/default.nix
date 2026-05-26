{
  makeSetupHook,
  writeScript,
  findutils,
}:

{ year }:

makeSetupHook
  {
    name = "ensure-newer-sources-hook";
  }
  (
    writeScript "ensure-newer-sources-hook.sh" ''
      postUnpackHooks+=(_ensureNewerSources)
      _ensureNewerSources() {
        local r=$sourceRoot
                # Avoid passing option-looking directory to find. The example is diffoscope-269:
                #   https://salsa.debian.org/reproducible-builds/diffoscope/-/issues/378
                [[ $r == -* ]] && r="./$r"
                '${findutils}/bin/find' "$r" \
                  '!' -newermt '${year}-01-01' -exec touch -h -d '${year}-01-02' '{}' '+'
              }
    ''
  )
