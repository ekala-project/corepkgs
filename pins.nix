{
  lib = import (
    builtins.fetchGit {
      url = "https://github.com/ekala-project/nix-lib.git";
      rev = "fd5cdc455e167022c720950fcc599c8a5ef618a1";
    }
  );
}
