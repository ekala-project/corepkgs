{
  lib = import (builtins.fetchGit {
    url = "https://github.com/ekala-project/nix-lib.git";
    rev = "e74186eac912734bec7ff8d10389f64bdb606113";
  });
}

