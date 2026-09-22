{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
}:

stdenvNoCC.mkDerivation rec {
  pname = "qcom-firmware";
  version = "20260810";

  src = fetchFromGitLab {
    owner = "kernel-firmware";
    repo = "linux-firmware";
    rev = "refs/tags/${version}";
    hash = "sha256-IFnCz4kiSQhIoQalRhcHcp7nXe4oC3MRWE09/D4i+Ao=";
    sparseCheckout = [ "qcom" ];
  };

  buildCommand = ''
    mkdir -p $out/lib/firmware
    cp -r $src/qcom $out/lib/firmware/
  '';

  meta = {
    description = "Qualcomm SoC firmware from linux-firmware";
    homepage = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
  };
}
