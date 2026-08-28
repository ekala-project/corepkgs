{
  lib,
  makeSetupHook,
  autoconf,
  automake,
  gettext,
  libtool,
}:

makeSetupHook {
  name = "autoreconf-hook";
  propagatedBuildInputs = [
    autoconf
    automake
    gettext
    libtool
  ];
  meta = {
    description = "Setup hook for running autoreconf before configure phase";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
} ./autoreconf.sh
