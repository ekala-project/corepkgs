{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation rec {
  pname = "p7zip";
  version = "17.05";

  src = fetchFromGitHub {
    owner = "p7zip-project";
    repo = "p7zip";
    rev = "v${version}";
    hash = "sha256-z3qXgv/TkNRbb85Ew1OcJNxoyssfzHShc0b0/4NZOb0=";
  };

  # Use the generic Unix makefile (no platform-specific optimizations)
  preConfigure = ''
    cp -v makefile.linux_any_cpu_gcc_4.X makefile.machine
  '';

  makeFlags = [
    "DEST_HOME=${placeholder "out"}"
    "DEST_BIN=${placeholder "out"}/bin"
    "DEST_SHARE=${placeholder "out"}/lib/p7zip"
    "DEST_MAN=${placeholder "out"}/share/man"
  ];

  enableParallelBuilding = true;

  # No install phase needed, the makefile handles it
  installFlags = [ "DEST_HOME=${placeholder "out"}" ];

  postInstall = ''
    # Create symlinks for common commands
    ln -s $out/bin/7za $out/bin/7z || true
  '';

  meta = {
    description = "A port of the 7-Zip archiver";
    homepage = "https://github.com/p7zip-project/p7zip";
    license = lib.licenses.lgpl21Plus;
    platforms = lib.platforms.unix;
    mainProgram = "7z";
  };
}
