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
  libx11,
  libxext,
  libXi,
  libxrender,
  libXtst,
  zlib,
  callPackage,
}:

let
  # Determine the major version for URL construction
  majorVersion = lib.versions.major version;

  # JDK 8 uses a different versioning scheme (8u504-b01 vs 21.0.12+8)
  isJdk8 = majorVersion == "8";

  archPlatform =
    if stdenv.hostPlatform.isLinux then
      if stdenv.hostPlatform.isx86_64 then
        "x64_linux"
      else if stdenv.hostPlatform.isAarch64 then
        "aarch64_linux"
      else
        throw "Unsupported Linux architecture"
    else if stdenv.hostPlatform.isDarwin then
      if stdenv.hostPlatform.isAarch64 then "aarch64_mac" else throw "Unsupported macOS architecture"
    else
      throw "Unsupported platform";

  # JDK 8:  OpenJDK8U-jdk_x64_linux_hotspot_8u504b01.tar.gz
  # JDK 11+: OpenJDK21U-jdk_x64_linux_hotspot_21.0.12_8.tar.gz
  archiveName =
    if isJdk8 then
      "OpenJDK8U-jdk_${archPlatform}_hotspot_${version}${build}.tar.gz"
    else
      "OpenJDK${majorVersion}U-jdk_${archPlatform}_hotspot_${version}_${build}.tar.gz";

  # JDK 8:  jdk8u504-b01
  # JDK 11+: jdk-21.0.12%2B8
  releaseTag = if isJdk8 then "jdk${version}-${build}" else "jdk-${version}%2B${build}";

in
stdenv.mkDerivation (finalAttrs: {
  pname = "openjdk";
  inherit version;

  src = fetchurl {
    url = "https://github.com/adoptium/temurin${
      if isJdk8 then "8" else majorVersion
    }-binaries/releases/download/${releaseTag}/${archiveName}";
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
      libx11
      libxext
      libXi
      libxrender
      libXtst
    ]
    ++ lib.optionals (alsa-lib != null) [ alsa-lib ]
    ++ lib.optionals (cups != null) [ cups ]
    ++ lib.optionals (fontconfig != null) [ fontconfig ]
    ++ lib.optionals (freetype != null) [ freetype ]
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

    mkdir -p $out
    cp -r * $out/

    # Remove demo and sample directories to reduce closure size
    rm -rf $out/demo $out/sample || true

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
      java = finalAttrs.finalPackage;
    };
    buildGradlePackage = callPackage ./build-gradle-package.nix {
      java = finalAttrs.finalPackage;
    };
  };

  meta = {
    description = "Eclipse Temurin OpenJDK ${majorVersion} (Adoptium)";
    homepage = "https://adoptium.net/";
    license = lib.licenses.gpl2Plus; # GPLv2+ with Classpath exception
    platforms = builtins.attrNames src-hash;
    mainProgram = "java";
    identifiers.cpeParts = {
      vendor = "oracle";
      product = "openjdk";
    };
  };
})
