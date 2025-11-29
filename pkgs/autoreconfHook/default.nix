{ makeSetupHook, autoconf, automake, gettext, libtool }:

makeSetupHook {
  name = "autoreconf-hook";
  propagatedBuildInputs = [ autoconf automake gettext libtool ];
} ./autoreconf.sh

