# Record propagated dependencies — nushell equivalent of recordPropagatedDependencies()
#
# Writes nix-support/propagated-* files in the standard format so downstream
# bash-based stdenv.mkDerivation packages can consume them.

export def recordPropagatedDeps [] {
  let attrs = $env.__attrs

  # Map from attr name to nix-support file name
  let depMap = [
    [attr file];
    [depsBuildBuildPropagated propagated-build-build-deps]
    [propagatedNativeBuildInputs propagated-native-build-inputs]
    [depsBuildTargetPropagated propagated-build-target-deps]
    [depsHostHostPropagated propagated-host-host-deps]
    [propagatedBuildInputs propagated-build-inputs]
    [depsTargetTargetPropagated propagated-target-target-deps]
  ]

  # Determine dev output
  let outputDev = ($env | get -o outputDev | default "out")
  let devPath = ($attrs.outputs | get $outputDev)

  for row in $depMap {
    let deps = ($attrs | get -o $row.attr | default [])
    if ($deps | length) > 0 {
      let supportDir = $"($devPath)/nix-support"
      mkdir $supportDir
      let content = ($deps | str join " ")
      $content | save -f $"($supportDir)/($row.file)"
    }
  }
}
