{
  version,
  hash,
  defaultJavaSelector,
  platforms ? [
    "aarch64-darwin"
    "aarch64-linux"
    "i686-windows"
    "x86_64-cygwin"
    "x86_64-darwin"
    "x86_64-linux"
    "x86_64-windows"
  ],
  meta ? { },
  enableUpdateScript ? false,
  ...
}@variantArgs:

{
  lib,
  stdenv,
  fetchurl,
  callPackage,
  makeWrapper,
  unzip,
  coreutils,
  findutils,
  ncurses5,
  ncurses6,
  gnused,
  udev,
  testers,
  runCommand,
  writeText,
  autoPatchelfHook,
  buildPackages,
  replaceVars,
  symlinkJoin,
  concatTextFile,
  makeSetupHook,
  nix-update-script,
  java,
  mitm-cache,

  # The JDK/JRE used for running Gradle.
  # Defaults to the version-specific default JDK
  jdk ? defaultJavaSelector java,

  # Additional JDK/JREs to be registered as toolchains.
  # See https://docs.gradle.org/current/userguide/toolchains.html
  javaToolchains ? [ ],

  # Ignored arguments from calling .override on the wrapper.
  ...
}:

let
  # The unwrapped gradle derivation
  gradle-unwrapped = stdenv.mkDerivation (finalAttrs: {
    pname = "gradle";
    inherit version;

    src = fetchurl {
      inherit hash;
      url = "https://services.gradle.org/distributions/gradle-${version}-bin.zip";
    };

    dontBuild = true;

    nativeBuildInputs = [
      makeWrapper
      unzip
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

    buildInputs = [
      stdenv.cc.cc
      ncurses5
      ncurses6
    ];

    # We only need to patchelf some libs embedded in JARs.
    dontAutoPatchelf = true;

    # All the installed Gradle libraries and binaries go here. Note that the Gradle wrapper
    # will look for a lib directory above its own directory (which is presumed to be bin)
    # for loading the main Gradle jar.
    gradleLibexec = "${placeholder "out"}/libexec/gradle";

    installPhase =
      let
        # set toolchains via installations.path property in gradle.properties.
        # See https://docs.gradle.org/current/userguide/toolchains.html#sec:custom_loc
        toolchainPaths = "org.gradle.java.installations.paths=${lib.concatStringsSep "," javaToolchains}";
        jnaLibraryPath = lib.optionalString stdenv.hostPlatform.isLinux (lib.makeLibraryPath [ udev ]);
        jnaFlag = lib.optionalString stdenv.hostPlatform.isLinux ''--add-flags "-Djna.library.path=${jnaLibraryPath}"'';
      in
      ''
        # Install all the Gradle jars.
        mkdir -vp $gradleLibexec
        cp -av lib/ $gradleLibexec
        [ -f $gradleLibexec/lib/gradle-launcher-*.jar ] || { echo "No Gradle launcher jar found!" >&2 && exit 1; }

        # Set up toolchain paths in the gradle.properties.
        echo ${lib.escapeShellArg toolchainPaths} > $gradleLibexec/gradle.properties

        # Just use the existing gradle wrapper (usually called `gradlew`) as the main program.
        mkdir -vp $gradleLibexec/bin
        cp -v bin/gradle $gradleLibexec/bin/gradlew
        chmod +x $gradleLibexec/bin/gradlew
        patchShebangs --host $gradleLibexec/bin/gradlew

        # Ensure that JAVA_HOME is set so the installed Gradle wrapper picks it up.
        # The wrapper also needs coreutils, xargs, and sed.
        mkdir -vp $out/bin
        makeWrapper $gradleLibexec/bin/gradlew $out/bin/gradle \
          --set-default JAVA_HOME ${jdk} \
          --suffix PATH : ${
            lib.makeBinPath [
              coreutils
              findutils
              gnused
            ]
          } \
          ${jnaFlag}
      '';

    dontFixup = !stdenv.hostPlatform.isLinux;

    fixupPhase =
      let
        arch = if stdenv.hostPlatform.is64bit then "amd64" else "i386";
        newFileEvents = toString (lib.versionAtLeast version "8.12");
      in
      ''
        # get the correct jar executable for cross
        export PATH="${buildPackages.jdk}/bin:$PATH"
        . ${./patching.sh}

        nativeVersion="$(extractVersion native-platform $gradleLibexec/lib/native-platform-*.jar)"
        for variant in "" "-ncurses5" "-ncurses6"; do
          autoPatchelfInJar \
            $gradleLibexec/lib/native-platform-linux-${arch}$variant-''${nativeVersion}.jar \
            "${lib.getLib stdenv.cc.cc}/lib64:${
              lib.makeLibraryPath [
                stdenv.cc.cc
                ncurses5
                ncurses6
              ]
            }"
        done

        # The file-events library _seems_ to follow the native-platform version, but
        # we won't assume that.
        if [ -n "${newFileEvents}" ]; then
          fileEventsVersion="$(extractVersion gradle-fileevents $gradleLibexec/lib/gradle-fileevents-*.jar)"
          autoPatchelfInJar \
            $gradleLibexec/lib/gradle-fileevents-''${fileEventsVersion}.jar \
            "${lib.getLib stdenv.cc.cc}/lib64:${lib.makeLibraryPath [ stdenv.cc.cc ]}"
        else
          fileEventsVersion="$(extractVersion file-events $gradleLibexec/lib/file-events-*.jar)"
          autoPatchelfInJar \
            $gradleLibexec/lib/file-events-linux-${arch}-''${fileEventsVersion}.jar \
            "${lib.getLib stdenv.cc.cc}/lib64:${lib.makeLibraryPath [ stdenv.cc.cc ]}"
        fi

        # The scanner doesn't pick up the runtime dependency in the jar.
        # Manually add a reference where it will be found.
        mkdir $out/nix-support
        echo ${stdenv.cc.cc} > $out/nix-support/manual-runtime-dependencies
        # Gradle will refuse to start without _both_ 5 and 6 versions of ncurses.
        echo ${ncurses5} >> $out/nix-support/manual-runtime-dependencies
        echo ${ncurses6} >> $out/nix-support/manual-runtime-dependencies
        ${lib.optionalString stdenv.hostPlatform.isLinux "echo ${udev} >> $out/nix-support/manual-runtime-dependencies"}
      '';

    passthru.tests = {
      version = testers.testVersion {
        package = finalAttrs.finalPackage;
        command = ''
          env GRADLE_USER_HOME=$TMPDIR/gradle GRADLE_OPTS=-Dorg.gradle.native.dir=$TMPDIR/native \
            gradle --version
        '';
      };

      java-application = testers.testEqualContents {
        assertion = "can build and run a trivial Java application";
        expected = writeText "expected" "hello\n";
        actual =
          runCommand "actual"
            {
              nativeBuildInputs = [ finalAttrs.finalPackage ];
              src = ./tests/java-application;
            }
            ''
              cp -a $src/* .

              # Make sure GRADLE_OPTS works.
              env \
                GRADLE_USER_HOME=$TMPDIR/gradle \
                GRADLE_OPTS="-Dorg.gradle.native.dir=$TMPDIR/native -Dnix.test.mainClass=Main" \
                gradle run --no-daemon --quiet --console plain > $out
            '';
      };
    };

    passthru.jdk = jdk;
    passthru.unwrapped = finalAttrs.finalPackage;

    passthru.updateScript =
      if enableUpdateScript then
        nix-update-script {
          extraArgs = [
            "--url=https://github.com/gradle/gradle"
            # Gradle's .0 releases are tagged as `vX.Y.0`, but the actual
            # release version omits the `.0`, so we'll wanto to only capture
            # the version up but not including the the trailing `.0`.
            "--version-regex=^v(\\d+\\.\\d+(?:\\.[1-9]\\d?)?)(\\.0)?$"
          ];
        }
      else
        null;

    meta = {
      inherit platforms;
      description = "Enterprise-grade build system";
      longDescription = ''
        Gradle is a build system which offers you ease, power and freedom.
        You can choose the balance for yourself. It has powerful multi-project
        build support. It has a layer on top of Ivy that provides a
        build-by-convention integration for Ivy. It gives you always the choice
        between the flexibility of Ant and the convenience of a
        build-by-convention behavior.
      '';
      homepage = "https://www.gradle.org/";
      changelog = "https://docs.gradle.org/${version}/release-notes.html";
      downloadPage = "https://gradle.org/next-steps/?version=${version}";
      sourceProvenance = with lib.sourceTypes; [
        binaryBytecode
        binaryNativeCode
      ];
      license = lib.licenses.asl20;
      mainProgram = "gradle";
    }
    // meta;
  });

  # Add passthru attributes to gradle-unwrapped
  gradle-final = gradle-unwrapped.overrideAttrs (oldAttrs: {
    passthru = (oldAttrs.passthru or { }) // {
      fetchDeps = callPackage ./fetch-deps.nix { inherit mitm-cache; };
      inherit mitm-cache;
      unwrapped = gradle-unwrapped;
      # Setup hook for gradle with mitm-cache support
      setupHook = makeSetupHook { name = "gradle-setup-hook"; } (
        replaceVars ./setup-hook.sh {
          # jdk used for keytool
          inherit (gradle-unwrapped) jdk;
          init_script = "${./init-build.gradle}";
        }
      );
      tests = (oldAttrs.passthru.tests or { }) // {
        toolchains =
          let
            jdk11 = java.v11;
            javaVersion = lib.getVersion jdk11;
            javaMajorVersion = lib.versions.major javaVersion;
          in
          runCommand "detects-toolchains-from-nix-env"
            {
              # Use JDKs that are not the default for any of the gradle versions
              nativeBuildInputs = [
                (gradle-final.override { javaToolchains = [ jdk11 ]; })
              ];
              src = ./tests/toolchains;
            }
            ''
              cp -a $src/* .
              substituteInPlace ./build.gradle --replace-fail '@JAVA_VERSION@' '${javaMajorVersion}'
              env GRADLE_USER_HOME=$TMPDIR/gradle GRADLE_OPTS=-Dorg.gradle.native.dir=$TMPDIR/native \
                gradle run --no-daemon --quiet --console plain > $out
              actual="$(<$out)"
              if [[ "${javaVersion}" != "$actual"* ]]; then
                echo "Error: Expected '${javaVersion}', to start with '$actual'" >&2
                exit 1
              fi
            '';
      };
    };
  });
in
gradle-final
