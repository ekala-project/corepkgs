# Adios port of ekaos/modules/boot/zswap.nix.
# TODO(adios-cutover) notes below mark semantics changed in translation.
{ types, ... }:

{
  options = {
    enable = {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable zswap, a compressed cache for swap pages.

        Zswap intercepts pages being swapped out and compresses them
        into a RAM-based pool, reducing I/O to the swap device and
        improving performance under memory pressure.
      '';
    };

    compressor = {
      type = types.enum "zswapCompressor" [
        "zstd"
        "lz4"
        "lzo"
        "lz4hc"
        "deflate"
        "842"
      ];
      default = "zstd";
      description = ''
        Compression algorithm for zswap.

        - zstd: Best compression ratio (default)
        - lz4: Fastest, lowest latency
        - lzo: Good balance of speed and ratio
        - lz4hc: High-compression variant of lz4
        - deflate: Higher compression, slower
        - 842: Hardware-accelerated on supported systems
      '';
    };

    zpool = {
      type = types.enum "zswapZpool" [
        "zsmalloc"
        "zbud"
      ];
      default = "zsmalloc";
      description = ''
        Kernel zpool allocator for zswap.

        zsmalloc is strongly recommended for kernels >= 6.3 as it offers
        the best memory density. zbud is the fallback for older kernels.
      '';
    };

    maxPoolPercent = {
      type = types.int;
      default = 25;
      description = ''
        Maximum percentage of system memory that zswap can occupy (1-100).

        Higher values provide more cache but increase memory pressure.
      '';
    };

    acceptThresholdPercent = {
      type = types.int;
      default = 90;
      description = ''
        Percentage below which zswap starts accepting pages again after
        the pool becomes full (1-100). Provides hysteresis to prevent
        pool oscillation.
      '';
    };

    shrinkerEnabled = {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable the zswap shrinker to reclaim memory
        under pressure.
      '';
    };
  };

  assertions = [
    {
      # Legacy type was types.ints.between 1 100.
      verify = { options, ... }: options.maxPoolPercent >= 1 && options.maxPoolPercent <= 100;
      explain = { options, ... }: "maxPoolPercent must be 1-100, got ${toString options.maxPoolPercent}";
    }
    {
      # Legacy type was types.ints.between 1 100.
      verify =
        { options, ... }: options.acceptThresholdPercent >= 1 && options.acceptThresholdPercent <= 100;
      explain =
        { options, ... }:
        "acceptThresholdPercent must be 1-100, got ${toString options.acceptThresholdPercent}";
    }
  ];

  impl =
    { options, ... }:
    if !options.enable then
      { }
    else
      {
        boot.kernelParams = [
          "zswap.enabled=1"
          "zswap.compressor=${options.compressor}"
          "zswap.zpool=${options.zpool}"
          "zswap.max_pool_percent=${toString options.maxPoolPercent}"
          "zswap.accept_threshold_percent=${toString options.acceptThresholdPercent}"
          "zswap.shrinker_enabled=${if options.shrinkerEnabled then "Y" else "N"}"
        ];

        boot.kernelModules = [
          options.compressor
          options.zpool
        ];

        boot.initrd.kernelModules = [
          options.compressor
          options.zpool
        ];
      };
}
