{
  stdenv,
  fetchurl,
  meson,
  ninja,
  pkg-config,
  gettext,
  bison,
  flex,
  python3,
  glib,
  makeWrapper,
  libcap,
  elfutils,
  bash-completion,
  lib,
  gobject-introspection,
  buildPackages,
  withIntrospection ?
    lib.meta.availableOn stdenv.hostPlatform gobject-introspection
    && stdenv.hostPlatform.emulatorAvailable buildPackages,
  libunwind,
  withLibunwind ?
    lib.meta.availableOn stdenv.hostPlatform libunwind
    && lib.elem "libunwind" libunwind.meta.pkgConfigModules or [ ],
}:

let
  hasElfutils = lib.meta.availableOn stdenv.hostPlatform elfutils;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "gstreamer";
  version = "1.28.5";

  outputs = [
    "bin"
    "out"
    "dev"
  ];

  src = fetchurl {
    url = "https://gstreamer.freedesktop.org/src/gstreamer/gstreamer-${finalAttrs.version}.tar.xz";
    hash = "sha256-pan3g4CbF6jrd09KdpWyy4y6axVSASmQb4fq8w5/hGk=";
  };

  strictDeps = true;

  depsBuildBuild = [
    pkg-config
  ];

  nativeBuildInputs = [
    meson
    meson.configurePhaseHook
    ninja
    pkg-config
    gettext
    bison
    flex
    python3
    makeWrapper
    glib
    bash-completion
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    libcap
  ]
  ++ lib.optionals withIntrospection [
    gobject-introspection
  ];

  buildInputs = [
    bash-completion
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    libcap
  ]
  ++ lib.optionals hasElfutils [
    elfutils
  ]
  ++ lib.optionals withLibunwind [
    libunwind
  ];

  propagatedBuildInputs = [
    glib
  ];

  mesonFeatures = {
    glib_debug = false;
    dbghelp = false;
    examples = false;
    ptp-helper = false;
    introspection = withIntrospection;
    doc = false;
    libunwind = withLibunwind;
    libdw = withLibunwind && hasElfutils;
  };

  postPatch = ''
    patchShebangs \
      gst/parse/get_flex_version.py \
      gst/parse/gen_grammar.py.in \
      gst/parse/gen_lex.py.in \
      libs/gst/helpers/ptp_helper_post_install.sh \
      scripts/extract-release-date-from-doap-file.py \
      docs/gst-plugins-doc-cache-generator.py
  '';

  postInstall =
    let
      sq = "'";
    in
    ''
      for prog in "$bin/bin/"*; do
          # We can't use --suffix here due to quoting so we craft the export command by hand
          wrapProgram "$prog" --run ${sq}export GST_PLUGIN_SYSTEM_PATH_1_0=$GST_PLUGIN_SYSTEM_PATH_1_0''${GST_PLUGIN_SYSTEM_PATH_1_0:+:}$(unset _tmp; for profile in $NIX_PROFILES; do _tmp="$profile/lib/gstreamer-1.0''${_tmp:+:}$_tmp"; done; printf ${sq}${sq}%s${sq}${sq} "$_tmp")${sq}
      done
    '';

  preFixup = ''
    moveToOutput "lib/gstreamer-1.0/pkgconfig" "$dev"
    moveToOutput "share/bash-completion" "$bin"
  '';

  setupHook = ./setup-hook.sh;

  meta = {
    description = "Open source multimedia framework";
    homepage = "https://gstreamer.freedesktop.org";
    license = lib.licenses.lgpl2Plus;
    platforms = lib.platforms.unix;
  };
})
