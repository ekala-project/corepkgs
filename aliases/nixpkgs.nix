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

  # Emit a deprecation warning and resolve the renamed attribute.
  renamed =
    old: new: val:
    lib.warn "'${old}' has been renamed to '${new}' in ekapkgs" val;
in
with pkgs;
# These largely reflect Nixpkgs aliases
mapAliases {
  # keep-sorted start
  SDL = renamed "SDL" "sdl12-compat" sdl12-compat;
  SDL2 = renamed "SDL2" "sdl2-compat" sdl2-compat;
  armTrustedFirmwareAllwinner =
    renamed "armTrustedFirmwareAllwinner" "arm-trusted-firmware.allwinner"
      arm-trusted-firmware.allwinner;
  armTrustedFirmwareAllwinnerH6 =
    renamed "armTrustedFirmwareAllwinnerH6" "arm-trusted-firmware.allwinnerH6"
      arm-trusted-firmware.allwinnerH6;
  armTrustedFirmwareAllwinnerH616 =
    renamed "armTrustedFirmwareAllwinnerH616" "arm-trusted-firmware.allwinnerH616"
      arm-trusted-firmware.allwinnerH616;
  armTrustedFirmwareQemu =
    renamed "armTrustedFirmwareQemu" "arm-trusted-firmware.qemu"
      arm-trusted-firmware.qemu;
  armTrustedFirmwareRK3328 =
    renamed "armTrustedFirmwareRK3328" "arm-trusted-firmware.rk3328"
      arm-trusted-firmware.rk3328;
  armTrustedFirmwareRK3399 =
    renamed "armTrustedFirmwareRK3399" "arm-trusted-firmware.rk3399"
      arm-trusted-firmware.rk3399;
  armTrustedFirmwareRK3568 =
    renamed "armTrustedFirmwareRK3568" "arm-trusted-firmware.rk3568"
      arm-trusted-firmware.rk3568;
  armTrustedFirmwareRK3588 =
    renamed "armTrustedFirmwareRK3588" "arm-trusted-firmware.rk3588"
      arm-trusted-firmware.rk3588;
  armTrustedFirmwareS905 =
    renamed "armTrustedFirmwareS905" "arm-trusted-firmware.s905"
      arm-trusted-firmware.s905;
  armTrustedFirmwareTools =
    renamed "armTrustedFirmwareTools" "arm-trusted-firmware.tools"
      arm-trusted-firmware.tools;
  at-spi2-atk = renamed "at-spi2-atk" "at-spi2-core" at-spi2-core; # merged into at-spi2-core
  atk = renamed "atk" "at-spi2-core" at-spi2-core; # merged into at-spi2-core
  autoconf269 = renamed "autoconf269" "autoconf.v2_69" autoconf.v2_69;
  autoconf271 = renamed "autoconf271" "autoconf.v2_71" autoconf.v2_71;
  automake116x = renamed "automake116x" "automake.v1_16" automake.v1_16;
  automake118x = renamed "automake118x" "automake.v1_18" automake.v1_18;
  autoreconfHook269 =
    renamed "autoreconfHook269" "autoconf.v2_69.autoreconfHook"
      autoconf.v2_69.autoreconfHook;
  autoreconfHook271 =
    renamed "autoreconfHook271" "autoconf.v2_71.autoreconfHook"
      autoconf.v2_71.autoreconfHook;
  bashInteractiveFHS = renamed "bashInteractiveFHS" "bashFHS" bashFHS;
  binutils-unwrapped = renamed "binutils-unwrapped" "binutils.unwrapped" binutils.unwrapped;
  binutils-unwrapped-all-targets =
    renamed "binutils-unwrapped-all-targets" "binutils.unwrapped-all-targets"
      binutils.unwrapped-all-targets;
  binutils-unwrapped_2_38 =
    renamed "binutils-unwrapped_2_38" "binutils.unwrapped.v2_38"
      binutils.unwrapped.v2_38;
  binutilsDualAs = throw "binutilsDualAs has been removed from Nixpkgs; use binutils";
  binutilsNoLibc = renamed "binutilsNoLibc" "binutils.noLibc" binutils.noLibc;
  bolt_19 = renamed "bolt_19" "llvm.v19.pkgs.bolt" llvm.v19.pkgs.bolt;
  bolt_20 = renamed "bolt_20" "llvm.v20.pkgs.bolt" llvm.v20.pkgs.bolt;
  bolt_21 = renamed "bolt_21" "llvm.v21.pkgs.bolt" llvm.v21.pkgs.bolt;
  buildGo124Module = renamed "buildGo124Module" "go.v1_24.buildModule" go.v1_24.buildModule;
  buildGo125Module = renamed "buildGo125Module" "go.v1_25.buildModule" go.v1_25.buildModule;
  buildGo126Module = renamed "buildGo126Module" "go.v1_26.buildModule" go.v1_26.buildModule;
  buildGo127Module = renamed "buildGo127Module" "go.v1_27.buildModule" go.v1_27.buildModule;
  buildGradlePackage = renamed "buildGradlePackage" "java.buildGradlePackage" java.buildGradlePackage;
  buildMavenPackage = renamed "buildMavenPackage" "java.buildMavenPackage" java.buildMavenPackage;
  buildNpmApplication =
    renamed "buildNpmApplication" "nodejs.buildNpmApplication"
      nodejs.buildNpmApplication;
  buildPnpmApplication =
    renamed "buildPnpmApplication" "nodejs.buildPnpmApplication"
      nodejs.buildPnpmApplication;
  buildYarnApplication =
    renamed "buildYarnApplication" "nodejs.buildYarnApplication"
      nodejs.buildYarnApplication;
  bzip2_1_1 = throw "'bzip2_1_1' has been removed as it was an unmaintained 2020 snapshot; use 'bzip2' instead";
  clang-manpages = renamed "clang-manpages" "llvmPackages.clang-manpages" llvmPackages.clang-manpages;
  clang-tools = renamed "clang-tools" "llvmPackages.clang-tools" llvmPackages.clang-tools;
  clang_18 = renamed "clang_18" "llvm.v18.pkgs.clang" llvm.v18.pkgs.clang;
  clang_19 = renamed "clang_19" "llvm.v19.pkgs.clang" llvm.v19.pkgs.clang;
  clang_20 = renamed "clang_20" "llvm.v20.pkgs.clang" llvm.v20.pkgs.clang;
  clang_21 = renamed "clang_21" "llvm.v21.pkgs.clang" llvm.v21.pkgs.clang;
  clj = renamed "clj" "clojure" clojure;
  cmakeMinimal = renamed "cmakeMinimal" "cmake.minimal" cmake.minimal;
  curlMinimal = renamed "curlMinimal" "curl.minimal" curl.minimal;
  curlWithGnuTls = renamed "curlWithGnuTls" "curl.gnutls" curl.gnutls;
  darwin = import ./darwin.nix pkgs;
  db4 = renamed "db4" "db.v4_8" db.v4_8;
  db48 = renamed "db48" "db.v4_8" db.v4_8;
  db5 = renamed "db5" "db.v5_3" db.v5_3;
  db53 = renamed "db53" "db.v5_3" db.v5_3;
  db6 = renamed "db6" "db.v6_0" db.v6_0;
  db60 = renamed "db60" "db.v6_0" db.v6_0;
  db62 = renamed "db62" "db.v6_2" db.v6_2;
  docbook_xml_dtd_412 = renamed "docbook_xml_dtd_412" "docbook-xml-dtd.v4_1_2" docbook-xml-dtd.v4_1_2;
  docbook_xml_dtd_42 = renamed "docbook_xml_dtd_42" "docbook-xml-dtd.v4_2" docbook-xml-dtd.v4_2;
  docbook_xml_dtd_43 = renamed "docbook_xml_dtd_43" "docbook-xml-dtd.v4_3" docbook-xml-dtd.v4_3;
  docbook_xml_dtd_44 = renamed "docbook_xml_dtd_44" "docbook-xml-dtd.v4_4" docbook-xml-dtd.v4_4;
  docbook_xml_dtd_45 = renamed "docbook_xml_dtd_45" "docbook-xml-dtd.v4_5" docbook-xml-dtd.v4_5;
  elixir_1_17 = renamed "elixir_1_17" "elixir.v1_17" elixir.v1_17;
  elixir_1_18 = renamed "elixir_1_18" "elixir" elixir;
  ffmpeg-full = renamed "ffmpeg-full" "ffmpeg.full" ffmpeg.full;
  ffmpeg-headless = renamed "ffmpeg-headless" "ffmpeg.headless" ffmpeg.headless;
  ffmpeg_4 = renamed "ffmpeg_4" "ffmpeg.v4" ffmpeg.v4;
  ffmpeg_4-full = renamed "ffmpeg_4-full" "ffmpeg.v4.full" ffmpeg.v4.full;
  ffmpeg_4-headless = renamed "ffmpeg_4-headless" "ffmpeg.v4.headless" ffmpeg.v4.headless;
  ffmpeg_6 = renamed "ffmpeg_6" "ffmpeg.v4" ffmpeg.v4;
  ffmpeg_6-full = renamed "ffmpeg_6-full" "ffmpeg.v4.full" ffmpeg.v4.full;
  ffmpeg_6-headless = renamed "ffmpeg_6-headless" "ffmpeg.v4.headless" ffmpeg.v4.headless;
  ffmpeg_7 = renamed "ffmpeg_7" "ffmpeg.v4" ffmpeg.v4;
  ffmpeg_7-full = renamed "ffmpeg_7-full" "ffmpeg.v4.full" ffmpeg.v4.full;
  ffmpeg_7-headless = renamed "ffmpeg_7-headless" "ffmpeg.v4.headless" ffmpeg.v4.headless;
  ffmpeg_8 = renamed "ffmpeg_8" "ffmpeg.v4" ffmpeg.v4;
  ffmpeg_8-full = renamed "ffmpeg_8-full" "ffmpeg.v4.full" ffmpeg.v4.full;
  ffmpeg_8-headless = renamed "ffmpeg_8-headless" "ffmpeg.v4.headless" ffmpeg.v4.headless;
  fftwFloat = renamed "fftwFloat" "fftw.float" fftw.float;
  fftwLongDouble = renamed "fftwLongDouble" "fftw.long_double" fftw.long_double;
  fftwQuad = renamed "fftwQuad" "fftw.quad" fftw.quad;
  fftwSinglePrec = renamed "fftwSinglePrec" "fftw.float" fftw.float;
  flang = renamed "flang" "llvm.v20.pkgs.flang" llvm.v20.pkgs.flang;
  flang_20 = renamed "flang_20" "llvm.v20.pkgs.flang" llvm.v20.pkgs.flang;
  flang_21 = renamed "flang_21" "llvm.v21.pkgs.flang" llvm.v21.pkgs.flang;
  flex_2_5_39 = renamed "flex_2_5_39" "flex.v2_5" flex.v2_5;
  fuse3 = renamed "fuse3" "fuse" fuse;
  glfw = renamed "glfw" "glfw3" glfw3;
  gmp6 = renamed "gmp6" "gmp.v6_3" gmp.v6_3;
  gmpxx = renamed "gmpxx" "gmp.withCxx" gmp.withCxx;
  gnugrep = renamed "gnugrep" "grep" grep;
  gnum4 = renamed "gnum4" "m4" m4;
  gnumake = renamed "gnumake" "make" make;
  gnupatch = renamed "gnupatch" "patch" patch;
  gnused = renamed "gnused" "sed" sed;
  gnutar = renamed "gnutar" "tar" tar;
  go_1_24 = renamed "go_1_24" "go.v1_24" go.v1_24;
  go_1_25 = renamed "go_1_25" "go.v1_25" go.v1_25;
  gradle_7 = renamed "gradle_7" "gradle.v7" gradle.v7;
  gradle_8 = renamed "gradle_8" "gradle" gradle;
  gradle_9 = renamed "gradle_9" "gradle.v9" gradle.v9;
  gtk2 = throw "gtk2 has reached end of life. All consumers should migrate to gtk3+";
  guile_1_8 = renamed "guile_1_8" "guile.v1_8" guile.v1_8;
  guile_2_0 = renamed "guile_2_0" "guile.v2_0" guile.v2_0;
  guile_2_2 = renamed "guile_2_2" "guile.v2_2" guile.v2_2;
  guile_3_0 = renamed "guile_3_0" "guile.v3_0" guile.v3_0;
  icu60 = renamed "icu60" "icu.v60" icu.v60;
  icu63 = renamed "icu63" "icu.v63" icu.v63;
  icu64 = renamed "icu64" "icu.v64" icu.v64;
  icu66 = renamed "icu66" "icu.v66" icu.v66;
  icu67 = renamed "icu67" "icu.v67" icu.v67;
  icu69 = renamed "icu69" "icu.v69" icu.v69;
  icu70 = renamed "icu70" "icu.v70" icu.v70;
  icu71 = renamed "icu71" "icu.v71" icu.v71;
  icu72 = renamed "icu72" "icu.v72" icu.v72;
  icu73 = renamed "icu73" "icu.v73" icu.v73;
  icu74 = renamed "icu74" "icu.v74" icu.v74;
  icu75 = renamed "icu75" "icu.v75" icu.v75;
  icu76 = renamed "icu76" "icu.v76" icu.v76;
  icu77 = renamed "icu77" "icu.v77" icu.v77;
  icu78 = renamed "icu78" "icu.v78" icu.v78;
  igraph-c = renamed "igraph-c" "igraph" igraph;
  jdk = renamed "jdk" "java" java;
  jdk11 = renamed "jdk11" "java.v11" java.v11;
  jdk17 = renamed "jdk17" "java.v17" java.v17;
  jdk21 = renamed "jdk21" "java" java;
  kernelPackagesExtensions = throw "kernelPackagesExtensions has been removed in ekapkgs. Use config.overlays.linux instead";
  kotlinc = renamed "kotlinc" "kotlin" kotlin;
  libcIconv = libc: callPackage ../pkgs-many/libiconv/libc.nix { inherit libc; };
  libclang = renamed "libclang" "llvmPackages.libclang" llvmPackages.libclang;
  libclc = renamed "libclc" "llvmPackages.libclc" llvmPackages.libclc;
  libffiReal = renamed "libffiReal" "libffi.real" libffi.real;
  libffi_3_3 = renamed "libffi_3_3" "libffi.v3_3" libffi.v3_3;
  libiconv-darwin = renamed "libiconv-darwin" "libiconv.darwin" libiconv.darwin;
  libiconvReal = renamed "libiconvReal" "libiconv.real" libiconv.real;
  libidn2 = renamed "libidn2" "libidn.v2" libidn.v2;
  libllvm = renamed "libllvm" "llvmPackages.libllvm" llvmPackages.libllvm;
  libmpg123 = renamed "libmpg123" "mpg123" mpg123;
  libmysqlclient = renamed "libmysqlclient" "mariadb-connector-c" mariadb-connector-c;
  libnghttp2 = renamed "libnghttp2" "nghttp2" nghttp2;
  libtool2 = renamed "libtool2" "libtool.v2_5" libtool.v2_5;
  libtool_1_5 = renamed "libtool_1_5" "libtool.v1_5" libtool.v1_5;
  libxml2Python = throw "libxml2Python is deprecated, please migrate to libxml2 or something else";
  linuxPackages = renamed "linuxPackages" "linux.pkgs" linux.pkgs;
  linuxPackages_5_10 = renamed "linuxPackages_5_10" "linux.v5_10.pkgs" linux.v5_10.pkgs;
  linuxPackages_5_15 = renamed "linuxPackages_5_15" "linux.v5_15.pkgs" linux.v5_15.pkgs;
  linuxPackages_6_1 = renamed "linuxPackages_6_1" "linux.v6_1.pkgs" linux.v6_1.pkgs;
  linuxPackages_6_12 = renamed "linuxPackages_6_12" "linux.v6_12.pkgs" linux.v6_12.pkgs;
  linuxPackages_6_17 = renamed "linuxPackages_6_17" "linux.v6_17.pkgs" linux.v6_17.pkgs;
  linuxPackages_6_18 = renamed "linuxPackages_6_18" "linux.v6_18.pkgs" linux.v6_18.pkgs;
  linuxPackages_6_6 = renamed "linuxPackages_6_6" "linux.v6_6.pkgs" linux.v6_6.pkgs;
  linuxPackages_latest = renamed "linuxPackages_latest" "linux.v6_18.pkgs" linux.v6_18.pkgs;
  lld_18 = renamed "lld_18" "llvm.v18.pkgs.lld" llvm.v18.pkgs.lld;
  lld_19 = renamed "lld_19" "llvm.v19.pkgs.lld" llvm.v19.pkgs.lld;
  lld_20 = renamed "lld_20" "llvm.v20.pkgs.lld" llvm.v20.pkgs.lld;
  lld_21 = renamed "lld_21" "llvm.v21.pkgs.lld" llvm.v21.pkgs.lld;
  lldb = renamed "lldb" "llvmPackages.lldb" llvmPackages.lldb;
  lldb_18 = renamed "lldb_18" "llvm.v18.pkgs.lldb" llvm.v18.pkgs.lldb;
  lldb_19 = renamed "lldb_19" "llvm.v19.pkgs.lldb" llvm.v19.pkgs.lldb;
  lldb_20 = renamed "lldb_20" "llvm.v20.pkgs.lldb" llvm.v20.pkgs.lldb;
  lldb_21 = renamed "lldb_21" "llvm.v21.pkgs.lldb" llvm.v21.pkgs.lldb;
  llvm-manpages = renamed "llvm-manpages" "llvmPackages.llvm-manpages" llvmPackages.llvm-manpages;
  llvm_18 = renamed "llvm_18" "llvm.v18.pkgs.llvm" llvm.v18.pkgs.llvm;
  llvm_19 = renamed "llvm_19" "llvm.v19.pkgs.llvm" llvm.v19.pkgs.llvm;
  llvm_20 = renamed "llvm_20" "llvm.v20.pkgs.llvm" llvm.v20.pkgs.llvm;
  llvm_21 = renamed "llvm_21" "llvm.v21.pkgs.llvm" llvm.v21.pkgs.llvm;
  lttng-ust_2_12 = renamed "lttng-ust_2_12" "lttng-ust.v2_12" lttng-ust.v2_12;
  lua5_1 = renamed "lua5_1" "lua.v5_1" lua.v5_1;
  lua5_2 = renamed "lua5_2" "lua.v5_2" lua.v5_2;
  lua5_2_compat = renamed "lua5_2_compat" "lua.v5_2_compat" lua.v5_2_compat;
  lua5_3 = renamed "lua5_3" "lua.v5_3" lua.v5_3;
  lua5_3_compat = renamed "lua5_3_compat" "lua.v5_3_compat" lua.v5_3_compat;
  lua5_4 = renamed "lua5_4" "lua.v5_4" lua.v5_4;
  lua5_4_compat = renamed "lua5_4_compat" "lua.v5_4_compat" lua.v5_4_compat;
  lua5_5 = renamed "lua5_5" "lua.v5_5" lua.v5_5;
  lua5_5_compat = renamed "lua5_5_compat" "lua.v5_5_compat" lua.v5_5_compat;
  luajitPackages = renamed "luajitPackages" "lua.luajit_2_1.pkgs" lua.luajit_2_1.pkgs;
  luajit_2_0 = renamed "luajit_2_0" "lua.luajit_2_0" lua.luajit_2_0;
  luajit_2_1 = renamed "luajit_2_1" "lua.luajit_2_1" lua.luajit_2_1;
  luajit_openresty = renamed "luajit_openresty" "lua.luajit_openresty" lua.luajit_openresty;
  luarocks = renamed "luarocks" "luaPackages.luarocks_bootstrap" luaPackages.luarocks_bootstrap;
  makeInitrd = renamed "makeInitrd" "linux.makeInitrd" linux.makeInitrd;
  makeModulesClosure =
    renamed "makeModulesClosure" "linux.makeModulesClosure"
      linux.makeModulesClosure;
  man = renamed "man" "man-db" man-db;
  mdbook-linkcheck = throw "'mdbook-linkcheck' has been removed and replaced by 'mdbook-linkcheck2' due to incompatibility with mdbook version 0.5.0+";
  mtdutils = renamed "mtdutils" "mtd-utils" mtd-utils;
  ncurses5 = renamed "ncurses5" "ncurses.v5" ncurses.v5;
  ncurses6 = renamed "ncurses6" "ncurses.v6" ncurses.v6;
  nimble = renamed "nimble" "nim" nim;
  nixStatic = renamed "nixStatic" "pkgsStatic.nix" pkgsStatic.nix;
  nodejs_18 = renamed "nodejs_18" "nodejs.v18" nodejs.v18;
  nodejs_20 = renamed "nodejs_20" "nodejs.v20" nodejs.v20;
  nodejs_22 = renamed "nodejs_22" "nodejs.v22" nodejs.v22;
  nodejs_23 = renamed "nodejs_23" "nodejs.v23" nodejs.v23;
  nodejs_latest = renamed "nodejs_latest" "nodejs.v26" nodejs.v26;
  openjdk = renamed "openjdk" "java" java;
  openjdk11 = renamed "openjdk11" "java.v11" java.v11;
  openssl_1_1 = renamed "openssl_1_1" "openssl.v1_1" openssl.v1_1;
  openssl_oqs = renamed "openssl_oqs" "openssl.oqs" openssl.oqs;
  patchelfUnstable = throw "patchelfUnstable was removed because it was older than patchelf and unneeded, use patchelf instead";
  perl538 = renamed "perl538" "perl.v5_38" perl.v5_38;
  perl538Packages = renamed "perl538Packages" "perl.v5_38.pkgs" (
    lib.recurseIntoAttrs perl.v5_38.pkgs
  );
  perl540 = renamed "perl540" "perl.v5_40" perl.v5_40;
  perl540Packages = renamed "perl540Packages" "perl.v5_40.pkgs" (
    lib.recurseIntoAttrs perl.v5_40.pkgs
  );
  perl542 = renamed "perl542" "perl.v5_42" perl.v5_42;
  perl542Packages = renamed "perl542Packages" "perl.v5_42.pkgs" (
    lib.recurseIntoAttrs perl.v5_42.pkgs
  );
  phpExtensions = renamed "phpExtensions" "php.buildPecl" php.buildPecl;
  pypy27Packages = renamed "pypy27Packages" "pypy27.pkgs" pypy27.pkgs;
  pypy2Packages = renamed "pypy2Packages" "pypy2.pkgs" pypy2.pkgs;
  pypy310Packages = renamed "pypy310Packages" "pypy310.pkgs" pypy310.pkgs;
  pypy311Packages = renamed "pypy311Packages" "pypy311.pkgs" pypy311.pkgs;
  pypy3Packages = renamed "pypy3Packages" "pypy3.pkgs" pypy3.pkgs;
  pypyPackages = renamed "pypyPackages" "pypy.pkgs" pypy.pkgs;
  python27Packages = renamed "python27Packages" "python27.pkgs" python27.pkgs;
  python310Packages = renamed "python310Packages" "python310.pkgs" python310.pkgs;
  python311Packages = renamed "python311Packages" "python311.pkgs" python311.pkgs;
  python314Packages = renamed "python314Packages" "python314.pkgs" python314.pkgs;
  python315Packages = renamed "python315Packages" "python315.pkgs" python315.pkgs;
  qemu-utils = renamed "qemu-utils" "qemu" qemu;
  r = renamed "r" "r-lang" r-lang;
  rLang = renamed "rLang" "r-lang" r-lang;
  scala_2_13 = renamed "scala_2_13" "scala.v2_13" scala.v2_13;
  scala_3 = renamed "scala_3" "scala" scala;
  strip-nondeterminism =
    renamed "strip-nondeterminism" "perlPackages.strip-nondeterminism"
      perlPackages.strip-nondeterminism;
  su = renamed "su" "shadow" shadow;
  tcl-8_5 = renamed "tcl-8_5" "tcl.v8_5" tcl.v8_5;
  tcl-8_6 = renamed "tcl-8_6" "tcl.v8_6" tcl.v8_6;
  tcl-9_0 = renamed "tcl-9_0" "tcl.v9_0" tcl.v9_0;
  tclPackages = renamed "tclPackages" "tcl.pkgs" tcl.pkgs;
  texinfo6 = renamed "texinfo6" "texinfo.v6" texinfo.v6;
  texinfo7 = renamed "texinfo7" "texinfo.v7" texinfo.v7;
  texinfoInteractive = renamed "texinfoInteractive" "texinfo.interactive" texinfo.interactive;
  tk-8_5 = renamed "tk-8_5" "tk.v8_5" tk.v8_5;
  tk-8_6 = renamed "tk-8_6" "tk.v8_6" tk.v8_6;
  tk-9_0 = renamed "tk-9_0" "tk.v9_0" tk.v9_0;
  ubootA20OlinuxinoLime =
    renamed "ubootA20OlinuxinoLime" "uboot.ubootA20OlinuxinoLime"
      uboot.ubootA20OlinuxinoLime;
  ubootA20OlinuxinoLime2EMMC =
    renamed "ubootA20OlinuxinoLime2EMMC" "uboot.ubootA20OlinuxinoLime2EMMC"
      uboot.ubootA20OlinuxinoLime2EMMC;
  ubootAmx335xEVM = renamed "ubootAmx335xEVM" "uboot.ubootAmx335xEVM" uboot.ubootAmx335xEVM;
  ubootBananaPi = renamed "ubootBananaPi" "uboot.ubootBananaPi" uboot.ubootBananaPi;
  ubootBananaPim2Zero =
    renamed "ubootBananaPim2Zero" "uboot.ubootBananaPim2Zero"
      uboot.ubootBananaPim2Zero;
  ubootBananaPim3 = renamed "ubootBananaPim3" "uboot.ubootBananaPim3" uboot.ubootBananaPim3;
  ubootBananaPim64 = renamed "ubootBananaPim64" "uboot.ubootBananaPim64" uboot.ubootBananaPim64;
  ubootCM3588NAS = renamed "ubootCM3588NAS" "uboot.ubootCM3588NAS" uboot.ubootCM3588NAS;
  ubootClearfog = renamed "ubootClearfog" "uboot.ubootClearfog" uboot.ubootClearfog;
  ubootCubieboard2 = renamed "ubootCubieboard2" "uboot.ubootCubieboard2" uboot.ubootCubieboard2;
  ubootGuruplug = renamed "ubootGuruplug" "uboot.ubootGuruplug" uboot.ubootGuruplug;
  ubootJetsonTK1 = renamed "ubootJetsonTK1" "uboot.ubootJetsonTK1" uboot.ubootJetsonTK1;
  ubootLibreTechCC = renamed "ubootLibreTechCC" "uboot.ubootLibreTechCC" uboot.ubootLibreTechCC;
  ubootNanoPCT4 = renamed "ubootNanoPCT4" "uboot.ubootNanoPCT4" uboot.ubootNanoPCT4;
  ubootNanoPCT6 = renamed "ubootNanoPCT6" "uboot.ubootNanoPCT6" uboot.ubootNanoPCT6;
  ubootNanoPiR5S = renamed "ubootNanoPiR5S" "uboot.ubootNanoPiR5S" uboot.ubootNanoPiR5S;
  ubootNovena = renamed "ubootNovena" "uboot.ubootNovena" uboot.ubootNovena;
  ubootOdroidC2 = renamed "ubootOdroidC2" "uboot.ubootOdroidC2" uboot.ubootOdroidC2;
  ubootOdroidXU3 = renamed "ubootOdroidXU3" "uboot.ubootOdroidXU3" uboot.ubootOdroidXU3;
  ubootOlimexA64Olinuxino =
    renamed "ubootOlimexA64Olinuxino" "uboot.ubootOlimexA64Olinuxino"
      uboot.ubootOlimexA64Olinuxino;
  ubootOlimexA64Teres1 =
    renamed "ubootOlimexA64Teres1" "uboot.ubootOlimexA64Teres1"
      uboot.ubootOlimexA64Teres1;
  ubootOrangePi3 = renamed "ubootOrangePi3" "uboot.ubootOrangePi3" uboot.ubootOrangePi3;
  ubootOrangePi3B = renamed "ubootOrangePi3B" "uboot.ubootOrangePi3B" uboot.ubootOrangePi3B;
  ubootOrangePi5 = renamed "ubootOrangePi5" "uboot.ubootOrangePi5" uboot.ubootOrangePi5;
  ubootOrangePi5Max = renamed "ubootOrangePi5Max" "uboot.ubootOrangePi5Max" uboot.ubootOrangePi5Max;
  ubootOrangePi5Plus =
    renamed "ubootOrangePi5Plus" "uboot.ubootOrangePi5Plus"
      uboot.ubootOrangePi5Plus;
  ubootOrangePiPc = renamed "ubootOrangePiPc" "uboot.ubootOrangePiPc" uboot.ubootOrangePiPc;
  ubootOrangePiZero = renamed "ubootOrangePiZero" "uboot.ubootOrangePiZero" uboot.ubootOrangePiZero;
  ubootOrangePiZero2 =
    renamed "ubootOrangePiZero2" "uboot.ubootOrangePiZero2"
      uboot.ubootOrangePiZero2;
  ubootOrangePiZero3 =
    renamed "ubootOrangePiZero3" "uboot.ubootOrangePiZero3"
      uboot.ubootOrangePiZero3;
  ubootOrangePiZeroPlus2H5 =
    renamed "ubootOrangePiZeroPlus2H5" "uboot.ubootOrangePiZeroPlus2H5"
      uboot.ubootOrangePiZeroPlus2H5;
  ubootPcduino3Nano = renamed "ubootPcduino3Nano" "uboot.ubootPcduino3Nano" uboot.ubootPcduino3Nano;
  ubootPine64 = renamed "ubootPine64" "uboot.ubootPine64" uboot.ubootPine64;
  ubootPine64LTS = renamed "ubootPine64LTS" "uboot.ubootPine64LTS" uboot.ubootPine64LTS;
  ubootPinebook = renamed "ubootPinebook" "uboot.ubootPinebook" uboot.ubootPinebook;
  ubootPinebookPro = renamed "ubootPinebookPro" "uboot.ubootPinebookPro" uboot.ubootPinebookPro;
  ubootQemuAarch64 = renamed "ubootQemuAarch64" "uboot.ubootQemuAarch64" uboot.ubootQemuAarch64;
  ubootQemuArm = renamed "ubootQemuArm" "uboot.ubootQemuArm" uboot.ubootQemuArm;
  ubootQemuRiscv64Smode =
    renamed "ubootQemuRiscv64Smode" "uboot.ubootQemuRiscv64Smode"
      uboot.ubootQemuRiscv64Smode;
  ubootQemuX86 = renamed "ubootQemuX86" "uboot.ubootQemuX86" uboot.ubootQemuX86;
  ubootQemuX86_64 = renamed "ubootQemuX86_64" "uboot.ubootQemuX86_64" uboot.ubootQemuX86_64;
  ubootQuartz64B = renamed "ubootQuartz64B" "uboot.ubootQuartz64B" uboot.ubootQuartz64B;
  ubootROCPCRK3399 = renamed "ubootROCPCRK3399" "uboot.ubootROCPCRK3399" uboot.ubootROCPCRK3399;
  ubootRadxaZero3W = renamed "ubootRadxaZero3W" "uboot.ubootRadxaZero3W" uboot.ubootRadxaZero3W;
  ubootRaspberryPi = renamed "ubootRaspberryPi" "uboot.ubootRaspberryPi" uboot.ubootRaspberryPi;
  ubootRaspberryPi2 = renamed "ubootRaspberryPi2" "uboot.ubootRaspberryPi2" uboot.ubootRaspberryPi2;
  ubootRaspberryPi3_32bit =
    renamed "ubootRaspberryPi3_32bit" "uboot.ubootRaspberryPi3_32bit"
      uboot.ubootRaspberryPi3_32bit;
  ubootRaspberryPi3_64bit =
    renamed "ubootRaspberryPi3_64bit" "uboot.ubootRaspberryPi3_64bit"
      uboot.ubootRaspberryPi3_64bit;
  ubootRaspberryPi4_32bit =
    renamed "ubootRaspberryPi4_32bit" "uboot.ubootRaspberryPi4_32bit"
      uboot.ubootRaspberryPi4_32bit;
  ubootRaspberryPi4_64bit =
    renamed "ubootRaspberryPi4_64bit" "uboot.ubootRaspberryPi4_64bit"
      uboot.ubootRaspberryPi4_64bit;
  ubootRaspberryPiZero =
    renamed "ubootRaspberryPiZero" "uboot.ubootRaspberryPiZero"
      uboot.ubootRaspberryPiZero;
  ubootRock4CPlus = renamed "ubootRock4CPlus" "uboot.ubootRock4CPlus" uboot.ubootRock4CPlus;
  ubootRock5ModelB = renamed "ubootRock5ModelB" "uboot.ubootRock5ModelB" uboot.ubootRock5ModelB;
  ubootRock64 = renamed "ubootRock64" "uboot.ubootRock64" uboot.ubootRock64;
  ubootRock64v2 = renamed "ubootRock64v2" "uboot.ubootRock64v2" uboot.ubootRock64v2;
  ubootRockPi4 = renamed "ubootRockPi4" "uboot.ubootRockPi4" uboot.ubootRockPi4;
  ubootRockPiE = renamed "ubootRockPiE" "uboot.ubootRockPiE" uboot.ubootRockPiE;
  ubootRockPro64 = renamed "ubootRockPro64" "uboot.ubootRockPro64" uboot.ubootRockPro64;
  ubootSheevaplug = renamed "ubootSheevaplug" "uboot.ubootSheevaplug" uboot.ubootSheevaplug;
  ubootSopine = renamed "ubootSopine" "uboot.ubootSopine" uboot.ubootSopine;
  ubootTools = renamed "ubootTools" "uboot.tools" uboot.tools;
  ubootTuringRK1 = renamed "ubootTuringRK1" "uboot.ubootTuringRK1" uboot.ubootTuringRK1;
  ubootUtilite = renamed "ubootUtilite" "uboot.ubootUtilite" uboot.ubootUtilite;
  ubootVisionFive2 = renamed "ubootVisionFive2" "uboot.ubootVisionFive2" uboot.ubootVisionFive2;
  ubootWandboard = renamed "ubootWandboard" "uboot.ubootWandboard" uboot.ubootWandboard;
  valgrind-light = renamed "valgrind-light" "valgrind.light" valgrind.light;
  wafHook = renamed "wafHook" "waf.hook" waf.hook;
  webrtc-audio-processing_0_3 =
    renamed "webrtc-audio-processing_0_3" "webrtc-audio-processing.v0_3"
      webrtc-audio-processing.v0_3;
  webrtc-audio-processing_1 =
    renamed "webrtc-audio-processing_1" "webrtc-audio-processing.v1"
      webrtc-audio-processing.v1;
  webrtc-audio-processing_2 =
    renamed "webrtc-audio-processing_2" "webrtc-audio-processing.v2"
      webrtc-audio-processing.v2;
  wlroots_0_17 = renamed "wlroots_0_17" "wlroots.v0_17" wlroots.v0_17;
  wlroots_0_18 = renamed "wlroots_0_18" "wlroots.v0_18" wlroots.v0_18;
  wlroots_0_19 = renamed "wlroots_0_19" "wlroots.v0_19" wlroots.v0_19;
  wrapGAppsHook3 = renamed "wrapGAppsHook3" "gtk3.wrapGAppsHook" gtk3.wrapGAppsHook;
  wrapGAppsHook4 = renamed "wrapGAppsHook4" "gtk4.wrapGAppsHook" gtk4.wrapGAppsHook;
  wrapGAppsNoGuiHook = renamed "wrapGAppsNoGuiHook" "gtk3.wrapGAppsNoGuiHook" gtk3.wrapGAppsNoGuiHook;
  wrapRustc = renamed "wrapRustc" "rustPackages.wrapRustc" rustPackages.wrapRustc;
  wrapRustcWith = renamed "wrapRustcWith" "rustPackages.wrapRustcWith" rustPackages.wrapRustcWith;
  xcodebuild = renamed "xcodebuild" "xcbuild" xcbuild;
  xorriso = renamed "xorriso" "libisoburn" libisoburn;
  xxHash = renamed "xxHash" "xxhash" xxhash;
  # keep-sorted end

  gst_all_1 = lib.warn "'gst_all_1' has been renamed to 'gstreamer' in ekapkgs" {
    inherit gstreamer;
    gst-plugins-base = gstreamer.plugins-base;
    gst-plugins-good = gstreamer.plugins-good;
    gst-plugins-bad = gstreamer.plugins-bad;
    gst-plugins-ugly = gstreamer.plugins-ugly;
    gst-rtsp-server = gstreamer.rtsp-server;
    gst-libav = gstreamer.libav;
    gst-devtools = gstreamer.devtools;
    gst-editing-services = gstreamer.editing-services;
  };
}
