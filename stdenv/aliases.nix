lib: final: prev:
let
  inherit (final) pkgs;
  # Removing recurseForDerivation prevents derivations of aliased attribute set
  # to appear while listing all the packages available.
  removeRecurseForDerivations =
    alias:
    if alias.recurseForDerivations or false then
      lib.removeAttrs alias [ "recurseForDerivations" ]
    else
      alias;

  # Make sure that we are not shadowing something from top-level.nix.
  checkInPkgs =
    n: alias: if builtins.hasAttr n prev then abort "Alias ${n} is still in top-level.nix" else alias;

  mapAliases =
    aliases: lib.mapAttrs (n: alias: removeRecurseForDerivations (checkInPkgs n alias)) aliases;
in
with pkgs;
# These largely reflect Nixpkgs aliases
mapAliases {
  # keep-sorted start
  autoconf269 = autoconf.v2_69;
  autoconf271 = autoconf.v2_71;
  automake116x = automake.v1_16;
  automake118x = automake.v1_18;
  autoreconfHook269 = autoconf.v2_69.autoreconfHook;
  autoreconfHook271 = autoconf.v2_71.autoreconfHook;
  cmakeMinimal = cmake.minimal;
  go_1_24 = go.v1_24;
  go_1_25 = go.v1_25;
  gmp6 = gmp.variants.v6_3;
  gmpxx = gmp.variants.cxx;
  guile_1_8 = guile.v1_8;
  guile_2_0 = guile.v2_0;
  guile_2_2 = guile.v2_2;
  guile_3_0 = guile.v3_0;
  perl538 = perl.v5_38;
  perl540 = perl.v5_40;
  tcl-8_5 = tcl.v8_5;
  tcl-8_6 = tcl.v8_6;
  tcl-9_0 = tcl.v9_0;
  # keep-sorted end
}
