{
  lib,
  stdenv,
  maven,
  jdk,
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
      jdk
      makeWrapper
    ]
    ++ nativeBuildInputs;

    buildInputs = [ jdk ] ++ buildInputs;

    configurePhase =
      args.configurePhase or ''
        runHook preConfigure

        # Set up Maven cache
        export M2_HOME=${maven}
        export MAVEN_OPTS="-Dmaven.repo.local=$TMPDIR/.m2/repository"

        runHook postConfigure
      '';

    buildPhase =
      args.buildPhase or ''
        runHook preBuild

        mvn package ${mvnParameters} \
          -Dmaven.test.skip=true \
          -Dmaven.repo.local=$TMPDIR/.m2/repository

        runHook postBuild
      '';

    installPhase =
      args.installPhase or ''
        runHook preInstall

        mkdir -p $out/share/java $out/bin

        # Install JAR files
        find target -name "*.jar" -not -name "*-sources.jar" -not -name "*-javadoc.jar" \
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
