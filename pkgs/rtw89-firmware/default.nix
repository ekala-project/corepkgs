{
  lib,
  stdenvNoCC,
  fetchFromGitLab,
}:

stdenvNoCC.mkDerivation rec {
  pname = "rtw89-firmware";
  version = "20260810";

  src = fetchFromGitLab {
    owner = "kernel-firmware";
    repo = "linux-firmware";
    rev = "refs/tags/${version}";
    hash = "sha256-hBSMqTeoLo2JEb2Hvq5CHpLQSEQYBetMzsheG6NrX7A=";
    sparseCheckout = [ "rtw89" ];
  };

  buildCommand = ''
    mkdir -p $out/lib/firmware
    cp -r $src/rtw89 $out/lib/firmware/
  '';

  meta = {
    description = "Realtek WiFi (rtw89) firmware from linux-firmware";
    homepage = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
    license = lib.licenses.unfreeRedistributableFirmware;
    platforms = lib.platforms.linux;
  };
}
