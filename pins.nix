{
  lib = import (
    builtins.fetchGit {
      url = "https://github.com/ekala-project/nix-lib.git";
      rev = "3cabe9bf231b6127b27a7826d0421b60cabcdde9";
    }
  );
}
