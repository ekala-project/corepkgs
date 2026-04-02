{
  # Standard Lua versions
  v5_1 = {
    version = "5.1.5";
    hash = "2640fc56a795f29d28ef15e13c34a47e223960b0240e8cb0a82d9b0738695333";
    compat = false;
    isLuaJIT = false;
    patches = [ ./CVE-2014-5461.patch ];
    darwinPatch = ./5.1.darwin.patch;
  };

  v5_2 = {
    version = "5.2.4";
    hash = "0jwznq0l8qg9wh5grwg07b5cy3lzngvl5m2nl1ikp6vqssmf9qmr";
    compat = false;
    isLuaJIT = false;
    patches = [ ./CVE-2022-28805.patch ];
    darwinPatch = ./5.2.darwin.patch;
  };

  v5_2_compat = {
    version = "5.2.4";
    hash = "0jwznq0l8qg9wh5grwg07b5cy3lzngvl5m2nl1ikp6vqssmf9qmr";
    compat = true;
    isLuaJIT = false;
    patches = [ ./CVE-2022-28805.patch ];
    darwinPatch = ./5.2.darwin.patch;
  };

  v5_3 = {
    version = "5.3.6";
    hash = "0q3d8qhd7p0b7a4mh9g7fxqksqfs6mr1nav74vq26qvkp2dxcpzw";
    compat = false;
    isLuaJIT = false;
    patches = [ ];
    darwinPatch = ./5.2.darwin.patch;
  };

  v5_3_compat = {
    version = "5.3.6";
    hash = "0q3d8qhd7p0b7a4mh9g7fxqksqfs6mr1nav74vq26qvkp2dxcpzw";
    compat = true;
    isLuaJIT = false;
    patches = [ ];
    darwinPatch = ./5.2.darwin.patch;
  };

  v5_4 = {
    version = "5.4.7";
    hash = "sha256-n79eKO+GxphY9tPTTszDLpEcGii0Eg/z6EqqcM+/HjA=";
    compat = false;
    isLuaJIT = false;
    patches = [ ];
    darwinPatch = ./5.4.darwin.patch;
  };

  v5_4_compat = {
    version = "5.4.7";
    hash = "sha256-n79eKO+GxphY9tPTTszDLpEcGii0Eg/z6EqqcM+/HjA=";
    compat = true;
    isLuaJIT = false;
    patches = [ ];
    darwinPatch = ./5.4.darwin.patch;
  };

  v5_5 = {
    version = "5.5.0";
    hash = "sha256-V8zDK7vQBcq3W8xSREBSU1r2kXiduiuQFtXFBkDWiz0=";
    compat = false;
    isLuaJIT = false;
    patches = [ ];
    darwinPatch = ./5.5.darwin.patch;
  };

  v5_5_compat = {
    version = "5.5.0";
    hash = "sha256-V8zDK7vQBcq3W8xSREBSU1r2kXiduiuQFtXFBkDWiz0=";
    compat = true;
    isLuaJIT = false;
    patches = [ ];
    darwinPatch = ./5.5.darwin.patch;
  };

  # LuaJIT variants
  luajit_2_0 = {
    version = "2.0.1741557863";
    isLuaJIT = true;
    luajitVariant = "2.0";
  };

  luajit_2_1 = {
    version = "2.1";
    isLuaJIT = true;
    luajitVariant = "2.1";
  };

  luajit_openresty = {
    version = "openresty";
    isLuaJIT = true;
    luajitVariant = "openresty";
  };
}
