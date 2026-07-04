{
  lib,
  buildGoModule,
  fetchFromGitHub,
  hwinfo,
  libusb1,
  gcc,
  pkg-config,
  makeWrapper,
  stdenv,
  systemd,
}:

buildGoModule (finalAttrs: {
  pname = "nixos-facter";
  version = "0.4.4";

  src = fetchFromGitHub {
    owner = "numtide";
    repo = "nixos-facter";
    tag = "v${finalAttrs.version}";
    hash = "sha256-w4tFIouJQLf/JeY7wvvSLbxQv73Bbs11a8EAu6iXwKU=";
  };

  vendorHash = "sha256-5duwAxAgbPZIbbgzZE2m574TF/0+jF/TvTKI4YBH6jM=";

  env.CGO_ENABLED = 1;

  buildInputs = [
    libusb1
    hwinfo
  ];

  nativeBuildInputs = [
    gcc
    pkg-config
    makeWrapper
  ];

  postInstall = ''
    wrapProgram "$out/bin/nixos-facter" \
        --prefix PATH : "${lib.makeBinPath [ systemd ]}"
  '';

  ldflags = [
    "-s"
    "-w"
    "-X git.numtide.com/numtide/nixos-facter/build.Name=nixos-facter"
    "-X git.numtide.com/numtide/nixos-facter/build.Version=v${finalAttrs.version}"
    "-X github.com/numtide/nixos-facter/pkg/build.System=${stdenv.hostPlatform.system}"
  ];

  meta = {
    description = "Declarative hardware configuration for NixOS";
    homepage = "https://github.com/numtide/nixos-facter";
    license = lib.licenses.gpl3Plus;
    mainProgram = "nixos-facter";
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
})
