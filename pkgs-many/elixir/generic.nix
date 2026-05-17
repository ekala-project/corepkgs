{
  version,
  src-hash,
  minimumOTPVersion,
  ...
}:

{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  erlang,
  coreutils,
  curl,
  bash,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "elixir";
  inherit version;

  src = fetchurl {
    url = "https://github.com/elixir-lang/elixir/archive/v${version}.tar.gz";
    hash = src-hash;
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = [
    erlang
  ];

  env = {
    LANG = "C.UTF-8";
    LC_TYPE = "C.UTF-8";
    DESTDIR = placeholder "out";
    PREFIX = "/";
    ERL_COMPILER_OPTIONS = "[deterministic]";
  };

  preBuild = ''
    patchShebangs lib/elixir/scripts/generate_app.escript || true
  '';

  # Disable parallel builds to avoid issues
  enableParallelBuilding = false;

  # copy stdlib source files for LSP access
  postInstall = ''
    for d in lib/*; do
      cp -R "$d/lib" "$out/lib/elixir/$d"
    done
  '';

  postFixup = ''
    # Elixir binaries are shell scripts which run erl. Add some stuff
    # to PATH so the scripts can run without problems.

    for f in $out/bin/*; do
      b=$(basename $f)
      if [ "$b" = mix ]; then continue; fi
      wrapProgram $f \
        --prefix PATH ":" "${
          lib.makeBinPath [
            erlang
            coreutils
            curl
            bash
          ]
        }"
    done

    substituteInPlace $out/bin/mix \
      --replace-warn "/usr/bin/env elixir" "$out/bin/elixir"
  '';

  passthru = {
    inherit erlang;
    majorVersion = lib.versions.major version;
    minorVersion = lib.versions.majorMinor version;
  };

  meta = {
    description = "Functional, concurrent, general-purpose programming language that runs on the BEAM VM";
    homepage = "https://elixir-lang.org/";
    changelog = "https://github.com/elixir-lang/elixir/releases/tag/v${version}";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix ++ lib.platforms.darwin;
    mainProgram = "elixir";
    maintainers = [ ];
  };
})
