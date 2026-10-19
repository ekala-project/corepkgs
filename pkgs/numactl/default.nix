{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  autoreconfHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "numactl";
  version = "2.0.19";

  src = fetchFromGitHub {
    owner = "numactl";
    repo = "numactl";
    tag = "v${finalAttrs.version}";
    hash = "sha256-88fxc7u7l7n0WLZ56vDmvdAoh8BaKTXUHWfqCycyoOw=";
  };

  outputs = [
    "out"
    "dev"
    "man"
  ];

  nativeBuildInputs = [ autoreconfHook ];

  postPatch = ''
    patchShebangs test
  '';

  meta = {
    description = "Library and tools for non-uniform memory access (NUMA) machines";
    homepage = "https://github.com/numactl/numactl";
    license = with lib.licenses; [
      gpl2Only
      lgpl21
    ]; # libnuma is lgpl21
    platforms = lib.platforms.linux;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "numactl_project" finalAttrs.version;
  };
})
