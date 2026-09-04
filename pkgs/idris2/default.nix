# Idris2 — dependently typed programming language
#
# Simplified port: builds the compiler and runtime support library.
# Does not include the full prelude scope from nixpkgs.
{
  lib,
  stdenv,
  fetchFromGitHub,
  chez,
  clang,
  gmp,
  makeBinaryWrapper,
  symlinkJoin,
}:

let
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "idris-lang";
    repo = "Idris2";
    rev = "v${version}";
    hash = "sha256-MvFNSPpgONSTjACH3HGWEiNgz9aAeBPmyQwFe21+fe0=";
  };

  inherit (stdenv.hostPlatform) extensions;

  # Runtime support library (C)
  libidris2_support = stdenv.mkDerivation {
    pname = "libidris2_support";
    inherit version src;

    strictDeps = true;
    buildInputs = [ gmp ];
    enableParallelBuilding = true;

    makeFlags = [
      "PREFIX=${placeholder "out"}"
    ];

    buildFlags = [ "support" ];
    installTargets = "install-support";

    postInstall = ''
      mv "$out/idris2-${version}/lib" "$out/lib"
      mv "$out/idris2-${version}/support" "$out/share"
      rm -rf $out/idris2-${version}
    '';

    meta.description = "Runtime library for Idris2";
  };

  libsupportLib = lib.makeLibraryPath [ libidris2_support ];
  libsupportShare = lib.makeSearchPath "share" [ libidris2_support ];

  # The compiler itself
  idris2-unwrapped = stdenv.mkDerivation {
    pname = "idris2";
    inherit version src;

    postPatch = ''
      shopt -s globstar

      substituteInPlace **/*.idr \
        --replace-quiet "libidris2_support" "${libidris2_support}/lib/libidris2_support${extensions.sharedLibrary}"

      substituteInPlace src/Compiler/RefC/CC.idr \
        --replace-fail "libidris2_support${extensions.sharedLibrary}.a" "libidris2_support.a"

      substituteInPlace bootstrap-stage2.sh \
        --replace-fail "MAKE all" "MAKE idris2-exec"

      patchShebangs --build tests
    '';

    strictDeps = true;
    nativeBuildInputs = [
      clang
      chez
    ];
    buildInputs = [
      chez
      gmp
      libidris2_support
    ];

    enableParallelBuilding = true;

    makeFlags = [
      "PREFIX=${placeholder "out"}"
      "IDRIS2_SUPPORT_DIR=${libsupportLib}"
    ];

    buildFlags = [
      "bootstrap"
      "SCHEME=scheme"
      "IDRIS2_LIBS=${libsupportLib}"
      "IDRIS2_DATA=${libsupportShare}"
    ];

    installTargets = "install-idris2";

    postInstall = ''
      rm $out/bin/idris2
      mv $out/bin/idris2_app/idris2.so $out/bin/idris2
      rm -rf $out/bin/idris2_app
    '';

    meta = {
      description = "Purely functional programming language with first class types";
      mainProgram = "idris2";
      homepage = "https://github.com/idris-lang/Idris2";
      license = lib.licenses.bsd3;
      platforms = lib.platforms.all;
    };
  };
in

# Wrapped version with CHEZ and library paths set
symlinkJoin {
  inherit version;
  pname = "idris2";
  paths = [ idris2-unwrapped ];
  nativeBuildInputs = [ makeBinaryWrapper ];

  postBuild = ''
    wrapProgram "$out/bin/idris2" \
      --set CHEZ "${lib.getExe chez}" \
      --suffix IDRIS2_LIBS ':' "${libsupportLib}" \
      --suffix IDRIS2_DATA ':' "${libsupportShare}" \
      --suffix LD_LIBRARY_PATH ':' "${libsupportLib}"
  '';

  passthru = {
    unwrapped = idris2-unwrapped;
    inherit libidris2_support;
  };

  meta = idris2-unwrapped.meta;
}
