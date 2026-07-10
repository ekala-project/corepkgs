{
  lib,
  stdenv,
  fetchFromGitHub,
  meson,
  ninja,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "directx-headers";
  version = "1.619.4";

  src = fetchFromGitHub {
    owner = "microsoft";
    repo = "DirectX-Headers";
    rev = "v${finalAttrs.version}";
    hash = "sha256-C3k3lvPf5/PJkcuu1RY3w/rn7PnP3QfKL+z39RIVUEo=";
  };

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
  ];

  # tests require WSL2
  mesonFlags = [ "-Dbuild-test=false" ];

  meta = {
    description = "Official D3D12 headers from Microsoft";
    homepage = "https://github.com/microsoft/DirectX-Headers";
    license = lib.licenses.mit;
    maintainers = [ ];
    platforms = lib.platforms.all;
  };
})
