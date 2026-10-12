{
  lib,
  stdenv,
  gradle,
  java,
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
      java
      makeWrapper
    ]
    ++ nativeBuildInputs;

    buildInputs = [ java ] ++ buildInputs;

    configurePhase =
      args.configurePhase or ''

        # Set up Gradle cache
        export GRADLE_USER_HOME=$TMPDIR/.gradle
        export JAVA_HOME=${java}

      '';

    buildPhase =
      args.buildPhase or ''

        gradle ${gradleBuildTask} \
          --no-daemon \
          --offline \
          --gradle-user-home=$GRADLE_USER_HOME

      '';

    installPhase =
      args.installPhase or ''

        mkdir -p $out/share/java $out/bin

        # Install JAR files from build output
        find build/libs -name "*.jar" -not -name "*-sources.jar" -not -name "*-javadoc.jar" \
          -exec cp {} $out/share/java/ \;

        # Create wrapper script if main class is specified
        ${lib.optionalString (args.mainClass or null != null) ''
            cat > $out/bin/${pname} <<EOF
          #!/bin/sh
          exec ${java}/bin/java -cp $out/share/java/*.jar ${args.mainClass} "\$@"
          EOF
            chmod +x $out/bin/${pname}
        ''}

      '';

    meta = args.meta or { } // {
      platforms = java.meta.platforms;
    };
  }
)
