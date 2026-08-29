{
  buildPerlPackage,
  fetchurl,
  IOTty,
  Readonly,
}:

buildPerlPackage {
  pname = "IPC-Run";
  version = "20231003.0";
  src = fetchurl {
    url = "mirror://cpan/authors/id/T/TO/TODDR/IPC-Run-20231003.0.tar.gz";
    hash = "sha256-6yW731kT0pF5fvG/6ZjxUTC0VdPtAqrN5oVvCyXk/lc=";
  };
  doCheck = false; # attempts a network connection to localhost
  propagatedBuildInputs = [ IOTty ];
  buildInputs = [ Readonly ];
  meta = {
    description = "System() and background procs w/ piping, redirs, ptys (Unix, Win32)";
  };
}
