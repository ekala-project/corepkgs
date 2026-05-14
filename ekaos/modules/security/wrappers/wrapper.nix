{
  stdenv,
  unsecvars,
  linuxHeaders,
  sourceProg,
  debug ? false,
}:
# Security wrapper for setuid/setgid/capabilities programs
# Based on NixOS implementation
stdenv.mkDerivation {
  name = "security-wrapper-${baseNameOf sourceProg}";
  buildInputs = [ linuxHeaders ];
  dontUnpack = true;
  CFLAGS = [
    ''-DSOURCE_PROG="${sourceProg}"''
  ]
  ++ (
    if debug then
      [
        "-Werror"
        "-Og"
        "-g"
      ]
    else
      [
        "-Wall"
        "-O2"
      ]
  );
  dontStrip = debug;
  installPhase = ''
    mkdir -p $out/bin
    $CC $CFLAGS ${./wrapper.c} -I${unsecvars} -o $out/bin/security-wrapper
  '';
}
