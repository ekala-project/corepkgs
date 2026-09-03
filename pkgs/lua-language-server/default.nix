# lua-language-server — Language server for Lua
{
  lib,
  stdenv,
  fetchFromGitHub,
  ninja,
  makeWrapper,
  fmt,
  libbfd,
  libunwind,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lua-language-server";
  version = "3.19.1";

  src = fetchFromGitHub {
    owner = "luals";
    repo = "lua-language-server";
    tag = finalAttrs.version;
    hash = "sha256-3Sm958Fr5wn54B+aJMaK+cR/F10dPIcGvBrhjHTy2us=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    ninja
    makeWrapper
  ];

  buildInputs = [
    fmt
    libbfd
    libunwind
  ];

  env.NIX_LDFLAGS = "-lfmt";

  postPatch = ''
    # filewatch tests are failing on darwin
    substituteInPlace 3rd/bee.lua/test/test.lua \
      --replace-fail 'require "test_filewatch"' ""

    # use system fmt library
    for d in 3rd/bee.lua 3rd/luamake/bee.lua
    do
      rm -r $d/3rd/fmt/*
      touch $d/3rd/fmt/format.cc
      substituteInPlace $d/bee/nonstd/format.h $d/bee/nonstd/print.h \
        --replace-fail "include <3rd/fmt/fmt" "include <fmt"
    done

    # flaky tests on linux
    substituteInPlace test/tclient/init.lua \
      --replace-fail "require 'tclient.tests.load-relative-library'" ""

    pushd 3rd/luamake
  '';

  ninjaFlags = [
    "-fcompile/ninja/${if stdenv.hostPlatform.isDarwin then "macos" else "linux"}.ninja"
  ];

  postBuild = ''
    popd
    ./3rd/luamake/luamake rebuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dt "$out"/share/lua-language-server/bin bin/lua-language-server
    install -m644 -t "$out"/share/lua-language-server/bin bin/*.*
    install -m644 -t "$out"/share/lua-language-server {debugger,main}.lua
    cp -r locale meta script "$out"/share/lua-language-server

    # necessary for --version to work:
    install -m644 -t "$out"/share/lua-language-server changelog.md

    makeWrapper "$out"/share/lua-language-server/bin/lua-language-server \
      $out/bin/lua-language-server \
      --add-flags "-E $out/share/lua-language-server/main.lua \
      --logpath=\''${XDG_CACHE_HOME:-\$HOME/.cache}/lua-language-server/log \
      --metapath=\''${XDG_CACHE_HOME:-\$HOME/.cache}/lua-language-server/meta"

    runHook postInstall
  '';

  meta = {
    description = "Language server that offers Lua language support";
    homepage = "https://github.com/luals/lua-language-server";
    license = lib.licenses.mit;
    mainProgram = "lua-language-server";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
