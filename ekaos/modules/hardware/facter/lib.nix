# Adios helper ported from ekaos/modules/hardware/facter/lib.nix.
#
# The legacy file is a plain helper (a function taking nixpkgs `lib`, no
# `options`/`config` keys), consumed via `import ./lib.nix lib`. It is
# rewritten here without nixpkgs lib (builtins + small locals only) at the
# same relative path.
#
# Calling convention: `(import ./lib.nix { })`. All arguments default to
# null because adios `defaultFunc` bodies only receive `{ inputs, options }`
# and therefore cannot pass `lib`/`types` in; the implementation below is
# fully self-contained and ignores its arguments.
#
# NOTE: adds `hexToInt` and `unique` beyond the legacy API. `hexToInt` fixes
# a latent legacy bug (facter/nvidia.nix `slotToBusId` references
# `facterLib.hexToInt`, which the legacy lib.nix never defined; that helper
# was dead code there). `unique` is an order-preserving dedup used in place
# of nixpkgs `lib.unique`.
{
  types ? null,
  lib ? null,
  ...
}:
let
  # Local reimplementation of nixpkgs `lib.assertMsg` (returns bool for `assert`).
  assertMsg = cond: msg: cond;

  stringToCharacters = s: builtins.genList (i: builtins.substring i 1 s) (builtins.stringLength s);

  hasPrefix = pref: str: builtins.substring 0 (builtins.stringLength pref) str == pref;

  escapeRegexChar =
    c:
    if
      builtins.elem c [
        "\\"
        "."
        "*"
        "+"
        "?"
        "("
        ")"
        "["
        "]"
        "{"
        "}"
        "^"
        "$"
        "|"
      ]
    then
      "\\${c}"
    else
      c;

  escapeRegex = s: builtins.concatStringsSep "" (builtins.map escapeRegexChar (stringToCharacters s));

  hasInfix = needle: haystack: builtins.match ".*${escapeRegex needle}.*" haystack != null;

  # Local reimplementation of nixpkgs `lib.toHexString` (lowercase).
  toHexString =
    n:
    let
      digits = "0123456789abcdef";
      go = q: if q == 0 then "" else go (q / 16) + builtins.substring (builtins.bitAnd q 15) 1 digits;
    in
    if n == 0 then "0" else go n;

  hexDigitValues = {
    "0" = 0;
    "1" = 1;
    "2" = 2;
    "3" = 3;
    "4" = 4;
    "5" = 5;
    "6" = 6;
    "7" = 7;
    "8" = 8;
    "9" = 9;
    "a" = 10;
    "b" = 11;
    "c" = 12;
    "d" = 13;
    "e" = 14;
    "f" = 15;
    "A" = 10;
    "B" = 11;
    "C" = 12;
    "D" = 13;
    "E" = 14;
    "F" = 15;
  };

  hexToInt =
    s: builtins.foldl' (acc: c: acc * 16 + (hexDigitValues.${c} or 0)) 0 (stringToCharacters s);

  # Order-preserving dedup (replaces nixpkgs `lib.unique`).
  unique = list: builtins.foldl' (acc: x: if builtins.elem x acc then acc else acc ++ [ x ]) [ ] list;

  # Query if a facter report contains a CPU with the given vendor name
  hasCpu =
    name:
    {
      hardware ? { },
      ...
    }:
    let
      cpus = hardware.cpu or [ ];
    in
    assert assertMsg (hardware != { }) "no hardware entries found in the report";
    assert assertMsg (cpus != [ ]) "no cpu entries found in the report";
    builtins.any (
      {
        vendor_name ? null,
        ...
      }:
      assert assertMsg (vendor_name != null) "detail.vendor_name not found in cpu entry";
      vendor_name == name
    ) cpus;

  # Extract all driver_modules from a list of hardware entries
  collectDrivers = list: builtins.foldl' (lst: value: lst ++ value.driver_modules or [ ]) [ ] list;

  # Deduplicate a list of strings
  stringSet = list: builtins.attrNames (builtins.groupBy (x: x) list);

  # Query if a facter report contains a GPU with the given PCI vendor ID
  hasGpuVendor =
    vendorId:
    {
      hardware ? { },
      ...
    }:
    builtins.any (
      {
        vendor ? { },
        ...
      }:
      (vendor.value or 0) == vendorId
    ) (hardware.graphics_card or [ ]);

  # Check if facter report indicates a portable/laptop chassis via SMBIOS
  # SMBIOS chassis types: 8=Portable, 9=Laptop, 10=Notebook,
  # 14=Sub Notebook, 30=Tablet, 31=Convertible, 32=Detachable
  isPortableChassis =
    {
      smbios ? { },
      ...
    }:
    let
      portableTypes = [
        8
        9
        10
        14
        30
        31
        32
      ];
    in
    builtins.any (
      {
        chassis_type ? { },
        ...
      }:
      builtins.elem (chassis_type.value or 0) portableTypes
    ) (smbios.chassis or [ ]);

  # Convert number to zero-padded 4-digit hex string (for USB device IDs)
  toZeroPaddedHex =
    n:
    let
      hex = toHexString n;
      len = builtins.stringLength hex;
    in
    if len == 1 then
      "000${hex}"
    else if len == 2 then
      "00${hex}"
    else if len == 3 then
      "0${hex}"
    else
      hex;

  # SMBIOS vendor/product matching for device quirks
  hasManufacturer =
    name:
    {
      smbios ? { },
      ...
    }:
    hasInfix name ((smbios.system or { }).manufacturer or "");

  hasProduct =
    pattern:
    {
      smbios ? { },
      ...
    }:
    hasInfix pattern ((smbios.system or { }).product_name or "");

  isDevice =
    {
      manufacturer,
      product ? null,
    }:
    report: hasManufacturer manufacturer report && (product == null || hasProduct product report);

  # Query if a facter report contains a PCI device with the given vendor and device IDs
  hasPciDevice =
    vendorId: deviceId:
    {
      hardware ? { },
      ...
    }:
    let
      allPci =
        (hardware.graphics_card or [ ])
        ++ (hardware.network_controller or [ ])
        ++ (hardware.storage_controller or [ ])
        ++ (hardware.multimedia_controller or [ ]);
    in
    builtins.any (
      {
        vendor ? { },
        device ? { },
        ...
      }:
      (vendor.value or 0) == vendorId && (device.value or 0) == deviceId
    ) allPci;

  # Query if a facter report contains a USB device with the given vendor ID
  hasUsbVendor =
    vendorId:
    {
      hardware ? { },
      ...
    }:
    let
      allUsb =
        (hardware.fingerprint_reader or [ ])
        ++ (hardware.joystick or [ ])
        ++ (hardware.scanner or [ ])
        ++ (hardware.printer or [ ]);
    in
    builtins.any (
      {
        vendor ? { },
        ...
      }:
      (vendor.value or 0) == vendorId
    ) allUsb;

  # Check if the facter report indicates a convertible/tablet chassis
  # SMBIOS: 30=Tablet, 31=Convertible, 32=Detachable
  isConvertibleChassis =
    {
      smbios ? { },
      ...
    }:
    builtins.any (
      {
        chassis_type ? { },
        ...
      }:
      builtins.elem (chassis_type.value or 0) [
        30
        31
        32
      ]
    ) (smbios.chassis or [ ]);

  # Query if a facter report contains a network controller with the given PCI vendor ID
  hasNetworkVendor =
    vendorId:
    {
      hardware ? { },
      ...
    }:
    builtins.any (
      {
        vendor ? { },
        ...
      }:
      (vendor.value or 0) == vendorId
    ) (hardware.network_controller or [ ]);

  # Check if any entries in a hardware category have a specific driver module prefix
  hasDriver =
    category: driverPrefix:
    {
      hardware ? { },
      ...
    }:
    builtins.any (entry: builtins.any (m: hasPrefix driverPrefix m) (entry.driver_modules or [ ])) (
      hardware.${category} or [ ]
    );
in
{
  inherit
    hasCpu
    hasGpuVendor
    isPortableChassis
    collectDrivers
    stringSet
    toZeroPaddedHex
    hasManufacturer
    hasProduct
    isDevice
    hasPciDevice
    hasUsbVendor
    isConvertibleChassis
    hasNetworkVendor
    hasDriver
    hexToInt
    unique
    hasPrefix
    hasInfix
    ;

  hasAmdCpu = hasCpu "AuthenticAMD";
  hasIntelCpu = hasCpu "GenuineIntel";

  # PCI vendor IDs: AMD/ATI=0x1002, Intel=0x8086, NVIDIA=0x10de
  hasAmdGpu = hasGpuVendor 4098;
  hasIntelGpu = hasGpuVendor 32902;
  hasNvidiaGpu = hasGpuVendor 4318;

  # Common device checks
  isFramework = hasManufacturer "Framework";
  isSurface = isDevice {
    manufacturer = "Microsoft Corporation";
    product = "Surface";
  };
  isThinkPad = hasProduct "ThinkPad";
  isAsusRog = isDevice {
    manufacturer = "ASUSTeK";
    product = "ROG";
  };
  isDellXps = isDevice {
    manufacturer = "Dell";
    product = "XPS";
  };
}
