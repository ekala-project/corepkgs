# BEAM package scope, parameterized by an Erlang interpreter.
#
# Each Erlang variant gets its own scope via erlang.beamPackages.
# The top-level alias is: beamPackages = erlang.beamPackages;
{
  lib,
  erlang,
  generateSplicesForMkScope,
  makeScopeWithSplicing',
  pkgs,
  splicePath ? [ "beamPackages" ],
}:

makeScopeWithSplicing' {
  otherSplices = generateSplicesForMkScope splicePath;
  keep = self: { inherit (self) beamPackages; };
  f =
    self:
    let
      inherit (self) callPackage;
    in
    {
      inherit erlang;
      beamPackages = self;

      # Build managers
      inherit (callPackage ./rebar3 { }) rebar3 rebar3WithPlugins;
      rebar = callPackage ./rebar { };

      # Rebar3 plugins
      pc = callPackage ./pc { };
      rebar3-proper = callPackage ./rebar3-proper { };
      rebar3-nix = callPackage ./rebar3-nix { };

      # Fetchers
      fetchHex = callPackage ./fetch-hex.nix { };
      fetchRebar3Deps = callPackage ./fetch-rebar-deps.nix { };

      # Builders
      buildRebar3 = callPackage ./build-rebar3.nix { };
      buildErlangMk = callPackage ./build-erlang-mk.nix { };
      buildMix = callPackage ./build-mix.nix { };
      fetchMixDeps = callPackage ./fetch-mix-deps.nix { };
      mixRelease = callPackage ./mix-release.nix { };
      rebar3Relx = callPackage ./rebar3-release.nix { };

      # Hex package manager
      hex = callPackage ./hex { };

      # BEAM-based languages — elixir versions from pkgs-many
      elixir = self.elixir_1_18;

      elixir_1_20 = pkgs.elixir.v1_20;
      elixir_1_19 = pkgs.elixir.v1_19;
      elixir_1_18 = pkgs.elixir.v1_18;
      elixir_1_17 = pkgs.elixir.v1_17;

      # Hooks
      inherit (callPackage ./hooks { })
        beamCopySourceHook
        beamModuleInstallHook
        mixBuildDirHook
        mixCompileHook
        mixAppConfigPatchHook
        rebar3CompileHook
        rebarDevendorPatchHook
        ;
    };
}
