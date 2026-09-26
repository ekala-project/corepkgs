# Adios port of ekaos/modules/hardware/facter/nvidia.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, lib, ... }:
let
  # Local reimplementation of nixpkgs `lib.splitString` (single-char
  # separator split; separators are dropped, unlike `builtins.split`).
  splitString =
    sep: s:
    let
      len = builtins.stringLength s;
      go =
        i: cur: acc:
        if i >= len then
          acc ++ [ cur ]
        else
          let
            c = builtins.substring i 1 s;
          in
          if c == sep then go (i + 1) "" (acc ++ [ cur ]) else go (i + 1) "${cur}${c}" acc;
    in
    go 0 "" [ ];

  # Local reimplementation of nixpkgs `lib.findFirst`.
  findFirst =
    pred: default: list:
    let
      found = builtins.filter pred list;
    in
    if found == [ ] then default else builtins.head found;

  nvidiaVendorId = 4318; # 0x10de
  intelVendorId = 32902; # 0x8086
  amdVendorId = 4098; # 0x1002

  nvidiaGpus =
    report:
    builtins.filter (
      {
        vendor ? { },
        ...
      }:
      (vendor.value or 0) == nvidiaVendorId
    ) (report.hardware.graphics_card or [ ]);

  otherGpus =
    report:
    builtins.filter (
      {
        vendor ? { },
        ...
      }:
      let
        vid = vendor.value or 0;
      in
      vid != nvidiaVendorId && (vid == intelVendorId || vid == amdVendorId)
    ) (report.hardware.graphics_card or [ ]);

  # Extract PCI bus ID from slot field in format "PCI:X:Y:Z".
  # NOTE: the legacy file also defines `slotToBusId` (identical logic, using
  # the missing `facterLib.hexToInt`); only this copy is live, the duplicate
  # is dropped here.
  gpuBusId =
    facterLib: gpu:
    let
      slot = gpu.slot or "";
      parts = splitString ":" slot;
      hasDomain = builtins.length parts >= 3;
      busStr = if hasDomain then builtins.elemAt parts 1 else builtins.elemAt parts 0;
      rest = if hasDomain then builtins.elemAt parts 2 else builtins.elemAt parts 1;
      devFn = splitString "." rest;
      devStr = builtins.elemAt devFn 0;
      fnStr = if builtins.length devFn > 1 then builtins.elemAt devFn 1 else "0";
    in
    if slot == "" then
      ""
    else
      "PCI:${builtins.toString (facterLib.hexToInt busStr)}:${builtins.toString (facterLib.hexToInt devStr)}:${fnStr}";
in
{
  options = {
    enable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        builtins.length (nvidiaGpus inputs.facter.report) > 0 && inputs.virt.noneEnable;
      description = "Whether to enable Facter NVIDIA GPU auto-configuration.";
    };

    hybridEnable = {
      type = types.bool;
      defaultFunc =
        { inputs, ... }:
        let
          report = inputs.facter.report;
        in
        builtins.length (nvidiaGpus report) > 0
        && builtins.length (otherGpus report) > 0
        && inputs.virt.noneEnable;
      description = "Whether to enable Facter hybrid GPU (PRIME) detection.";
    };

    busId = {
      type = types.string;
      defaultFunc =
        { inputs, ... }:
        let
          facterLib = import ./lib.nix { };
          gpus = nvidiaGpus inputs.facter.report;
        in
        if builtins.length gpus > 0 then gpuBusId facterLib (builtins.head gpus) else "";
      description = "PCI bus ID of the NVIDIA GPU (auto-detected from facter report).";
    };

    iGpuBusId = {
      type = types.string;
      defaultFunc =
        { inputs, ... }:
        let
          facterLib = import ./lib.nix { };
          gpus = otherGpus inputs.facter.report;
        in
        if builtins.length gpus > 0 then gpuBusId facterLib (builtins.head gpus) else "";
      description = "PCI bus ID of the integrated GPU (auto-detected from facter report).";
    };

    iGpuVendor = {
      type = types.enum "iGpuVendor" [
        "intel"
        "amd"
        "none"
      ];
      defaultFunc =
        { inputs, ... }:
        let
          gpus = otherGpus inputs.facter.report;
          iGpu = if builtins.length gpus > 0 then builtins.head gpus else null;
        in
        if iGpu != null && (iGpu.vendor.value or 0) == intelVendorId then
          "intel"
        else if iGpu != null && (iGpu.vendor.value or 0) == amdVendorId then
          "amd"
        else
          "none";
      description = "Vendor of the integrated GPU.";
    };
  };

  inputs = {
    facter.from = { root }: root.hardware.facter;
    virt.from = { root }: root.hardware.facter.virtualisation;
  };

  impl =
    { options, inputs }:
    lib.merge.attrs.recursively {
      mutators = [
        # Enable the NVIDIA hardware module with auto-detected settings
        (
          if options.enable then
            {
              # TODO(adios-cutover): legacy mkDefault priority lost (both options).
              hardware.nvidia.enable = true;
              hardware.nvidia.prime.nvidiaBusId = options.busId;
            }
          else
            { }
        )

        # Hybrid GPU: auto-configure PRIME offload with detected bus IDs
        # TODO(adios-cutover): legacy mkDefault priority lost (all options).
        (
          if options.hybridEnable then
            {
              hardware.nvidia.prime.offload.enable = true;
            }
          else
            { }
        )

        (
          if (options.hybridEnable && options.iGpuVendor == "intel") then
            {
              hardware.nvidia.prime.intelBusId = options.iGpuBusId;
            }
          else
            { }
        )

        (
          if (options.hybridEnable && options.iGpuVendor == "amd") then
            {
              hardware.nvidia.prime.amdgpuBusId = options.iGpuBusId;
            }
          else
            { }
        )
      ];
    };
}
