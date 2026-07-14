{
  lib,
  stdenv,
  fetchurl,
  linux-pam,
  testers,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "cronie";
  version = "1.7.2";

  src = fetchurl {
    url = "https://github.com/cronie-crond/cronie/releases/download/cronie-${finalAttrs.version}/cronie-${finalAttrs.version}.tar.gz";
    hash = "sha256-8do3ShW6dgXPN4NH+WvItnjT18B2UmnIJCz+WweJxXE=";
  };

  buildInputs = [
    linux-pam
  ];

  configureFlags = [
    "--with-pam"
    "--with-inotify"
    "--enable-anacron"
    "--with-daemon-name=crond"
    "--localstatedir=/var"
    "--sysconfdir=/etc"
  ];

  # Override install paths to prevent writing to /etc during build
  installFlags = [
    "pamdir=$(out)/etc/pam.d"
    "sysconfdir=$(out)/etc"
  ];

  # Skip systemd unit installation
  postConfigure = ''
    if grep -q 'systemctl' Makefile; then
      substituteInPlace Makefile \
        --replace 'systemctl --' 'echo skipped: systemctl --'
    fi
  '';

  outputs = [
    "out"
    "man"
  ];

  enableParallelBuilding = true;

  passthru.tests = {
    version = testers.testVersion {
      package = finalAttrs.finalPackage;
      command = "crond -V";
    };
  };

  meta = {
    homepage = "https://github.com/cronie-crond/cronie";
    description = "Standard UNIX daemon crond that runs specified programs at scheduled times";
    longDescription = ''
      Cronie contains the standard UNIX daemon crond that runs specified programs at
      scheduled times and related tools. It is a fork of the original vixie-cron and
      has security and configuration enhancements like the ability to use PAM and
      SELinux.
    '';
    license = lib.licenses.isc;
    maintainers = [ ];
    platforms = lib.platforms.linux;
    mainProgram = "crond";
  };
})
