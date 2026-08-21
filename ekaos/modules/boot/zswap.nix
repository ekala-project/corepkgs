# Zswap — compressed cache for swap pages
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.boot.zswap;
in

{
  options = {
    boot.zswap = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable zswap, a compressed cache for swap pages.

          Zswap intercepts pages being swapped out and compresses them
          into a RAM-based pool, reducing I/O to the swap device and
          improving performance under memory pressure.
        '';
      };

      compressor = mkOption {
        type = types.enum [
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

      zpool = mkOption {
        type = types.enum [
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

      maxPoolPercent = mkOption {
        type = types.ints.between 1 100;
        default = 25;
        description = ''
          Maximum percentage of system memory that zswap can occupy (1-100).

          Higher values provide more cache but increase memory pressure.
        '';
      };

      acceptThresholdPercent = mkOption {
        type = types.ints.between 1 100;
        default = 90;
        description = ''
          Percentage below which zswap starts accepting pages again after
          the pool becomes full (1-100). Provides hysteresis to prevent
          pool oscillation.
        '';
      };

      shrinkerEnabled = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to enable the zswap shrinker to reclaim memory
          under pressure.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    boot.kernelParams = [
      "zswap.enabled=1"
      "zswap.compressor=${cfg.compressor}"
      "zswap.zpool=${cfg.zpool}"
      "zswap.max_pool_percent=${toString cfg.maxPoolPercent}"
      "zswap.accept_threshold_percent=${toString cfg.acceptThresholdPercent}"
      "zswap.shrinker_enabled=${if cfg.shrinkerEnabled then "Y" else "N"}"
    ];

    # Ensure the compressor and zpool modules are available
    boot.kernelModules = [
      cfg.compressor
      cfg.zpool
    ];

    boot.initrd.kernelModules = [
      cfg.compressor
      cfg.zpool
    ];
  };
}
