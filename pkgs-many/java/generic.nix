{
  version,
  build,
  src-hash,
  ...
}@variantArgs:

{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib ? null,
  cups ? null,
  fontconfig ? null,
  freetype ? null,
  xorg ? { },
  zlib,
  callPackage,
}:

let
  # Determine the major version for URL construction
  majorVersion = lib.versions.major version;

  # Map Nix platform to Adoptium platform names
  platform =
    if stdenv.hostPlatform.system == "x86_64-linux" then
      "linux-x64"
    else if stdenv.hostPlatform.system == "aarch64-linux" then
      "linux-aarch64"
    else if stdenv.hostPlatform.system == "x86_64-darwin" then
      "mac-x64"
    else if stdenv.hostPlatform.system == "aarch64-darwin" then
      "mac-aarch64"
    else
      throw "Unsupported platform: ${stdenv.hostPlatform.system}";

  # Construct the download URL
  # Format: https://github.com/adoptium/temurin{major}-binaries/releases/download/jdk-{version}+{build}/OpenJDK{major}U-jdk_{arch}_{os}_hotspot_{version}_{build}.tar.gz
  archiveName = "OpenJDK${majorVersion}U-jdk_${
    if stdenv.hostPlatform.isLinux then
      if stdenv.hostPlatform.isx86_64 then
        "x64_linux"
      else if stdenv.hostPlatform.isAarch64 then
        "aarch64_linux"
      else
        throw "Unsupported Linux architecture"
    else if stdenv.hostPlatform.isDarwin then
      if stdenv.hostPlatform.isx86_64 then
        "x64_mac"
      else if stdenv.hostPlatform.isAarch64 then
        "aarch64_mac"
      else
        throw "Unsupported macOS architecture"
    else
      throw "Unsupported platform"
  }_hotspot_${version}_${build}.tar.gz";

in
stdenv.mkDerivation (finalAttrs: {
  pname = "openjdk";
  inherit version;

  src = fetchurl {
    url = "https://github.com/adoptium/temurin${majorVersion}-binaries/releases/download/jdk-${version}%2B${build}/${archiveName}";
    hash =
      src-hash.${stdenv.hostPlatform.system}
        or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
  };

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux (
    [
      zlib
    ]
    ++ lib.optionals (alsa-lib != null) [ alsa-lib ]
    ++ lib.optionals (cups != null) [ cups ]
    ++ lib.optionals (fontconfig != null) [ fontconfig ]
    ++ lib.optionals (freetype != null) [ freetype ]
    ++ lib.optionals (xorg.libX11 or null != null) [ xorg.libX11 ]
    ++ lib.optionals (xorg.libXext or null != null) [ xorg.libXext ]
    ++ lib.optionals (xorg.libXi or null != null) [ xorg.libXi ]
    ++ lib.optionals (xorg.libXrender or null != null) [ xorg.libXrender ]
    ++ lib.optionals (xorg.libXtst or null != null) [ xorg.libXtst ]
  );

  # Patch ELF files, but exclude jmods
  dontAutoPatchelf = false;

  # Ignore missing X11 libraries that aren't available in core-pkgs yet
  # These are only needed for GUI/AWT applications
  autoPatchelfIgnoreMissingDeps = [
    "libXtst.so.6"
    "libXi.so.6"
  ];

  # Prevent autoPatchelfHook from patching jmods directory
  preFixup = ''
    # Remove jmods temporarily to prevent autoPatchelf from breaking them
    if [ -d "$out/jmods" ]; then
      mv $out/jmods $out/jmods.tmp
    fi
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r * $out/

    # Remove demo and sample directories to reduce closure size
    rm -rf $out/demo $out/sample || true

    runHook postInstall
  '';

  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    # Restore jmods directory if it was moved
    if [ -d "$out/jmods.tmp" ]; then
      mv $out/jmods.tmp $out/jmods
    fi

    # Set interpreter for all executables
    for file in $out/bin/* $out/lib/jexec $out/lib/jspawnhelper; do
      if [ -f "$file" ] && isELF "$file" 2>/dev/null; then
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$file" 2>/dev/null || true
      fi
    done
  '';

  passthru = {
    home = placeholder "out";
    javaVersion = majorVersion;
    ekapkgs-update.skip = true;
    buildMavenPackage = callPackage ./build-maven-package.nix {
      jdk = finalAttrs.finalPackage;
    };
    buildGradlePackage = callPackage ./build-gradle-package.nix {
      jdk = finalAttrs.finalPackage;
    };
  };

  meta = {
    description = "Eclipse Temurin OpenJDK ${majorVersion} (Adoptium)";
    homepage = "https://adoptium.net/";
    license = lib.licenses.gpl2Plus; # GPLv2+ with Classpath exception
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "java";
    maintainers = [ ];
  };
})
