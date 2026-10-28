{
  buildGoModule,
  lib,
  fetchFromGitHub,
  testers,
}:

buildGoModule (finalAttrs: {
  pname = "go-tools";
  version = "2026.2.2";

  src = fetchFromGitHub {
    owner = "dominikh";
    repo = "go-tools";
    tag = finalAttrs.version;
    sha256 = "sha256-nmcXIQf9Mws4CMQDKQ1NUYHLYkm+ggSnh5sDiuvdnK4=";
  };

  vendorHash = "sha256-YC+DQZ3xjLGzhUXq/KBYhi1PGE63hBFaFor+XUZE1Ng=";

  excludedPackages = [
    "website"
    "staticcheck/sa5000"
  ];

  passthru.tests = {
    version = testers.testVersion {
      package = finalAttrs.finalPackage;
      command = "staticcheck -version";
    };
  };

  meta = {
    description = "Collection of tools and libraries for working with Go code, including linters and static analysis";
    homepage = "https://staticcheck.io";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
