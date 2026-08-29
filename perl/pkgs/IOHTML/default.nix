{
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "IO-HTML";
  version = "1.004";
  src = fetchurl {
    url = "mirror://cpan/authors/id/C/CJ/CJM/IO-HTML-1.004.tar.gz";
    hash = "sha256-yHst9ZRju/LDlZZ3PftcA73g9+EFGvM5+WP1jBy9i/U=";
  };
  meta = {
    description = "Open an HTML file with automatic charset detection";
  };
}
