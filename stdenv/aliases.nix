lib: final: prev:
let
  inherit (final) pkgs;
  # Removing recurseForDerivation prevents derivations of aliased attribute set
  # to appear while listing all the packages available.
  removeRecurseForDerivations =
    alias:
    if alias.recurseForDerivations or false then
      lib.removeAttrs alias [ "recurseForDerivations" ]
    else
      alias;

  # Make sure that we are not shadowing something from top-level.nix.
  checkInPkgs =
    n: alias: if builtins.hasAttr n prev then abort "Alias ${n} is still in top-level.nix" else alias;

  mapAliases =
    aliases: lib.mapAttrs (n: alias: removeRecurseForDerivations (checkInPkgs n alias)) aliases;
in
with pkgs;
# These largely reflect Nixpkgs aliases
mapAliases {
  # keep-sorted start

  autoconf269 = autoconf.v2_69;
  autoconf271 = autoconf.v2_71;
  automake116x = automake.v1_16;
  automake118x = automake.v1_18;
  autoreconfHook269 = autoconf.v2_69.autoreconfHook;
  autoreconfHook271 = autoconf.v2_71.autoreconfHook;
  bolt_19 = llvm.v19.pkgs.bolt;
  bolt_20 = llvm.v20.pkgs.bolt;
  bolt_21 = llvm.v21.pkgs.bolt;
  clang_18 = llvm.v18.pkgs.clang;
  clang_19 = llvm.v19.pkgs.clang;
  clang_20 = llvm.v20.pkgs.clang;
  clang_21 = llvm.v21.pkgs.clang;
  cmakeMinimal = cmake.minimal;
  curlMinimal = curl.minimal;
  curlWithGnuTls = curl.gnutls;
  db4 = db.v4_8;
  db48 = db.v4_8;
  db5 = db.v5_3;
  db53 = db.v5_3;
  db6 = db.v6_0;
  db60 = db.v6_0;
  db62 = db.v6_2;
  flang_20 = llvm.v20.pkgs.flang;
  flang_21 = llvm.v21.pkgs.flang;
  flex_2_5_39 = flex.v2_5_39;
  gmp6 = gmp.variants.v6_3;
  gmpxx = gmp.variants.cxx;
  go_1_24 = go.v1_24;
  go_1_25 = go.v1_25;
  guile_1_8 = guile.v1_8;
  guile_2_0 = guile.v2_0;
  guile_2_2 = guile.v2_2;
  guile_3_0 = guile.v3_0;
  icu60 = icu.v60;
  icu63 = icu.v63;
  icu64 = icu.v64;
  icu66 = icu.v66;
  icu67 = icu.v67;
  icu69 = icu.v69;
  icu70 = icu.v70;
  icu71 = icu.v71;
  icu72 = icu.v72;
  icu73 = icu.v73;
  icu74 = icu.v74;
  icu75 = icu.v75;
  icu76 = icu.v76;
  icu77 = icu.v77;
  icu78 = icu.v78;
  libtool2 = libtool.v2_5;
  libtool_1_5 = libtool.v1_5;
  lld_18 = llvm.v18.pkgs.lld;
  lld_19 = llvm.v19.pkgs.lld;
  lld_20 = llvm.v20.pkgs.lld;
  lld_21 = llvm.v21.pkgs.lld;
  lldb_18 = llvm.v18.pkgs.lldb;
  lldb_19 = llvm.v19.pkgs.lldb;
  lldb_20 = llvm.v20.pkgs.lldb;
  lldb_21 = llvm.v21.pkgs.lldb;
  llvm_18 = llvm.v18.pkgs.llvm;
  llvm_19 = llvm.v19.pkgs.llvm;
  llvm_20 = llvm.v20.pkgs.llvm;
  llvm_21 = llvm.v21.pkgs.llvm;
  lua5_1 = lua.v5_1;
  lua5_2 = lua.v5_2;
  lua5_2_compat = lua.v5_2_compat;
  lua5_3 = lua.v5_3;
  lua5_3_compat = lua.v5_3_compat;
  lua5_4 = lua.v5_4;
  lua5_4_compat = lua.v5_4_compat;
  lua5_5 = lua.v5_5;
  lua5_5_compat = lua.v5_5_compat;
  luajit_2_0 = lua.luajit_2_0;
  luajit_2_1 = lua.luajit_2_1;
  luajit_openresty = lua.luajit_openresty;
  ncurses5 = ncurses.v5;
  ncurses6 = ncurses.v6;
  openssl_oqs = openssl.oqs;
  perl538 = perl.v5_38;
  perl540 = perl.v5_40;
  tcl-8_5 = tcl.v8_5;
  tcl-8_6 = tcl.v8_6;
  tcl-9_0 = tcl.v9_0;
  # keep-sorted end
}
