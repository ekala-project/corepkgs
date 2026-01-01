{
  lib = import (
    builtins.fetchGit {
      url = "https://github.com/ekala-project/nix-lib.git";
      rev = "2c14377c3f3825e2cd5ebf43858ec4aaac5bffde";
    }
  );
}
