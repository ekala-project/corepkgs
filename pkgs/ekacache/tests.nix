# Each test starts a private ecd inside the build sandbox, compiles the same
# input twice and checks ec's per-compile log: the first run must store a
# result, the second must replay it. The cc and rustc tests go through the
# corepkgs wrappers with `compilerLauncher` set, as `config.ekacache.enable`
# does.
{
  lib,
  runCommand,
  runCommandWith,
  stdenv,
  overrideCC,
  rustPackages,
  go,
  ekacache,
}:

let
  cc = stdenv.cc.override { compilerLauncher = ekacache; };
  rustc = rustPackages.wrapRustcWith {
    rustc-unwrapped = rustPackages.rustc.unwrapped;
    compilerLauncher = ekacache;
  };

  # Starts ecd on $TMPDIR/ecd/sock and points ec at it and at $TMPDIR/ec.log.
  # `expectLog <line> <tool> <outcome>` checks one row of that log. The
  # sandbox kills ecd when the build ends.
  withEcd = ''
    mkdir -p "$TMPDIR/ecd"
    XDG_CACHE_HOME="$TMPDIR/ecd/cache" ${lib.getExe' ekacache.ekacached "ecd"} "$TMPDIR/ecd/sock" \
      2>"$TMPDIR/ecd/log" &
    for _ in $(seq 100); do
      [[ -S $TMPDIR/ecd/sock ]] && break
      sleep 0.1
    done
    if [[ ! -S $TMPDIR/ecd/sock ]]; then
      echo "ecd did not start:" >&2
      cat "$TMPDIR/ecd/log" >&2
      exit 1
    fi
    export EKACACHE_SOCK=$TMPDIR/ecd/sock EKACACHE_LOG=$TMPDIR/ec.log

    expectLog() {
      local row
      row=$(sed -n "$1p" "$EKACACHE_LOG" | cut -f1,2)
      if [[ $row != "$2"$'\t'"$3" ]]; then
        echo "line $1 of the ec log: expected '$2 $3', got '$row'" >&2
        cat "$EKACACHE_LOG" >&2
        exit 1
      fi
    }
  '';
in
{
  # The flags cc-wrapper adds are part of the key: the same flags hit, a
  # changed NIX_CFLAGS_COMPILE misses.
  cc-wrapper =
    runCommandWith
      {
        name = "ekacache-test-cc-wrapper";
        stdenv = overrideCC stdenv cc;
      }
      ''
        ${withEcd}
        grep -qF ${lib.escapeShellArg "exec ${lib.getExe ekacache} "} ${cc}/bin/cc
        printf 'int f(int x) { return x * 2; }\n' > a.c
        for run in 1 2; do
          cc -O2 -c a.c -o a$run.o
        done
        cmp a1.o a2.o
        export NIX_CFLAGS_COMPILE_${cc.suffixSalt}+=" -DEKACACHE_TEST"
        cc -O2 -c a.c -o a3.o
        expectLog 1 cc compiled
        expectLog 2 cc cached
        expectLog 3 cc compiled
        touch $out
      '';

  rustc-wrapper = runCommand "ekacache-test-rustc-wrapper" { } ''
    ${withEcd}
    grep -qF ${lib.escapeShellArg "exec ${lib.getExe ekacache} "} ${rustc}/bin/rustc
    printf 'pub fn f(x: u32) -> u32 { x * 2 }\n' > lib.rs
    for run in 1 2; do
      mkdir out$run
      ${rustc}/bin/rustc --edition=2021 --crate-type=lib --crate-name=ekacache_test \
        --emit=dep-info,metadata,link --out-dir out$run lib.rs
    done
    cmp out1/libekacache_test.rlib out2/libekacache_test.rlib
    expectLog 1 rustc compiled
    expectLog 2 rustc cached
    touch $out
  '';

  gocacheprog =
    runCommand "ekacache-test-gocacheprog"
      {
        nativeBuildInputs = [ go ];
        env.CGO_ENABLED = "0";
      }
      ''
        ${withEcd}
        export GOCACHEPROG=${ekacache}/libexec/ekacache/gocacheprog
        export HOME=$TMPDIR GOFLAGS=-trimpath GOTOOLCHAIN=local
        mkdir hello && cd hello
        printf 'module example.com/hello\n\ngo 1.24\n' > go.mod
        printf 'package main\n\nfunc main() { println("hello") }\n' > main.go
        for run in 1 2; do
          GOCACHEPROG_DIR=$TMPDIR/gocacheprog$run go build -o hello$run .
        done
        cmp hello1 hello2
        grep -q $'^go\tcompiled\t' "$EKACACHE_LOG"
        grep -q $'^go\tcached\t' "$EKACACHE_LOG"
        touch $out
      '';
}
