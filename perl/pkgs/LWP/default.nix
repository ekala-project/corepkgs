{
  buildPerlPackage,
  fetchurl,
  FileListing,
  HTMLParser,
  HTTPCookieJar,
  HTTPCookies,
  HTTPDaemon,
  HTTPNegotiate,
  lib,
  NetHTTP,
  stdenv,
  TestFatal,
  TestNeeds,
  TestRequiresInternet,
  TryTiny,
  WWWRobotRules,
}:

buildPerlPackage {
  pname = "libwww-perl";
  version = "6.72";
  src = fetchurl {
    url = "mirror://cpan/authors/id/O/OA/OALDERS/libwww-perl-6.72.tar.gz";
    hash = "sha256-6bg1T9XiC+IHr+I93VhPzVm/gpmNwHfez2hLodrloF0=";
  };
  propagatedBuildInputs = [
    FileListing
    HTMLParser
    HTTPCookies
    HTTPCookieJar
    HTTPNegotiate
    NetHTTP
    TryTiny
    WWWRobotRules
  ];
  # support cross-compilation by avoiding using `has_module` which does not work in miniperl (it requires B native module)
  postPatch = lib.optionalString (stdenv.buildPlatform != stdenv.hostPlatform) ''
    substituteInPlace Makefile.PL --replace 'if has_module' 'if 0; #'
  '';
  doCheck = !stdenv.hostPlatform.isDarwin;
  nativeCheckInputs = [
    HTTPDaemon
    TestFatal
    TestNeeds
    TestRequiresInternet
  ];
  meta = {
    description = "World-Wide Web library for Perl";
  };
}
