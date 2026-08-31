let
  allKernels = builtins.fromJSON (builtins.readFile ./kernels-rt.json);
in

{
  branch,
  lib,
  fetchurl,
  buildLinux,
  kernelPatches ? [ ],
  structuredExtraConfig ? { },
  extraMeta ? { },
  argsOverride ? { },
  ...
}@args:

let
  thisKernel = allKernels.${branch};
  inherit (thisKernel) version;

  # The RT patch is versioned X.Y.Z-rtN; the tarball it applies to is X.Y.Z.
  kversion = builtins.elemAt (lib.splitString "-" version) 0;

  rt-patch = {
    name = "rt";
    patch = fetchurl {
      url = "mirror://kernel/linux/kernel/projects/rt/${branch}/older/patch-${version}.patch.xz";
      hash = thisKernel.patchHash;
    };
  };
in
buildLinux (
  (removeAttrs args [ "branch" ])
  // {
    inherit version;
    pname = "linux-rt";

    # modDirVersion needs a patch number, change X.Y-rtZ to X.Y.0-rtZ.
    modDirVersion =
      if (builtins.match "[^.]*[.][^.]*-.*" version) == null then
        version
      else
        lib.replaceStrings [ "-" ] [ ".0-" ] version;

    src = fetchurl {
      url = "mirror://kernel/linux/kernel/v${lib.versions.major version}.x/linux-${kversion}.tar.xz";
      inherit (thisKernel) hash;
    };

    kernelPatches = [ rt-patch ] ++ kernelPatches;

    # Every branch the RT project maintains a patch series for is an LTS kernel.
    isLTS = true;

    structuredExtraConfig =
      with lib.kernel;
      {
        PREEMPT_RT = yes;
        # Fix error: unused option: PREEMPT_RT.
        EXPERT = yes; # PREEMPT_RT depends on it (in kernel/Kconfig.preempt)
        # Fix error: option not set correctly: PREEMPT_VOLUNTARY (wanted 'y', got 'n').
        PREEMPT_VOLUNTARY = lib.mkForce no; # PREEMPT_RT deselects it.
        # Fix error: unused option: RT_GROUP_SCHED.
        RT_GROUP_SCHED = lib.mkForce (option no); # Removed by sched-disable-rt-group-sched-on-rt.patch.
      }
      // structuredExtraConfig;

    extraMeta = extraMeta // {
      inherit branch;
    };
  }
  // argsOverride
)
