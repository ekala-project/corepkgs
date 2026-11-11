# Hooks for building lua packages.
{
  lua,
  makeSetupHook,
}:

let
  callPackage = lua.pkgs.callPackage;
in
{
  /**
    Accepts "bustedFlags" as an array.
    You can customize the call by setting "bustedFlags" and prevent the test from running by setting "dontBustedCheck"
  */
  bustedCheckHook = callPackage (
    # busted is not packaged here; package sets layered on top (lua-pkgs)
    # provide it. Throw rather than abort without it, so the hook is still
    # catchable when only corepkgs is evaluated.
    {
      busted ? null,
    }:
    if busted == null then
      throw "bustedCheckHook: busted is not in this Lua package set"
    else
      makeSetupHook {
        name = "busted-check-hook";
        propagatedBuildInputs = [
          busted
        ];
      } ./busted-check-hook.sh
  ) { };

  luarocksCheckHook = callPackage (
    # Package sets layered on top (lua-pkgs) provide a full `luarocks`; fall
    # back to the bootstrap one that every luarocks build already uses.
    {
      luarocks ? null,
      luarocks_bootstrap,
    }:
    makeSetupHook {
      name = "luarocks-check-hook";
      propagatedBuildInputs = [ (if luarocks == null then luarocks_bootstrap else luarocks) ];
    } ./luarocks-check-hook.sh
  ) { };

  # luarocks installs data in a non-overridable location. Until a proper luarocks patch,
  # we move the files around ourselves
  luarocksMoveDataFolder = makeSetupHook {
    name = "luarocks-move-rock";
    propagatedBuildInputs = [ ];
  } ./luarocks-move-data.sh;
}
