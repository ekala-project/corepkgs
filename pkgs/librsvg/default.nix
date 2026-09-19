{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  meson,
  ninja,
  glib,
  gdk-pixbuf,
  installShellFiles,
  pango,
  freetype,
  cairo,
  libxml2,
  bzip2,
  dav1d,
  rustPlatform,
  rustc,
  cargo-c,
  cargo-auditable-cargo-wrapper,
  gi-docgen,
  python3Packages,
  vala,
  shared-mime-info,
  withPixbufLoader ?
    !stdenv.hostPlatform.isStatic && stdenv.hostPlatform.emulatorAvailable buildPackages,
  withIntrospection ?
    lib.meta.availableOn stdenv.hostPlatform gobject-introspection
    && stdenv.hostPlatform.emulatorAvailable buildPackages,
  buildPackages,
  gobject-introspection,
  mesonEmulatorHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "librsvg";
  version = "2.62.3";

  outputs = [
    "out"
    "dev"
  ]
  ++ lib.optionals withIntrospection [
    "devdoc"
  ];

  src = fetchurl {
    url = "mirror://gnome/sources/librsvg/${lib.versions.majorMinor finalAttrs.version}/librsvg-${finalAttrs.version}.tar.xz";
    hash = "sha256-frRJsnIqdoAhNW9m3+4yAsIptU7U5qcM5AwJDpf/FvI=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) src;
    name = "librsvg-deps-${finalAttrs.version}";
    hash = "sha256-9ubfIl9R2BdcAWn7i050KBbb4cMdlakvrKdnjpZCQjA=";
    dontConfigure = true;
  };

  strictDeps = true;

  depsBuildBuild = [
    pkg-config
  ];

  nativeBuildInputs = [
    installShellFiles
    pkg-config
    meson
    meson.configurePhaseHook
    ninja
    rustc
    cargo-c
    cargo-auditable-cargo-wrapper
    python3Packages.docutils
    rustPlatform.cargoSetupHook
  ]
  ++ lib.optionals withIntrospection [
    gobject-introspection
    gi-docgen
    vala
  ]
  ++ lib.optionals (withIntrospection && !stdenv.buildPlatform.canExecute stdenv.hostPlatform) [
    mesonEmulatorHook
  ];

  buildInputs = [
    libxml2
    bzip2
    dav1d
    pango
    freetype
  ]
  ++ lib.optionals withIntrospection [
    vala
  ];

  propagatedBuildInputs = [
    glib
    gdk-pixbuf
    cairo
  ];

  mesonEntries = {
    triplet = stdenv.hostPlatform.rust.rustcTarget;
    tests = false;
  };

  mesonFeatures = {
    introspection = withIntrospection;
    pixbuf-loader = withPixbufLoader;
    vala = withIntrospection;
  };

  env = {
    PKG_CONFIG_GDK_PIXBUF_2_0_GDK_PIXBUF_QUERY_LOADERS = buildPackages.writeShellScript "gdk-pixbuf-loader-loaders-wrapped" ''
      ${lib.optionalString (stdenv.hostPlatform.emulatorAvailable buildPackages) (stdenv.hostPlatform.emulator buildPackages)} ${lib.getDev gdk-pixbuf}/bin/gdk-pixbuf-query-loaders
    '';
  };

  postPatch = ''
    patchShebangs \
      meson/cargo_wrapper.py \
      meson/makedef.py \
      meson/query-rustc.py

    # Fix thumbnailer path
    substituteInPlace gdk-pixbuf-loader/librsvg.thumbnailer.in \
      --replace-fail '@bindir@/gdk-pixbuf-thumbnailer' '${gdk-pixbuf}/bin/gdk-pixbuf-thumbnailer'
  '';

  postInstall =
    let
      emulator = stdenv.hostPlatform.emulator buildPackages;
    in
    lib.optionalString withPixbufLoader ''
      # Merge gdkpixbuf and librsvg loaders
      GDK_PIXBUF=$out/${gdk-pixbuf.binaryDir}
      cat ${lib.getLib gdk-pixbuf}/${gdk-pixbuf.binaryDir}/loaders.cache $GDK_PIXBUF/loaders.cache > $GDK_PIXBUF/loaders.cache.tmp
      mv $GDK_PIXBUF/loaders.cache.tmp $GDK_PIXBUF/loaders.cache
    ''
    + lib.optionalString (stdenv.hostPlatform.emulatorAvailable buildPackages) ''
      installShellCompletion --cmd rsvg-convert \
        --bash <(${emulator} $out/bin/rsvg-convert --completion bash) \
        --fish <(${emulator} $out/bin/rsvg-convert --completion fish) \
        --zsh <(${emulator} $out/bin/rsvg-convert --completion zsh)
    '';

  postFixup = lib.optionalString withIntrospection ''
    # Cannot be in postInstall, otherwise _multioutDocs hook in preFixup will move right back.
    moveToOutput "share/doc" "$devdoc"
  '';

  meta = {
    description = "Small library to render SVG images to Cairo surfaces";
    homepage = "https://gitlab.gnome.org/GNOME/librsvg";
    license = lib.licenses.lgpl2Plus;
    mainProgram = "rsvg-convert";
    platforms = lib.platforms.unix;
  };
})
