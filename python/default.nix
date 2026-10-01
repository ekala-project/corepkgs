{
  __splicedPackages,
  callPackage,
  config,
  db,
  lib,
  makeScopeWithSplicing',
  mkManyVariants,
  pythonPackagesExtensions ? [ ],
  stdenv,
}:

(
  let

    # Common passthru for all Python interpreters.
    passthruFun = import ./passthrufun.nix {
      inherit
        lib
        config
        makeScopeWithSplicing'
        stdenv
        callPackage
        pythonPackagesExtensions
        ;
    };

    cpython = callPackage (mkManyVariants {
      variants = ./cpython-variants.nix;
      aliases = { };
      name = "cpython";
      eol = { };
      removed = { };
      defaultSelector = (p: p.v3_13);
      genericBuilder = ./cpython-generic.nix;
      inherit callPackage;
    }) { };

  in
  {

    # CPython interpreters
    python310 = cpython.v3_10;
    python311 = cpython.v3_11;
    python312 = cpython.v3_12;
    python313 = cpython.v3_13;
    python314 = cpython.v3_14;
    python315 = cpython.v3_15;
    python3Minimal = cpython.minimal;

    python27 = callPackage ./cpython/2.7 {
      self = __splicedPackages.python27;
      sourceVersion = {
        major = "2";
        minor = "7";
        patch = "18";
        suffix = ".12"; # ActiveState's Python 2 extended support
      };
      hash = "sha256-RuEgfpags9wJm9Xe0daotqUx4knABEUc7DvtgnQXEfE=";
      inherit passthruFun;
    };

    pypy27 = callPackage ./pypy {
      self = __splicedPackages.pypy27;
      sourceVersion = {
        major = "7";
        minor = "3";
        patch = "19";
      };

      hash = "sha256-hwPNywH5+Clm3UO2pgGPFAOZ21HrtDwSXB+aIV57sAM=";
      pythonVersion = "2.7";
      db = db.override { dbmSupport = !stdenv.hostPlatform.isDarwin; };
      python = __splicedPackages.pythonInterpreters.pypy27_prebuilt;
      inherit passthruFun;
    };

    pypy310 = callPackage ./pypy {
      self = __splicedPackages.pypy310;
      sourceVersion = {
        major = "7";
        minor = "3";
        patch = "19";
      };

      hash = "sha256-p8IpMLkY9Ahwhl7Yp0FH9ENO+E09bKKzweupNV1JKcg=";
      pythonVersion = "3.10";
      db = db.override { dbmSupport = !stdenv.hostPlatform.isDarwin; };
      python = __splicedPackages.pypy27;
      inherit passthruFun;
    };

    pypy311 = callPackage ./pypy {
      self = __splicedPackages.pypy311;
      sourceVersion = {
        major = "7";
        minor = "3";
        patch = "20";
      };

      hash = "sha256-d4bdp2AAPi6nQJwQN+UCAMV47EJ84CRaxM11hxCyBvs=";
      pythonVersion = "3.11";
      db = db.override { dbmSupport = !stdenv.hostPlatform.isDarwin; };
      python = __splicedPackages.pypy27;
      inherit passthruFun;
    };

    pypy27_prebuilt = callPackage ./pypy/prebuilt_2_7.nix {
      # Not included at top-level
      self = __splicedPackages.pythonInterpreters.pypy27_prebuilt;
      sourceVersion = {
        major = "7";
        minor = "3";
        patch = "19";
      };

      hash =
        {
          aarch64-linux = "sha256-/onU/UrxP3bf5zFZdQA1GM8XZSDjzOwVRKiNF09QkQ4=";
          x86_64-linux = "sha256-04RFUIwurxTrs4DZwd7TIcXr6uMcfmaAAXPYPLjd9CM=";
          aarch64-darwin = "sha256-KHgOC5CK1ttLTglvQjcSS+eezJcxlG2EDZyHSetnp1k=";
        }
        .${stdenv.system};
      pythonVersion = "2.7";
      inherit passthruFun;
    };

    pypy310_prebuilt = callPackage ./pypy/prebuilt.nix {
      # Not included at top-level
      self = __splicedPackages.pythonInterpreters.pypy310_prebuilt;
      sourceVersion = {
        major = "7";
        minor = "3";
        patch = "19";
      };
      hash =
        {
          aarch64-linux = "sha256-ryeliRePERmOIkSrZcpRBjC6l8Ex18zEAh61vFjef1c=";
          x86_64-linux = "sha256-xzrCzCOArJIn/Sl0gr8qPheoBhi6Rtt1RNU1UVMh7B4=";
          aarch64-darwin = "sha256-PbigP8SWFkgBZGhE1/OxK6oK2zrZoLfLEkUhvC4WijY=";
        }
        .${stdenv.system};
      pythonVersion = "3.10";
      inherit passthruFun;
    };

    pypy311_prebuilt = callPackage ./pypy/prebuilt.nix {
      # Not included at top-level
      self = __splicedPackages.pythonInterpreters.pypy311_prebuilt;
      sourceVersion = {
        major = "7";
        minor = "3";
        patch = "19";
      };
      hash =
        {
          aarch64-linux = "sha256-EyB9v4HOJOltp2CxuGNie3e7ILH7TJUZHgKgtyOD33Q=";
          x86_64-linux = "sha256-kXfZ4LuRsF+SHGQssP9xoPNlO10ppC1A1qB4wVt1cg8=";
          aarch64-darwin = "sha256-dwTg1TAuU5INMtz+mv7rEENtTJQjPogwz2A6qVWoYcE=";
        }
        .${stdenv.system};
      pythonVersion = "3.11";
      inherit passthruFun;
    };
  }
)
