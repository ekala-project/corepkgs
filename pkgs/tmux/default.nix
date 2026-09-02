# tmux — terminal multiplexer
{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  bison,
  libevent,
  ncurses,
  pkg-config,
  runCommand,
  withSystemd ? lib.meta.availableOn stdenv.hostPlatform systemdLibs,
  systemdLibs,
  withUtf8proc ? !(stdenv.hostPlatform.is32bit),
  utf8proc,
  # TODO: add libutempter to core-pkgs
  withUtempter ? false,
  libutempter ? null,
  withSixel ? true,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "tmux";
  version = "3.7c";

  strictDeps = true;

  outputs = [
    "out"
    "man"
  ];

  src = fetchFromGitHub {
    owner = "tmux";
    repo = "tmux";
    tag = finalAttrs.version;
    hash = "sha256-TpZXTeXKQv6MV1vAPu5MIT52d3Pl6dYcOReZa7QANZY=";
  };

  nativeBuildInputs = [
    pkg-config
    autoreconfHook
    bison
  ];

  buildInputs = [
    ncurses
    libevent
  ]
  ++ lib.optionals withSystemd [ systemdLibs ]
  ++ lib.optionals withUtf8proc [ utf8proc ]
  ++ lib.optionals (withUtempter && libutempter != null) [ libutempter ];

  configureFlags = [
    "--sysconfdir=/etc"
    "--localstatedir=/var"
  ]
  ++ lib.optionals withSystemd [ "--enable-systemd" ]
  ++ lib.optionals withSixel [ "--enable-sixel" ]
  ++ lib.optionals (withUtempter && libutempter != null) [ "--enable-utempter" ]
  ++ lib.optionals withUtf8proc [ "--enable-utf8proc" ];

  enableParallelBuilding = true;

  passthru.terminfo = runCommand "tmux-terminfo" { nativeBuildInputs = [ ncurses ]; } ''
    mkdir -p $out/share/terminfo/t
    ln -sv ${ncurses}/share/terminfo/t/{tmux,tmux-256color,tmux-direct} $out/share/terminfo/t
  '';

  meta = {
    homepage = "https://tmux.github.io/";
    description = "Terminal multiplexer";
    changelog = "https://github.com/tmux/tmux/raw/${finalAttrs.version}/CHANGES";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
    mainProgram = "tmux";
  };
})
