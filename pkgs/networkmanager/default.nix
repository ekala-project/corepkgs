{
  lib,
  stdenv,
  fetchurl,
  replaceVars,
  gettext,
  pkg-config,
  dbus,
  libuuid,
  polkit,
  gnutls,
  # TODO(corepkgs): Port ppp
  # ppp,
  dhcpcd,
  iptables,
  nftables,
  vala,
  libgcrypt,
  # TODO(corepkgs): Port dnsmasq
  # dnsmasq,
  # TODO(corepkgs): Port bluez5
  # bluez5,
  readline,
  libselinux,
  audit,
  gobject-introspection,
  perl,
  # TODO(corepkgs): Port modemmanager
  # modemmanager,
  # TODO(corepkgs): Port openresolv
  # openresolv,
  libndp,
  newt,
  # TODO(corepkgs): Port ethtool
  # ethtool,
  gnused,
  iputils,
  kmod,
  jansson,
  elfutils,
  gtk-doc,
  libxslt,
  docbook-xsl-nons,
  docbook_xml_dtd_412,
  docbook_xml_dtd_42,
  docbook_xml_dtd_43,
  curl,
  meson,
  ninja,
  libpsl,
  # TODO(corepkgs): Port mobile-broadband-provider-info
  # mobile-broadband-provider-info,
  systemd,
  udev,
  udevCheckHook,
  withSystemd ? true,
}:

let
  # TODO(corepkgs): Enable docs when pygobject3 is available in python3.pkgs
  enableDocs = false;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "networkmanager";
  version = "1.56.0";

  src = fetchurl {
    url = "https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/releases/${finalAttrs.version}/downloads/NetworkManager-${finalAttrs.version}.tar.xz";
    hash = "sha256-WaMtOFzB564m5DeYxvEtB/9hmKvQQewGILOgjPwCHMw=";
  };

  outputs = [
    "out"
    "dev"
  ]
  ++ lib.optionals enableDocs [
    "devdoc"
    "man"
    "doc"
  ];

  mesonFlags = [
    # System paths
    "--sysconfdir=/etc"
    "--localstatedir=/var"
    (lib.mesonOption "systemdsystemunitdir" (
      if withSystemd then "${placeholder "out"}/etc/systemd/system" else "no"
    ))
    # to enable link-local connections
    "-Dudev_dir=${placeholder "out"}/lib/udev"
    "-Ddbus_conf_dir=${placeholder "out"}/share/dbus-1/system.d"
    "-Dkernel_firmware_dir=/run/current-system/firmware"

    # Platform
    "-Dmodprobe=${kmod}/bin/modprobe"
    (lib.mesonOption "session_tracking" (if withSystemd then "systemd" else "no"))
    (lib.mesonBool "systemd_journal" withSystemd)
    "-Dlibaudit=yes-disabled-by-default"
    "-Dpolkit_agent_helper_1=/run/wrappers/bin/polkit-agent-helper-1"

    # Features
    "-Diwd=true"
    # TODO(corepkgs): Enable when ppp is ported
    # "-Dpppd=${ppp}/bin/pppd"
    "-Dppp=false"
    "-Diptables=${iptables}/bin/iptables"
    "-Dnft=${nftables}/bin/nft"
    # TODO(corepkgs): Enable when modemmanager is ported
    "-Dmodem_manager=false"
    "-Dnmtui=true"
    # TODO(corepkgs): Enable when dnsmasq is ported
    # "-Ddnsmasq=${dnsmasq}/bin/dnsmasq"
    "-Dqt=false"
    "-Dnbft=false"

    # Handlers
    # TODO(corepkgs): Enable when openresolv is ported
    # "-Dresolvconf=${openresolv}/bin/resolvconf"

    # DHCP clients
    "-Ddhcpcd=${dhcpcd}/bin/dhcpcd"

    # Miscellaneous
    "-Ddocs=${lib.boolToString enableDocs}"
    "-Dman=${lib.boolToString enableDocs}"
    "-Dtests=no"
    "-Dcrypto=gnutls"
    # TODO(corepkgs): Enable when mobile-broadband-provider-info is ported
    # "-Dmobile_broadband_provider_info_database=${mobile-broadband-provider-info}/share/mobile-broadband-provider-info/serviceproviders.xml"
  ];

  patches = [
    (replaceVars ./fix-paths.patch {
      inherit
        iputils
        gnused
        ;
      # TODO(corepkgs): Port ethtool; using placeholder for now
      ethtool = "/run/current-system/sw";
      runtimeShell = "${stdenv.shell}";
    })

    ./fix-install-paths.patch
  ];

  buildInputs = [
    (if withSystemd then systemd else udev)
    libselinux
    audit
    libpsl
    libuuid
    polkit
    libndp
    curl
    # TODO(corepkgs): Port bluez5
    # bluez5
    # TODO(corepkgs): Port modemmanager
    # modemmanager
    readline
    newt
    jansson
    dbus
  ];

  propagatedBuildInputs = [
    gnutls
    libgcrypt
  ];

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    gettext
    pkg-config
    vala
    gobject-introspection
    perl
    elfutils
    udevCheckHook
  ]
  ++ lib.optionals enableDocs [
    gtk-doc
    libxslt
    docbook-xsl-nons
    docbook_xml_dtd_412
    docbook_xml_dtd_42
    docbook_xml_dtd_43
  ];

  postPatch = ''
    patchShebangs ./tools
    patchShebangs libnm/generate-setting-docs.py

    substituteInPlace meson.build \
      --replace "'vala', req" "'vala', native: false, req"
  ''
  + lib.optionalString withSystemd ''
    substituteInPlace data/NetworkManager.service.in \
      --replace-fail /usr/bin/busctl ${systemd}/bin/busctl
  '';

  preBuild = lib.optionalString enableDocs ''
    mkdir -p ${placeholder "out"}/lib
    ln -s $PWD/src/libnm-client-impl/libnm.so.0 ${placeholder "out"}/lib/libnm.so.0
  '';

  mesonBuildType = "release";

  meta = {
    homepage = "https://networkmanager.dev";
    description = "Network configuration and management tool";
    license = lib.licenses.gpl2Plus;
    maintainers = [ ];
    platforms = lib.platforms.linux;
  };
})
