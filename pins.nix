{
  lib = import (
    builtins.fetchGit {
      url = "https://github.com/ekala-project/nix-lib.git";
      rev = "0eefb2da00ace95f1128a79b4800f4034ad8ddc0";
    }
  );
}
