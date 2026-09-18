{
  lib,
  stdenv,
  buildPackages,
  fetchFromGitHub,
  flex,
  db,
  gettext,
  ninja,
  audit,
  linuxHeaders,
  libxcrypt,
  bash,
  bashNonInteractive,
  meson,
  pkg-config,
  systemdLibs,
  docbook5,
  libxslt,
  libxml2,
  findXMLCatalogs,
  docbook-xsl-ns,
  nix-update-script,
  withLogind ? lib.meta.availableOn stdenv.hostPlatform systemdLibs,
  withAudit ?
    lib.meta.availableOn stdenv.hostPlatform audit
    # cross-compilation only works from platforms with linux headers
    && lib.meta.availableOn stdenv.buildPlatform linuxHeaders,
  debugMode ? false, # warning: slower execution due to debug makes VM tests fail!
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "linux-pam";
  version = "1.7.2";

  src = fetchFromGitHub {
    owner = "linux-pam";
    repo = "linux-pam";
    tag = "v${finalAttrs.version}";
    hash = "sha256-V3XQqolinh+MqUefMDYJF9zP4fBJTHc7YKN+NEGjx1g=";

  };

  # patching unix_chkpwd is required as the nix store entry does not have the necessary bits
  postPatch = ''
    substituteInPlace modules/module-meson.build \
      --replace-fail "sbindir / 'unix_chkpwd'" "'/run/wrappers/bin/unix_chkpwd'"
  '';

  outputs = [
    "out"
    "doc"
    "man"
    "scripts"
    # "modules"
  ];

  depsBuildBuild = [ buildPackages.stdenv.cc ];
  nativeBuildInputs = [
    flex
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
    gettext

    libxslt
    libxml2
    findXMLCatalogs
    docbook-xsl-ns
    docbook5
  ];

  buildInputs = [
    db.v4_8
    libxcrypt
    bash
  ]
  ++ lib.optionals withAudit [
    audit
  ]
  ++ lib.optionals withLogind [
    systemdLibs
  ];

  mesonAutoFeatures = "auto";

  mesonEntries = {
    sysconfdir = "etc"; # relative to meson prefix, which is $out
    vendordir = "";
    xtests = false;
    examples = false;
    # warning: slower execution due to debug makes VM tests fail!
    ${if debugMode then "pam-debug" else null} = true;
  };

  mesonFeatures = {
    logind = withLogind;
    audit = withAudit;
    pam_lastlog = !stdenv.hostPlatform.isMusl; # TODO: switch to pam_lastlog2, pam_lastlog is deprecated and broken on musl
    pam_unix = true;
    elogind = false;
    econf = false;
    selinux = false;
    nis = false;
  };

  postInstall = ''
    moveToOutput sbin/pam_namespace_helper $scripts
    moveToOutput etc/security/namespace.init $scripts
  '';

  doCheck = false; # fails

  outputChecks.out.disallowedRequisites = [
    bash
    bashNonInteractive
  ];

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = {
    changelog = "https://github.com/linux-pam/linux-pam/releases/tag/${finalAttrs.src.tag}";
    homepage = "https://github.com/linux-pam/linux-pam";
    description = "Pluggable Authentication Modules, a flexible mechanism for authenticating user";
    platforms = lib.platforms.linux;
    license = lib.licenses.bsd3;
    badPlatforms = [ lib.systems.inspect.platformPatterns.isStatic ];
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "linux-pam" finalAttrs.version;
  };
})
