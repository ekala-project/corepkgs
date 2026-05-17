{
  lib,
  stdenv,
  gradle,
  jdk,
  makeWrapper,
}:

{
  pname,
  version,
  src,
  gradleHash ? "",
  gradleBuildTask ? "build",
  buildInputs ? [ ],
  nativeBuildInputs ? [ ],
  ...
}@args:

stdenv.mkDerivation (
  args
  // {
    inherit pname version src;

    nativeBuildInputs = [
      gradle
      jdk
      makeWrapper
    ]
    ++ nativeBuildInputs;

    buildInputs = [ jdk ] ++ buildInputs;

    configurePhase =
      args.configurePhase or ''
        runHook preConfigure

        # Set up Gradle cache
        export GRADLE_USER_HOME=$TMPDIR/.gradle
        export JAVA_HOME=${jdk}

        runHook postConfigure
      '';

    buildPhase =
      args.buildPhase or ''
        runHook preBuild

        gradle ${gradleBuildTask} \
          --no-daemon \
          --offline \
          --gradle-user-home=$GRADLE_USER_HOME

        runHook postBuild
      '';

    installPhase =
      args.installPhase or ''
        runHook preInstall

        mkdir -p $out/share/java $out/bin

        # Install JAR files from build output
        find build/libs -name "*.jar" -not -name "*-sources.jar" -not -name "*-javadoc.jar" \
          -exec cp {} $out/share/java/ \;

        # Create wrapper script if main class is specified
        ${lib.optionalString (args.mainClass or null != null) ''
            cat > $out/bin/${pname} <<EOF
          #!/bin/sh
          exec ${jdk}/bin/java -cp $out/share/java/*.jar ${args.mainClass} "\$@"
          EOF
            chmod +x $out/bin/${pname}
        ''}

        runHook postInstall
      '';

    meta = args.meta or { } // {
      platforms = jdk.meta.platforms;
    };
  }
)
