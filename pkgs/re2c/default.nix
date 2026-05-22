{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  nix-update-script,
  python3,

  # for passthru.tests
  ninja,
  php,
  spamassassin,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "re2c";
  version = "4.3";

  src = fetchFromGitHub {
    owner = "skvadrik";
    repo = "re2c";
    rev = finalAttrs.version;
    hash = "sha256-zPOENMfXXgTwds1t+Lrmz9+GTHJf2yRpQsGT7nLRvcg=";
  };

  nativeBuildInputs = [
    autoreconfHook
    python3
  ];

  doCheck = false;
  enableParallelBuilding = true;

  preCheck = ''
    patchShebangs run_tests.py
  '';

  passthru = {
    updateScript = nix-update-script {
      # Skip non-release tags like `python-experimental`.
      extraArgs = [
        "--version-regex"
        "([0-9.]+)"
      ];
    };
    tests = {
      unit = finalAttrs.finalPackage.overrideAttrs { doCheck = true; };
      inherit ninja php spamassassin;
    };
  };

  meta = {
    description = "Tool for writing very fast and very flexible scanners";
    homepage = "https://re2c.org";
    license = lib.licenses.publicDomain;
    platforms = lib.platforms.all;
  };
})
