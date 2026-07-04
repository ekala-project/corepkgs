{
  lib,
  stdenv,
  fetchFromGitHub,
  flex,
  libuuid,
  libx86emu ? null,
  perl,
  perlPackages,
  kmod,
  systemd,
  buildPackages,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "hwinfo";
  version = "25.2";

  # Use the numtide fork which nixos-facter requires
  src = fetchFromGitHub {
    owner = "numtide";
    repo = "hwinfo";
    rev = "bfeab0b4e38b200c7a62a44d4d01601a86fe1091";
    hash = "sha256-GL3fNCSaU45fNihEksgtPtbuLkc+tVGXtPH05wbrHwI=";
  };

  nativeBuildInputs = [
    flex
    perl
    perlPackages.XMLWriter
    perlPackages.XMLParser
  ];
  depsBuildBuild = [ buildPackages.stdenv.cc ];

  buildInputs = [ libuuid ] ++ lib.optional (libx86emu != null) libx86emu;

  postPatch = ''
    echo ${finalAttrs.version} > VERSION

    substituteInPlace Makefile \
      --replace-fail "/sbin" "/bin"
    substituteInPlace src/isdn/cdb/Makefile \
      --replace-fail "lex isdn_cdb.lex" "flex isdn_cdb.lex"
    substituteInPlace hwinfo.pc.in \
      --replace-fail "prefix=/usr" "prefix=$out"
    substituteInPlace src/isdn/cdb/cdb_hwdb.h \
      --replace-fail "/usr/share" "$out/share"

    substituteInPlace src/hd/hd_int.h \
      --replace-fail "/sbin/modprobe" "${kmod}/bin/modprobe" \
      --replace-fail "/sbin/rmmod" "${kmod}/bin/rmmod" \
      --replace-fail "/usr/bin/udevinfo" "${systemd}/bin/udevinfo" \
      --replace-fail "/usr/bin/udevadm" "${systemd}/bin/udevadm"

    patchShebangs src/ids/convert_hd
  '';

  outputs = [
    "bin"
    "dev"
    "lib"
    "out"
  ];

  preBuild = ''
    rm -f git2log
    pushd src/ids
    cp ${systemd.src}/hwdb.d/pci.ids src/pci
    cp ${systemd.src}/hwdb.d/usb.ids src/usb
    perl -pi -e 'undef $_ if /^C\s/..1' src/usb
    perl ./convert_hd src/pci
    perl ./convert_hd src/usb
    popd

    make -C src/ids CC=$CC_FOR_BUILD -j $NIX_BUILD_CORES check_hd
    make -C src/isdn/cdb CC=$CC_FOR_BUILD -j $NIX_BUILD_CORES isdn_cdb mk_isdnhwdb
  '';

  makeFlags = [
    "LIBDIR=/lib"
    "CC=${stdenv.cc.targetPrefix}cc"
    "ARCH=${stdenv.hostPlatform.uname.processor}"
  ];
  installFlags = [
    "INSTALL_PREFIX="
    "DESTDIR=$(out)"
  ];

  enableParallelBuilding = false;

  postInstall = ''
    moveToOutput bin "$bin"
    moveToOutput lib "$lib"
  '';

  meta = {
    description = "Hardware detection tool from openSUSE (numtide fork)";
    license = lib.licenses.gpl2Only;
    homepage = "https://github.com/numtide/hwinfo";
    platforms = lib.platforms.linux;
    mainProgram = "hwinfo";
    maintainers = [ ];
  };
})
