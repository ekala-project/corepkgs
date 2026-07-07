{
  lib,
  stdenv,
  fetchurl,
  ncurses,
  groff,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lsof";
  version = "4.99.7";

  src = fetchurl {
    url = "https://github.com/lsof-org/lsof/releases/download/${finalAttrs.version}/lsof-${finalAttrs.version}.tar.gz";
    hash = "sha256-ShA5GqsLjOH1OegqGWZpOyps8iWXKmUE67fsT6cWdd4=";
  };

  nativeBuildInputs = [
    groff # for soelim to generate man pages
  ];

  buildInputs = [
    ncurses
  ];

  enableParallelBuilding = true;

  meta = {
    homepage = "https://github.com/lsof-org/lsof";
    description = "A tool to list open files";
    longDescription = ''
      lsof is a command meaning "list open files", which is used in many
      Unix-like systems to report a list of all open files and the processes
      that opened them.

      Features:
      - List all open files
      - Show processes that opened specific files
      - List files opened by specific processes
      - Display network connections (TCP, UDP sockets)
      - Show Unix domain sockets
      - Display open pipes
      - Show deleted files still held open
      - Filter by user, process, file descriptor type
      - Supports IPv4 and IPv6

      lsof is essential for system administration and debugging, helping to:
      - Find which process is using a file or directory
      - Identify network connections and listening ports
      - Troubleshoot "device or resource busy" errors
      - Detect deleted files still consuming disk space
    '';
    license = lib.licenses.bsd0;
    platforms = lib.platforms.unix;
    maintainers = [ ];
  };
})
