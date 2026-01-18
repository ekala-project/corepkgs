{
  overlays ? [ ],
  config ? { },
  packages ? null,
  devShells ? null,
  checks ? null,
  formatter ? null,
  apps ? null,
  checks ? null,
  hydraJobs ? null,
  systems ? [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ],
  # TODO: support pkgsModules
}:

let
  # TODO: don't depend on lib
  forAllSystems = lib.genAttrs systems;
  optionalAttrs = pred: attrs: if pred then attrs else { };
  optionalOutput = outputFunc: outputName: optionalAttrs (output != null) {
    ${outputName} = forallSystem (system: outputFunc legacyPackages.${sytem});
  };
  packages = forallSystems (system: packages legacyPackages.${system});

  legacyPackages = forAllSystems (system: import ../. {
    inherit system config;
  });
  assertMsg = pred: msg: pred || throw msg;
  assertFuncDefined = func: name: assertMsg (func != null -> builtins.isFunction func) "${name} must be a function";
  # Avoid having people do this boilerplate
  mkApps = builtins.mapAttrs (_: v: { type = "app"; program = v; })
  apps' = if apps == null then null else x: mkApps (apps x);
in

assert assertFuncDefined packages "packages";
assert assertFuncDefined devShells "devShells";
assert assertFuncDefined checks "checks";
assert assertFuncDefined formatter "formatter";
assert assertFuncDefined apps "apps";
assert assertFuncDefined hydraJobs "hydraJobs";

{
  inherit legacyPackages;
} // optionalOutput packages "packages"
// optionalOutput devShells "devShells"
// optionalOutput checks "checks"
// optionalOutput formatter "formatter"
// optionalOutput apps' "apps"
// optionalOutput hydraJobs "hydraJobs"
