let
  pins = import ./pins.nix;
  lib = import pins.lib;
in
lib.extend (
  _: super: {
    # nix-lib's `filesystem.nix` no longer re-exports these builtins, but its
    # `default.nix` still inherits them from `self.filesystem`, so each of them
    # throws `attribute '<name>' missing`. Restore them until nix-lib is fixed.
    filesystem = super.filesystem // {
      inherit (builtins)
        baseNameOf
        dirOf
        isPath
        readDir
        readFileType
        hashFile
        ;
    };

    # Deprecated: provided only because nix-lib's `systems.elaborate` gates its
    # compatibility asserts on it. This repo has no legacy release window, so
    # every gate is satisfied. Remove once nix-lib no longer requires it.
    trivial = super.trivial // {
      oldestSupportedReleaseIsAtLeast = _: true;
    };
  }
)
