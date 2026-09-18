{
  makeSetupHook,
  waf,
}:

makeSetupHook {
  name = "waf-setup-hook";

  substitutions = {
    inherit waf;
  };

  meta = {
    description = "Setup hook for using Waf in Nixpkgs";
    inherit (waf.meta) platforms;
  };
} ./setup-hook.sh
