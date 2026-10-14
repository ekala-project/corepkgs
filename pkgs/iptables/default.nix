{
  lib,
  stdenv,
  fetchurl,
  autoreconfHook,
  pkg-config,
  pruneLibtoolFiles,
  flex,
  bison,
  libmnl,
  libnetfilter_conntrack,
  libnfnetlink,
  libnftnl,
  libpcap,
  bash,
  iptables,
  testers,
  bashNonInteractive,
  nftablesCompat ? true,
  gitUpdater,
}:

stdenv.mkDerivation (finalAttrs: {
  version = "1.8.11";
  pname = "iptables";

  src = fetchurl {
    url = "https://www.netfilter.org/projects/iptables/files/iptables-${finalAttrs.version}.tar.xz";
    sha256 = "2HMD1V74ySvK1N0/l4sm0nIBNkKwKUJXdfW60QCf57I=";
  };

  outputs = [
    "out"
    "lib"
    "dev"
    "man"
  ];

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
    pruneLibtoolFiles
    flex
    bison
  ];

  buildInputs = [
    libmnl
    libnetfilter_conntrack
    libnfnetlink
    libnftnl
    libpcap
    bash
  ];

  configureFlags = [
    "--enable-bpf-compiler"
    "--enable-devel"
    "--enable-libipq"
    "--enable-nfsynproxy"
    "--enable-shared"
  ]
  ++ lib.optional (!nftablesCompat) "--disable-nftables";

  postInstall = lib.optionalString nftablesCompat ''
    rm $out/sbin/{iptables,iptables-restore,iptables-save,ip6tables,ip6tables-restore,ip6tables-save}
    ln -sv xtables-nft-multi $out/bin/iptables
    ln -sv xtables-nft-multi $out/bin/iptables-restore
    ln -sv xtables-nft-multi $out/bin/iptables-save
    ln -sv xtables-nft-multi $out/bin/ip6tables
    ln -sv xtables-nft-multi $out/bin/ip6tables-restore
    ln -sv xtables-nft-multi $out/bin/ip6tables-save
  '';

  outputChecks.lib.disallowedRequisites = [
    bash
    bashNonInteractive
  ];

  passthru = {
    tests = {
      version = testers.testVersion {
        package = iptables;
        command = "iptables --version";
      };
    };
    updateScript = gitUpdater {
      url = "https://git.netfilter.org/iptables";
      rev-prefix = "v";
    };
  };

  meta = {
    description = "Program to configure the Linux IP packet filtering ruleset";
    homepage = "https://www.netfilter.org/projects/iptables/index.html";
    platforms = lib.platforms.linux;
    mainProgram = "iptables";
    license = lib.licenses.gpl2Plus;
    downloadPage = "https://www.netfilter.org/projects/iptables/files/";
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "netfilter" finalAttrs.version;
  };
})
