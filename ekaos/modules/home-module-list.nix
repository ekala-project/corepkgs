# Modules for standalone home evaluation (no system dependencies)
#
# This list is used by eval-home.nix and contains only modules
# needed for per-user home configuration. No boot, kernel,
# networking, or system activation modules are included.
[
  # Home configuration
  ./home/options.nix
  ./home/build.nix

  # Stubs for options that language modules write to in system context
  ./home/language-stubs.nix

  # Per-user program modules
  ./home/programs/bash.nix
  ./home/programs/git.nix
  ./home/programs/ssh.nix
  ./home/programs/gpg-agent.nix

  # Assertions (home-compatible version)
  ./misc/assertions-home.nix

  # Language modules (write to home.users.<name>.languages)
  ./languages/bun.nix
  ./languages/c.nix
  ./languages/clojure.nix
  ./languages/cplusplus.nix
  ./languages/crystal.nix
  ./languages/cue.nix
  ./languages/deno.nix
  ./languages/dotnet.nix
  ./languages/elixir.nix
  ./languages/erlang.nix
  ./languages/fortran.nix
  ./languages/gawk.nix
  ./languages/gleam.nix
  ./languages/go.nix
  ./languages/guile.nix
  ./languages/hare.nix
  ./languages/haskell.nix
  ./languages/idris.nix
  ./languages/java.nix
  ./languages/javascript.nix
  ./languages/jsonnet.nix
  ./languages/julia.nix
  ./languages/kotlin.nix
  ./languages/lobster.nix
  ./languages/lean.nix
  ./languages/lua.nix
  ./languages/nim.nix
  ./languages/nix.nix
  ./languages/nodejs.nix
  ./languages/ocaml.nix
  ./languages/odin.nix
  ./languages/opentofu.nix
  ./languages/perl.nix
  ./languages/php.nix
  ./languages/pkl.nix
  ./languages/purescript.nix
  ./languages/python.nix
  ./languages/racket.nix
  ./languages/raku.nix
  ./languages/r-lang.nix
  ./languages/ruby.nix
  ./languages/rust.nix
  ./languages/scala.nix
  ./languages/shell.nix
  ./languages/sml.nix
  ./languages/solidity.nix
  ./languages/tcl.nix
  ./languages/terraform.nix
  ./languages/texlive.nix
  ./languages/typst.nix
  ./languages/typescript.nix
  ./languages/unison.nix
  ./languages/vala.nix
  ./languages/vlang.nix
  ./languages/zig.nix
]
