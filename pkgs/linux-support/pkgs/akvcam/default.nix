{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
  kernelModuleMakeFlags,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "akvcam";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "webcamoid";
    repo = "akvcam";
    tag = finalAttrs.version;
    sha256 = "sha256-3fs+Kfafry77SQvsAidM29g9CcfjWirteS/VdNSWVCE=";
  };
  sourceRoot = "${finalAttrs.src.name}/src";

  nativeBuildInputs = kernel.moduleBuildDependencies;
  makeFlags = kernelModuleMakeFlags ++ [
    "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  installPhase = ''
    install -m644 -b -D akvcam.ko $out/lib/modules/${kernel.modDirVersion}/akvcam.ko
  '';

  meta = {
    description = "Virtual camera driver for Linux";
    homepage = "https://github.com/webcamoid/akvcam";
    platforms = lib.platforms.linux;
    license = lib.licenses.gpl2Only;
  };
})
