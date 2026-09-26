{
  stdenv,
  lib,
  makeSetupHook,
  makeWrapper,
  isGraphical ? false,
  gtk3 ? null,
  librsvg,
  dconf,
  withDconf ? !stdenv.targetPlatform.isDarwin && lib.meta.availableOn stdenv.targetPlatform dconf,
  targetPackages,
}:

makeSetupHook {
  name = "wrap-gapps-hook";
  propagatedBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals isGraphical [
    gtk3
    librsvg
  ];

  depsTargetTargetPropagated =
    assert (!targetPackages ? raw || throw "wrapGAppsNoGuiHook must be in nativeBuildInputs");
    lib.optionals isGraphical [
      librsvg
      gtk3
    ]
    ++ lib.optionals withDconf [
      dconf.lib
    ];

  meta.license = lib.licenses.mit;
} ./wrap-gapps-hook.sh
