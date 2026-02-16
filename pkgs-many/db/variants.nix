{
  v4_8 = rec {
    version = "4.8.30";
    sha256 = "0ampbl2f0hb1nix195kz1syrqqxpmvnvnfvphambj7xjrl3iljg0";
    extraPatches = [
      ./clang-4.8.patch
      ./CVE-2017-10140-4.8-cwd-db_config.patch
      ./darwin-mutexes-4.8.patch
    ];
    drvArgs.hardeningDisable = [ "format" ];
    drvArgs.doCheck = false;
  };

  v5_3 = rec {
    version = "5.3.28";
    sha256 = "0a1n5hbl7027fbz5lm0vp0zzfp1hmxnz14wx3zl9563h83br5ag0";
    extraPatches = [
      ./clang-5.3.patch
      ./CVE-2017-10140-cwd-db_config.patch
      ./darwin-mutexes.patch
    ];
  };

  v6_0 = rec {
    version = "6.0.30";
    sha256 = "1lhglbvg65j5slrlv7qv4vi3cvd7kjywa07gq1abzschycf4p3k0";
    license = "agpl3Only";
    extraPatches = [
      ./clang-6.0.patch
      ./CVE-2017-10140-cwd-db_config.patch
      ./darwin-mutexes.patch
    ];
  };

  v6_2 = rec {
    version = "6.2.32";
    sha256 = "1yx8wzhch5wwh016nh0kfxvknjkafv6ybkqh6nh7lxx50jqf5id9";
    license = "agpl3Only";
    extraPatches = [
      ./clang-6.0.patch
      ./CVE-2017-10140-cwd-db_config.patch
      ./darwin-mutexes.patch
    ];
  };
}
