{
  lib,
  stdenv,
  makeWrapper,
  coreutils,
  diffutils,
  git,
  grep,
  sed,
  jq,
  nix,
  python3Packages,
}:

stdenv.mkDerivation {
  name = "common-updater-scripts";

  nativeBuildInputs = [
    makeWrapper
    python3Packages.wrapPython
  ];

  pythonPath = [
    python3Packages.beautifulsoup4
    python3Packages.requests
  ];

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp ${./scripts}/* $out/bin

    # wrap non python scripts
    for f in $out/bin/*; do
      if ! (head -n1 "$f" | grep -q '#!.*/env.*\(python\|pypy\)'); then
        wrapProgram $f --prefix PATH : ${
          lib.makeBinPath [
            coreutils
            diffutils
            git
            grep
            sed
            jq
            nix
          ]
        }
      fi
    done

    # wrap python scripts
    makeWrapperArgs+=( --prefix PATH : "${lib.makeBinPath [ nix ]}" )
    wrapPythonPrograms
  '';

  meta = {
    description = "Common scripts for automatically updating package sources";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
