/*
  This file defines the composition for Lua packages.  It has
  been factored out of all-packages.nix because there are many of
  them.  Also, because most Nix expressions for Lua packages are
  trivial, most are actually defined here.  I.e. there's no function
  for each package in a separate file: the call to the function would
  be almost as must code as the function itself.
*/

{
  pkgs,
  stdenv,
  lib,
  lua,
}:

self:

let
  inherit (self) callPackage;

  buildLuaApplication = args: buildLuarocksPackage ({ namePrefix = ""; } // args);

  buildLuarocksPackage = lib.makeOverridable (callPackage ./build-luarocks-package.nix { });

  luaLib = callPackage ./modules/lib.nix { };

  #define build lua package function
  buildLuaPackage = callPackage ./modules/generic { };

  getPath =
    drv: pathListForVersion: lib.concatMapStringsSep ";" (path: "${drv}/${path}") pathListForVersion;

in
rec {

  # Dont take luaPackages from "global" pkgs scope to avoid mixing lua versions
  luaPackages = self;

  # helper functions for dealing with LUA_PATH and LUA_CPATH
  inherit luaLib;

  getLuaPath = drv: getPath drv luaLib.luaPathList;
  getLuaCPath = drv: getPath drv luaLib.luaCPathList;

  inherit (callPackage ./hooks { })
    luarocksMoveDataFolder
    luarocksCheckHook
    bustedCheckHook
    ;

  inherit lua;
  inherit buildLuaPackage buildLuarocksPackage buildLuaApplication;
  inherit (luaLib)
    luaOlder
    luaAtLeast
    isLua51
    isLua52
    isLua53
    isLuaJIT
    requiredLuaModules
    toLuaModule
    hasLuaModule
    ;

  # wraps programs in $out/bin with valid LUA_PATH/LUA_CPATH
  wrapLua = callPackage ./wrap-lua.nix { };

  luarocks_bootstrap = toLuaModule (callPackage ./luarocks { });

  # a fork of luarocks used to generate nix lua derivations from rockspecs
  luarocks-nix = toLuaModule (callPackage ./luarocks/luarocks-nix.nix { });
}
