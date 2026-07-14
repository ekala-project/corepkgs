{
  lib,
  stdenv,
  fetchurl,
  ncurses,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "htop";
  version = "3.5.1";

  src = fetchurl {
    url = "https://github.com/htop-dev/htop/releases/download/${finalAttrs.version}/htop-${finalAttrs.version}.tar.xz";
    hash = "sha256-Umzs1ihwqo0U0qeaNeoZfk4rUxfSdbVnzuBXSy3bLpo=";
  };

  buildInputs = [
    ncurses
  ];

  enableParallelBuilding = true;

  passthru.tests = {
    version = testers.testVersion {
      package = finalAttrs.finalPackage;
    };
  };

  meta = {
    homepage = "https://htop.dev/";
    description = "Interactive process viewer for Unix systems";
    longDescription = ''
      htop is an interactive process viewer for Unix systems. It is a text-mode
      application (for console or X terminals) and requires ncurses.

      Features:
      - Visual, real-time process monitoring
      - CPU, memory, and swap usage meters
      - Tree view of processes
      - Mouse support
      - Vertical and horizontal scrolling
      - Kill processes directly from htop
      - Change process priority (nice value)
      - Search processes
      - Filter processes by name
      - Color-coded displays

      htop is a better alternative to the traditional 'top' command, providing
      a more user-friendly and informative interface.
    '';
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.unix;
    maintainers = [ ];
  };
})
