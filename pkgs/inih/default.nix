{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "inih";
  version = "58";

  src = fetchFromGitHub {
    owner = "benhoyt";
    repo = "inih";
    rev = "r${finalAttrs.version}";
    hash = "sha256-b2f6hQvkmWgni/zdfv3I1b9ypd7zSyEBv/JVBA6K7/w=";
  };

  nativeBuildInputs = [
    meson
    ninja
  ];

  configurePhase = ''
    runHook preConfigure
    meson setup build \
      --prefix=$out \
      -Ddefault_library=shared \
      -Ddistro_install=true
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    ninja -C build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    ninja -C build install
    runHook postInstall
  '';

  outputs = [
    "out"
    "dev"
  ];

  meta = {
    homepage = "https://github.com/benhoyt/inih";
    description = "Simple .INI file parser in C";
    longDescription = ''
      inih (INI Not Invented Here) is a simple .INI file parser written in C.
      It's only a couple of pages of code, and it was designed to be small
      and simple, so it's good for embedded systems.
    '';
    license = lib.licenses.bsd3;
    platforms = lib.platforms.all;
    maintainers = [ ];
  };
})
