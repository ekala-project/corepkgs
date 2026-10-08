{
  erlang,
  beamCopySourceHook,
  beamModuleInstallHook,
  rebar3CompileHook,
  rebar3WithPlugins,
  rebarDevendorPatchHook,

  libyaml,
  openssl,

  lib,
  stdenv,
  writeText,
}:

lib.extendMkDerivation {
  constructDrv = stdenv.mkDerivation;
  excludeDrvArgNames = [
    "beamDeps"
    "buildPlugins"
  ];
  extendDrvArgs =
    finalAttrs:
    {
      beamDeps ? [ ],
      buildPlugins ? [ ],

      enableDebugInfo ? false,
      erlangCompilerOptions ? [ ],
      erlangDeterministicBuilds ? true,
      ...
    }@args:
    let
      rebar3Custom = rebar3WithPlugins {
        plugins = buildPlugins;
      };
    in
    {
      pname = args.name;
      name = "erlang${erlang.version}-${args.name}-${finalAttrs.version}";

      nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [
        erlang
        rebar3Custom
        rebarDevendorPatchHook
        beamCopySourceHook
        beamModuleInstallHook
        rebar3CompileHook
      ];

      buildInputs = (args.buildInputs or [ ]) ++ [
        erlang
        openssl
        libyaml
      ];

      propagatedBuildInputs = lib.unique beamDeps;

      env = {
        ERL_COMPILER_OPTIONS =
          let
            options = erlangCompilerOptions ++ lib.optionals erlangDeterministicBuilds [ "deterministic" ];
          in
          "[${lib.concatStringsSep "," options}]";

        beamModuleName = args.name;
      }
      // (args.env or { });

      setupHook = writeText "setupHook.sh" ''
        addToSearchPath ERL_LIBS "$1/lib/erlang/lib/"
      '';

      meta = {
        inherit (erlang.meta) platforms;
      }
      // (args.meta or { });

      passthru = {
        inherit beamDeps;
      };
    };
}
