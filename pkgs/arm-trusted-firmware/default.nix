{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchFromGitLab,
  openssl,
  pkgsCross,
  buildPackages,

  # Warning: this blob (hdcp.bin) runs on the main CPU (not the GPU) at
  # privilege level EL3, which is above both the kernel and the
  # hypervisor.
  #
  # This parameter applies only to platforms which are believed to use
  # hdcp.bin. On all other platforms, or if unfreeIncludeHDCPBlob=false,
  # hdcp.bin will be deleted before building.
  unfreeIncludeHDCPBlob ? true,
}:

let
  buildArmTrustedFirmware = lib.makeOverridable (
    {
      filesToInstall,
      installDir ? "$out",
      platform ? null,
      platformCanUseHDCPBlob ? false, # set this to true if the platform is able to use hdcp.bin
      extraMakeFlags ? [ ],
      extraMeta ? { },
      ...
    }@args:

    # delete hdcp.bin if either: the platform is thought to
    # not need it or unfreeIncludeHDCPBlob is false
    let
      deleteHDCPBlobBeforeBuild = !platformCanUseHDCPBlob || !unfreeIncludeHDCPBlob;
    in

    let
      version = "2.13.0";
    in
    stdenv.mkDerivation (
      {

        pname = "arm-trusted-firmware";
        extensions = lib.optionals (platform != null) [ platform ];
        inherit version;

        src = fetchFromGitHub {
          owner = "ARM-software";
          repo = "arm-trusted-firmware";
          tag = "v${version}";
          hash = "sha256-rxm5RCjT/MyMCTxiEC8jQeFMrCggrb2DRbs/qDPXb20=";
        };

        patches = lib.optionals deleteHDCPBlobBeforeBuild [
          # this is a rebased version of https://gitlab.com/vicencb/kevinboot/-/blob/master/atf.patch
          ./remove-hdcp-blob.patch
        ];

        postPatch = lib.optionalString deleteHDCPBlobBeforeBuild ''
          rm plat/rockchip/rk3399/drivers/dp/hdcp.bin
        '';

        depsBuildBuild = [ buildPackages.stdenv.cc ];

        nativeBuildInputs = [
          pkgsCross.arm-embedded.stdenv.cc # For Cortex-M0 firmware in RK3399
          openssl # For fiptool
        ];

        # Make the new toolchain guessing (from 2.11+) happy
        # https://github.com/ARM-software/arm-trusted-firmware/blob/4ec2948fe3f65dba2f19e691e702f7de2949179c/make_helpers/toolchains/rk3399-m0.mk#L21-L22
        rk3399-m0-oc = "${pkgsCross.arm-embedded.stdenv.cc.targetPrefix}objcopy";

        buildInputs = [ openssl ];

        makeFlags = [
          "HOSTCC=$(CC_FOR_BUILD)"
          "M0_CROSS_COMPILE=${pkgsCross.arm-embedded.stdenv.cc.targetPrefix}"
          "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
          # Make the new toolchain guessing (from 2.11+) happy
          "CC=${stdenv.cc.targetPrefix}cc"
          "LD=${stdenv.cc.targetPrefix}cc"
          "AS=${stdenv.cc.targetPrefix}cc"
          "OC=${stdenv.cc.targetPrefix}objcopy"
          "OD=${stdenv.cc.targetPrefix}objdump"
          # Passing OpenSSL path according to docs/design/trusted-board-boot-build.rst
          "OPENSSL_DIR=${openssl}"
        ]
        ++ (lib.optional (platform != null) "PLAT=${platform}")
        ++ extraMakeFlags;

        installPhase = ''

          mkdir -p ${installDir}
          cp ${lib.concatStringsSep " " filesToInstall} ${installDir}

        '';

        hardeningDisable = [ "all" ];
        dontStrip = true;

        env.NIX_CFLAGS_COMPILE = lib.concatStringsSep " " [
          # breaks secondary CPU bringup on at least RK3588, maybe others
          "-fomit-frame-pointer"

          # Breaks compilation of armTrustedFirmwareRK3399:
          # /nix/store/hash-arm-none-eabi-binutils-2.44/bin/arm-none-eabi-ld: /build/source/build/rk3399/release/m0/rk3399m0.elf: error: PHDR segment not covered by LOAD segment
          #
          # This was caused by ccc56d1a79ff2a0f528cecf5e36eb76beaacc8c0 adding the flag `--enable-default-pie`.
          # According to https://trustedfirmware-a.readthedocs.io/en/v2.2/getting_started/user-guide.html,
          # Trusted Firmware-A has an option called ENABLE_PIE, which is turned off by default.
          # Someone with more knowledge of the implications can try using that option instead.
          "-no-pie"
        ];

        meta =

          {
            homepage = "https://github.com/ARM-software/arm-trusted-firmware";
            description = "Reference implementation of secure world software for ARMv8-A";
            license = [
              lib.licenses.bsd3
            ]
            ++ lib.optionals (!deleteHDCPBlobBeforeBuild) [ lib.licenses.unfreeRedistributable ];

          }
          // extraMeta;
      }
      // removeAttrs args [ "extraMeta" ]
    )
  );

in
{
  inherit buildArmTrustedFirmware;

  tools = buildArmTrustedFirmware {
    # Normally, arm-trusted-firmware builds the build tools for buildPlatform
    # using CC_FOR_BUILD (or as it calls it HOSTCC). Since want to build them
    # for the hostPlatform here, we trick it by overriding the HOSTCC setting
    # and, to be safe, remove CC_FOR_BUILD from the environment.
    depsBuildBuild = [ ];
    extraMakeFlags = [
      "HOSTCC=${stdenv.cc.targetPrefix}gcc"
      "fiptool"
      "certtool"
    ];
    filesToInstall = [
      "tools/fiptool/fiptool"
      "tools/cert_create/cert_create"
    ];
    postInstall = ''
      mkdir -p "$out/bin"
      find "$out" -type f -executable -exec mv -t "$out/bin" {} +
    '';
  };

  allwinner =
    let
      platform = "sun50i_a64";
    in
    buildArmTrustedFirmware {
      inherit platform;
      extraMeta.platforms = [ "aarch64-linux" ];
      filesToInstall = [ "build/${platform}/release/bl31.bin" ];
    };

  allwinnerH616 =
    let
      platform = "sun50i_h616";
    in
    buildArmTrustedFirmware {
      inherit platform;
      extraMeta.platforms = [ "aarch64-linux" ];
      filesToInstall = [ "build/${platform}/release/bl31.bin" ];
    };

  allwinnerH6 =
    let
      platform = "sun50i_h6";
    in
    buildArmTrustedFirmware {
      inherit platform;
      extraMeta.platforms = [ "aarch64-linux" ];
      filesToInstall = [ "build/${platform}/release/bl31.bin" ];
    };

  qemu =
    let
      platform = "qemu";
    in
    buildArmTrustedFirmware {
      inherit platform;
      extraMeta.platforms = [ "aarch64-linux" ];
      filesToInstall = [
        "build/${platform}/release/bl1.bin"
        "build/${platform}/release/bl2.bin"
        "build/${platform}/release/bl31.bin"
      ];
    };

  rk3328 =
    let
      platform = "rk3328";
    in
    buildArmTrustedFirmware {
      extraMakeFlags = [ "bl31" ];
      inherit platform;
      extraMeta.platforms = [ "aarch64-linux" ];
      filesToInstall = [ "build/${platform}/release/bl31/bl31.elf" ];
    };

  rk3399 =
    let
      platform = "rk3399";
    in
    buildArmTrustedFirmware {
      extraMakeFlags = [ "bl31" ];
      inherit platform;
      extraMeta.platforms = [ "aarch64-linux" ];
      filesToInstall = [ "build/${platform}/release/bl31/bl31.elf" ];
      platformCanUseHDCPBlob = true;
    };

  rk3568 =
    let
      platform = "rk3568";
    in
    buildArmTrustedFirmware {
      extraMakeFlags = [ "bl31" ];
      inherit platform;
      extraMeta.platforms = [ "aarch64-linux" ];
      filesToInstall = [ "build/${platform}/release/bl31/bl31.elf" ];
    };

  rk3588 =
    let
      platform = "rk3588";
    in
    buildArmTrustedFirmware {
      extraMakeFlags = [ "bl31" ];
      inherit platform;
      extraMeta.platforms = [ "aarch64-linux" ];
      filesToInstall = [ "build/${platform}/release/bl31/bl31.elf" ];
    };

  s905 =
    let
      platform = "gxbb";
    in
    buildArmTrustedFirmware {
      extraMakeFlags = [ "bl31" ];
      inherit platform;
      extraMeta.platforms = [ "aarch64-linux" ];
      filesToInstall = [ "build/${platform}/release/bl31.bin" ];
    };
}
