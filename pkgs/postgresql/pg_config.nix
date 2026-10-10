{
  diffutils,
  lib,
  replaceVarsWith,
  runtimeShell,
  stdenv,
  # PostgreSQL package
  postgresql,
}:

replaceVarsWith {
  name = "pg_config";
  src = ./pg_config.sh;
  dir = "bin";
  isExecutable = true;
  replacements = {
    inherit runtimeShell;
    "pg_config.env" = replaceVarsWith {
      name = "pg_config.env";
      src = "${lib.getDev postgresql}/nix-support/pg_config.env";
      replacements = { inherit (postgresql) out man; };
    };
  };
  nativeCheckInputs = [
    diffutils
  ];
  # The expected output only matches when outputs have *not* been altered by postgresql.withPackages.
  postCheck = lib.optionalString (postgresql.out == lib.getOutput "out" postgresql) ''
    if [ -e ${lib.getDev postgresql}/nix-support/pg_config.expected ]; then
        diff ${lib.getDev postgresql}/nix-support/pg_config.expected <($out/bin/pg_config)
    fi
  '';
}
