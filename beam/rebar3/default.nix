{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchHex,
  erlang,
  makeWrapper,
  writableTmpDirAsHomeHook,
  rebar3-nix,
}:

let
  deps = import ./rebar-deps.nix {
    inherit fetchFromGitHub fetchHex;
    fetchgit = throw "rebar3: fetchgit deps not needed";
  };
  rebar3 = stdenv.mkDerivation (finalAttrs: {
    pname = "rebar3";
    version = "3.27.0";

    src = fetchFromGitHub {
      owner = "erlang";
      repo = "rebar3";
      tag = finalAttrs.version;
      sha256 = "+va3wHlAfVtl3aK6+DVkN/EgpiMxwAGUyNywaWiKTJQ=";
    };

    nativeBuildInputs = [
      erlang
      writableTmpDirAsHomeHook
    ];

    buildInputs = [ erlang ];

    postPatch = ''
      mkdir -p _checkouts _build/default/lib/

      ${toString (
        lib.mapAttrsToList (k: v: ''
          cp -R --no-preserve=mode ${v} _checkouts/${k}
        '') deps
      )}

      # Bootstrap script expects the dependencies in _build/default/lib
      for i in _checkouts/* ; do
          ln -s $(pwd)/$i $(pwd)/_build/default/lib/
      done
    '';

    buildPhase = ''
      runHook preBuild

      escript bootstrap

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp rebar3 $out/bin/rebar3

      runHook postInstall
    '';

    meta = {
      homepage = "https://github.com/erlang/rebar3";
      changelog = "https://github.com/erlang/rebar3/releases/tag/${finalAttrs.version}";
      description = "Erlang build tool that makes it easy to compile and test Erlang applications, port drivers and releases";
      mainProgram = "rebar3";
      platforms = lib.platforms.unix;
      license = lib.licenses.asl20;
    };
  });

  # Alias rebar3 so we can use it as default parameter below
  _rebar3 = rebar3;

  rebar3WithPlugins =
    {
      plugins ? [ ],
      globalPlugins ? [ ],
      rebar3 ? _rebar3,
    }:
    let
      pluginLibDirs = map (p: "${p}/lib/erlang/lib") (lib.unique (plugins ++ globalPlugins));
      globalPluginNames = lib.unique (map (p: p.pname) globalPlugins);
      rebar3Patched = (
        rebar3.overrideAttrs (old: {
          patches = [
            ./skip-plugins.patch
            ./global-plugins.patch
          ];

          # our patches cause the tests to fail
          doCheck = false;
        })
      );
    in
    stdenv.mkDerivation {
      pname = "rebar3-with-plugins";
      inherit (rebar3) version;
      nativeBuildInputs = [
        erlang
        makeWrapper
      ];
      unpackPhase = "true";

      installPhase = ''
        erl -noshell -eval '
          {ok, Escript} = escript:extract("${rebar3Patched}/bin/rebar3", []),
          {archive, Archive} = lists:keyfind(archive, 1, Escript),
          {ok, _} = zip:extract(Archive, [{cwd, "'$out/lib'"}]),
          init:stop(0)
        '
        cp ${./rebar_ignore_deps.erl} rebar_ignore_deps.erl
        erlc -o $out/lib/rebar/ebin rebar_ignore_deps.erl
        mkdir -p $out/bin
        makeWrapper ${erlang}/bin/erl $out/bin/rebar3 \
          --set REBAR_GLOBAL_PLUGINS "${toString globalPluginNames} rebar_ignore_deps" \
          --suffix-each ERL_LIBS ":" "$out/lib ${toString pluginLibDirs}" \
          --add-flags "+sbtu +A1 -noshell -boot start_clean -s rebar3 main -extra"
      '';
    };
in
{
  inherit rebar3 rebar3WithPlugins;
}
