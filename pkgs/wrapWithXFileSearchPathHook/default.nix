{
  lib,
  makeBinaryWrapper,
  makeSetupHook,
  writeScript,
}:

makeSetupHook
  {
    name = "wrapWithXFileSearchPathHook";
    propagatedBuildInputs = [ makeBinaryWrapper ];
    meta = {
      description = "Setup hook for wrapping programs with X file search paths";
      license = lib.licenses.mit;
      platforms = lib.platforms.all;
    };
  }
  (
    writeScript "wrapWithXFileSearchPathHook.sh" ''
      wrapWithXFileSearchPath() {
        paths=(
          "$out/share/X11/%T/%N"
          "$out/include/X11/%T/%N"
        )
        for exe in $out/bin/*; do
          wrapProgram "$exe" \
            --suffix XFILESEARCHPATH : $(IFS=:; echo "''${paths[*]}")
        done
      }
      postInstallHooks+=(wrapWithXFileSearchPath)
    ''
  )
