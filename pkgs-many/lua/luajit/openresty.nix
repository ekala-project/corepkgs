{
  self,
  callPackage,
  fetchFromGitHub,
  passthruFun,
}:

callPackage ./default.nix rec {
  version = "2.1-20261117";

  src = fetchFromGitHub {
    owner = "openresty";
    repo = "luajit2";
    tag = "v${version}";
    hash = "sha256-COz+UvlqQpDRnq3yyZsiUF6cX67Fm04GJgXa+grl6iI=";
  };

  inherit self passthruFun;
}
