{
  lib,
  stdenv,
  fetchFromGitLab,
  bash,
  bash-completion,
  # TODO(corepkgs): Port bridge-utils for Linux bridge management
  # bridge-utils,
  coreutils,
  curl,
  dbus,
  dnsmasq,
  docutils,
  gettext,
  glib,
  gnutls,
  iproute2,
  iptables,
  json_c,
  libgcrypt,
  libpcap,
  libtasn1,
  libxml2,
  libxslt,
  makeWrapper,
  meson,
  nftables,
  ninja,
  openssh,
  passt,
  perl,
  pkg-config,
  polkit,
  # TODO(corepkgs): Port pmutils for power management
  # pmutils,
  python3,
  readline,
  # TODO(corepkgs): Port rpcsvc-proto for rpcgen
  # rpcsvc-proto,
  runtimeShell,
  writeShellScriptBin,

  # Linux
  acl,
  attr,
  audit,
  # TODO(corepkgs): Port dmidecode for DMI/SMBIOS hardware info
  # dmidecode,
  fuse,
  kmod,
  libapparmor,
  libcap_ng,
  libnl,
  libpciaccess,
  libtirpc,
  lvm2,
  numactl,
  # TODO(corepkgs): Port numad for NUMA daemon support
  # numad,
  parted,
  systemd,
  util-linux,
}:

let
  inherit (stdenv.hostPlatform) isLinux;
  binPath = lib.makeBinPath (
    [
      dnsmasq
    ]
    ++ lib.optionals isLinux [
      # bridge-utils # TODO(corepkgs)
      # dmidecode # TODO(corepkgs)
      dnsmasq
      iproute2
      iptables
      kmod
      lvm2
      nftables
      numactl
      # numad # TODO(corepkgs)
      openssh
      passt
      # pmutils # TODO(corepkgs)
      systemd
    ]
  );
in

stdenv.mkDerivation (finalAttrs: {
  pname = "libvirt";
  version = "12.6.0";

  src = fetchFromGitLab {
    owner = "libvirt";
    repo = "libvirt";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-SEscELXhiEoFnDDcxV7Jb2LjyheNJbgPp7AnXix2GVU=";
  };

  patches = [
    ./0001-meson-patch-in-an-install-prefix-for-building-on-nix.patch
  ];

  # remove some broken tests
  postPatch = ''
    sed -i '/commandtest/d' tests/meson.build
    sed -i '/virnetsockettest/d' tests/meson.build
    # delete only the first occurrence of this
    sed -i '0,/qemuxmlconftest/{/qemuxmlconftest/d;}' tests/meson.build

  ''
  + lib.optionalString isLinux ''
    for binary in mount umount mkfs; do
      substituteInPlace meson.build \
        --replace "find_program('$binary'" "find_program('${lib.getBin util-linux}/bin/$binary'"
    done

  ''
  + ''
    substituteInPlace meson.build \
      --replace "'dbus-daemon'," "'${lib.getBin dbus}/bin/dbus-daemon',"
  ''
  + lib.optionalString isLinux ''
    sed -i 's,define PARTED "parted",define PARTED "${parted}/bin/parted",' \
      src/storage/storage_backend_disk.c \
      src/storage/storage_util.c
  ''
  + lib.optionalString isLinux (
    let
      script = writeShellScriptBin "virt-secret-init-encryption-sh" ''
        export PATH="${
          lib.makeBinPath [
            coreutils
            systemd
          ]
        }:$PATH"
        exec ${runtimeShell} "$@"
      '';
    in
    ''
      substituteInPlace src/secret/virt-secret-init-encryption.service.in \
        --replace-fail /usr/bin/sh ${script}/bin/virt-secret-init-encryption-sh
    ''
  );

  strictDeps = true;

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    docutils
    libxml2 # for xmllint
    libxslt # for xsltproc
    gettext
    makeWrapper
    ninja
    pkg-config
    perl
    # TODO(corepkgs): Port perlPackages.XMLXPath
    # perlPackages.XMLXPath
    # TODO(corepkgs): Port rpcsvc-proto for rpcgen
    # rpcsvc-proto
  ];

  buildInputs = [
    bash
    bash-completion
    curl
    dbus
    glib
    gnutls
    libgcrypt
    libpcap
    libtasn1
    libxml2
    python3
    readline
    json_c
  ]
  ++ lib.optionals isLinux [
    acl
    attr
    audit
    fuse
    libapparmor
    libcap_ng
    libnl
    libpciaccess
    libtirpc
    lvm2
    numactl
    # numad # TODO(corepkgs)
    parted
    systemd
    util-linux
  ];

  preConfigure =
    let
      overrides = {
        QEMU_BRIDGE_HELPER = "/run/wrappers/bin/qemu-bridge-helper";
        QEMU_PR_HELPER = "/run/libvirt/nix-helpers/qemu-pr-helper";
      };

      patchBuilder = var: value: ''
        sed -i meson.build -e "s|conf.set_quoted('${var}',.*|conf.set_quoted('${var}','${value}')|"
      '';
    in
    ''
      PATH="${binPath}:$PATH"
      # the path to qemu-kvm will be stored in VM's .xml and .save files
      # do not use "''${qemu_kvm}/bin/qemu-kvm" to avoid bound VMs to particular qemu derivations
      substituteInPlace src/lxc/lxc_conf.c \
        --replace 'lxc_path,' '"/run/libvirt/nix-emulators/libvirt_lxc",'

      substituteInPlace build-aux/meson.build \
        --replace "gsed" "sed" \
        --replace "gmake" "make" \
        --replace "ggrep" "grep"

      substituteInPlace src/util/virpolkit.h \
        --replace '"/usr/bin/pkttyagent"' '"${polkit.bin}/bin/pkttyagent"'

      substituteInPlace src/util/virpci.c \
         --replace '/lib/modules' '${
           if isLinux then "/run/booted-system/kernel-modules" else ""
         }/lib/modules'

      patchShebangs .
    ''
    + (lib.concatStringsSep "\n" (lib.mapAttrsToList patchBuilder overrides));

  mesonAutoFeatures = "disabled";

  mesonFlags =
    let
      cfg = option: val: "-D${option}=${val}";
      feat = option: enable: cfg option (if enable then "enabled" else "disabled");
      driver = name: feat "driver_${name}";
      storage = name: feat "storage_${name}";
    in
    [
      "--sysconfdir=/var/lib"
      (cfg "install_prefix" (placeholder "out"))
      (cfg "localstatedir" "/var")
      (cfg "runstatedir" "/run")
      (cfg "sshconfdir" "/etc/ssh/ssh_config.d")

      (cfg "init_script" "systemd")

      (feat "apparmor" isLinux)
      (feat "attr" isLinux)
      (feat "audit" isLinux)
      (feat "bash_completion" true)
      (feat "blkid" isLinux)
      (feat "capng" isLinux)
      (feat "curl" true)
      (feat "docs" true)
      (feat "expensive_tests" true)
      (feat "firewalld" isLinux)
      (feat "firewalld_zone" isLinux)
      (feat "fuse" isLinux)
      (feat "glusterfs" false)
      (feat "host_validate" true)
      (feat "libiscsi" false)
      (feat "libnl" isLinux)
      (feat "libpcap" true)
      (feat "libssh2" true)
      (feat "login_shell" isLinux)
      (feat "nss" (isLinux && !stdenv.hostPlatform.isMusl))
      (feat "numactl" isLinux)
      # TODO(corepkgs): enable numad when ported
      (feat "numad" false)
      (feat "pciaccess" isLinux)
      (feat "polkit" isLinux)
      (feat "readline" true)
      (feat "secdriver_apparmor" isLinux)
      (feat "ssh_proxy" isLinux)
      (feat "tests" true)
      (feat "udev" isLinux)
      (feat "json_c" true)
      (feat "libvirtd" true)

      (driver "ch" (isLinux && (stdenv.hostPlatform.isx86_64 || stdenv.hostPlatform.isAarch64)))
      (driver "esx" true)
      (driver "interface" isLinux)
      (driver "libvirtd" true)
      # TODO(corepkgs): enable Xen driver when xen is ported
      (driver "libxl" false)
      (driver "lxc" isLinux)
      (driver "network" true)
      (driver "openvz" isLinux)
      (driver "qemu" true)
      (driver "remote" true)
      (driver "secrets" true)
      (driver "test" true)
      (driver "vbox" true)
      (driver "vmware" true)

      (storage "dir" true)
      (storage "disk" isLinux)
      (storage "fs" isLinux)
      # TODO(corepkgs): enable gluster storage when glusterfs is ported
      (storage "gluster" false)
      # TODO(corepkgs): enable iSCSI storage when openiscsi/libiscsi are ported
      (storage "iscsi" false)
      (storage "iscsi_direct" false)
      (storage "lvm" isLinux)
      (storage "mpath" isLinux)
      # TODO(corepkgs): enable RBD storage when ceph is ported
      (storage "rbd" false)
      (storage "scsi" true)
      (storage "vstorage" isLinux)
      # TODO(corepkgs): enable ZFS storage when zfs is ported
      (storage "zfs" false)
    ];

  doCheck = true;

  postInstall = ''
    substituteInPlace $out/bin/virt-xml-validate \
      --replace xmllint ${libxml2}/bin/xmllint

    # Enable to set some options from the corresponding ekaos module (or other
    # places) via environment variables.
    substituteInPlace $out/libexec/libvirt-guests.sh \
      --replace 'ON_BOOT="start"'       'ON_BOOT=''${ON_BOOT:-start}' \
      --replace 'ON_SHUTDOWN="suspend"' 'ON_SHUTDOWN=''${ON_SHUTDOWN:-suspend}' \
      --replace 'PARALLEL_SHUTDOWN=0'   'PARALLEL_SHUTDOWN=''${PARALLEL_SHUTDOWN:-0}' \
      --replace 'SHUTDOWN_TIMEOUT=300'  'SHUTDOWN_TIMEOUT=''${SHUTDOWN_TIMEOUT:-300}' \
      --replace 'START_DELAY=0'         'START_DELAY=''${START_DELAY:-0}' \
      --replace "$out/bin"              '${gettext}/bin' \
      --replace 'lock/subsys'           'lock' \
      --replace 'gettext.sh'            'gettext.sh
    # Added in corepkgs:
    gettext() { "${gettext}/bin/gettext" "$@"; }
    '
  ''
  + lib.optionalString isLinux ''
    for f in $out/lib/systemd/system/*.service ; do
      substituteInPlace $f --replace /bin/kill ${coreutils}/bin/kill
    done
    rm $out/lib/systemd/system/{virtlockd,virtlogd}.*
    wrapProgram $out/sbin/libvirtd \
      --prefix PATH : /run/libvirt/nix-emulators:${binPath}
  '';

  meta = {
    description = "Toolkit to interact with the virtualization capabilities of recent versions of Linux and other OSes";
    homepage = "https://libvirt.org/";
    changelog = "https://gitlab.com/libvirt/libvirt/-/raw/v${finalAttrs.version}/NEWS.rst";
    license = lib.licenses.lgpl2Plus;
    platforms = lib.platforms.linux;
  };
})
