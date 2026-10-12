{
  lib,
  stdenv,
  maven,
  java,
  makeWrapper,
}:

{
  pname,
  version,
  src,
  mvnHash ? "",
  mvnParameters ? "",
  buildInputs ? [ ],
  nativeBuildInputs ? [ ],
  ...
}@args:

stdenv.mkDerivation (
  args
  // {
    inherit pname version src;

    nativeBuildInputs = [
      maven
      java
      makeWrapper
    ]
    ++ nativeBuildInputs;

    buildInputs = [ java ] ++ buildInputs;

    configurePhase =
      args.configurePhase or ''

        # Set up Maven cache
        export M2_HOME=${maven}
        export MAVEN_OPTS="-Dmaven.repo.local=$TMPDIR/.m2/repository"

      '';

    buildPhase =
      args.buildPhase or ''

        mvn package ${mvnParameters} \
          -Dmaven.test.skip=true \
          -Dmaven.repo.local=$TMPDIR/.m2/repository

      '';

    installPhase =
      args.installPhase or ''

        mkdir -p $out/share/java $out/bin

        # Install JAR files
        find target -name "*.jar" -not -name "*-sources.jar" -not -name "*-javadoc.jar" \
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
