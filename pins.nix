{
  lib = import (builtins.fetchGit {
    url = "https://github.com/ekala-project/nix-lib.git";
    rev = "16fc631315c3937761d1ee22126b4b7818944fa5";
  });
}

