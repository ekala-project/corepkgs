{
  lib,
  config,
  buildPlatform,
  hostPlatform,
  fetchurl,
  checkMeta,
}:

lib.makeScope
  # Prevent using top-level attrs to protect against introducing dependency on
  # non-bootstrap packages by mistake. Any top-level inputs must be explicitly
  # declared here.
  (
    extra:
    lib.callPackageWith (
      {
        inherit
          lib
          config
          buildPlatform
          hostPlatform
          fetchurl
          checkMeta
          ;
      }
      // extra
    )
  )
  (
    self:
    with self;
    (
      {
        supportedSystems = [
          "i686-linux"
          "x86_64-linux"
        ];

        bash_2_05 = callPackage ./bash/2.nix { tinycc = tinycc-mes; };

        bash = callPackage ./bash {
          bootBash = bash_2_05;
          tinycc = tinycc-musl;
          coreutils = coreutils-musl;
          make = make-musl;
          tar = tar-musl;
        };

        bash-static = callPackage ./bash/static.nix {
          gcc-buildbuild = gcc-latest;
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        binutils = callPackage ./binutils {
          tinycc = tinycc-musl;
          make = make-musl;
          tar = tar-musl;
        };

        binutils-static = callPackage ./binutils/static.nix {
          gcc-buildbuild = gcc-latest;
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        bison = callPackage ./bison {
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        bzip2 = callPackage ./bzip2 {
          tinycc = tinycc-musl;
          make = make-musl;
          tar = tar-musl;
        };

        bzip2-static = callPackage ./bzip2/static.nix {
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        coreutils = callPackage ./coreutils { tinycc = tinycc-mes; };

        coreutils-musl = callPackage ./coreutils/musl.nix {
          bash = bash_2_05;
          tinycc = tinycc-musl;
          make = make-musl;
          tar = tar-musl;
        };
        coreutils-static = callPackage ./coreutils/static.nix {
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        diffutils = callPackage ./diffutils {
          bash = bash_2_05;
          tinycc = tinycc-musl;
          make = make-musl;
          tar = tar-musl;
        };

        diffutils-static = callPackage ./diffutils/static.nix {
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        findutils = callPackage ./findutils {
          tinycc = tinycc-musl;
          make = make-musl;
          tar = tar-musl;
        };

        findutils-static = callPackage ./findutils/static.nix {
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        gawk-mes = callPackage ./gawk/mes.nix {
          bash = bash_2_05;
          tinycc = tinycc-mes;
          sed = sed-mes;
        };

        gawk = callPackage ./gawk {
          bash = bash_2_05;
          tinycc = tinycc-musl;
          make = make-musl;
          tar = tar-musl;
          bootGawk = gawk-mes;
        };

        gcc46 = callPackage ./gcc/4.6.nix {
          tinycc = tinycc-musl;
          make = make-musl;
          tar = tar-musl;
        };

        gcc46-cxx = callPackage ./gcc/4.6.cxx.nix {
          gcc = gcc46;
          make = make-musl;
          tar = tar-musl;
        };

        gcc10 = callPackage ./gcc/10.nix {
          gcc = gcc46-cxx;
          make = make-musl;
          tar = tar-latest;
        };

        gcc-latest-unwrapped = callPackage ./gcc/latest.nix {
          gcc = gcc10;
          make = make-musl;
          tar = tar-latest;
        };
        gcc-latest = callPackage ./gcc/wrapper.nix {
          bash-build = bash;
          gcc-unwrapped = gcc-latest-unwrapped;
          targetPlatform = hostPlatform;
          libc = musl;
          libgcc = gcc-latest-unwrapped;
          libstdcxx = gcc-latest-unwrapped;
        };

        grep = callPackage ./grep {
          bash = bash_2_05;
          tinycc = tinycc-mes;
        };

        grep-static = callPackage ./grep/static.nix {
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        gnum4 = callPackage ./gnum4 {
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        make = callPackage ./make { tinycc = tinycc-bootstrappable; };

        make-musl = callPackage ./make/musl.nix {
          bash = bash_2_05;
          tinycc = tinycc-musl;
          gawk = gawk-mes;
          makeBoot = make;
          # GNU Make's release tarball relies on preserved mtimes for
          # pregenerated Autotools files.
          tar = tar-musl;
        };

        make-static = callPackage ./make/static.nix {
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        patch = callPackage ./patch { tinycc = tinycc-mes; };

        patch-static = callPackage ./patch/static.nix {
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        sed = callPackage ./sed {
          bash = bash_2_05;
          tinycc = tinycc-musl;
          sed = sed-mes;
        };

        sed-mes = callPackage ./sed/mes.nix {
          bash = bash_2_05;
          tinycc = tinycc-bootstrappable;
        };

        sed-static = callPackage ./sed/static.nix {
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        tar = callPackage ./tar/mes.nix {
          bash = bash_2_05;
          tinycc = tinycc-mes;
          sed = sed-mes;
        };

        # FIXME: better package naming scheme
        tar-latest = callPackage ./tar/latest.nix {
          gcc = gcc46;
          make = make-musl;
          tarBoot = tar-musl;
        };

        tar-musl = callPackage ./tar/musl.nix {
          bash = bash_2_05;
          tinycc = tinycc-musl;
          sed = sed-mes;
        };

        tar-static = callPackage ./tar/static.nix {
          gcc = gcc-latest;
          make = make-musl;
          tarBoot = tar-latest;
        };

        gzip-static = callPackage ./gzip/static.nix {
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        gzip = callPackage ./gzip {
          bash = bash_2_05;
          tinycc = tinycc-bootstrappable;
          sed = sed-mes;
        };

        heirloom = callPackage ./heirloom {
          bash = bash_2_05;
          tinycc = tinycc-mes;
        };

        heirloom-devtools = callPackage ./heirloom-devtools { tinycc = tinycc-mes; };

        libgmp = callPackage ./gcc/gmp.nix {
          gcc-buildbuild = gcc-latest;
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        libmpc = callPackage ./gcc/mpc.nix {
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        libmpfr = callPackage ./gcc/mpfr.nix {
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        linux-headers = callPackage ./linux-headers {
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        ln-boot = callPackage ./ln-boot { };

        mes = callPackage ./mes { };

        mes-libc = callPackage ./mes/libc.nix { };

        musl-tcc-intermediate = callPackage ./musl/tcc.nix {
          bash = bash_2_05;
          tinycc = tinycc-mes;
          sed = sed-mes;
        };

        musl-tcc = callPackage ./musl/tcc.nix {
          bash = bash_2_05;
          tinycc = tinycc-musl-intermediate;
          sed = sed-mes;
        };

        musl = callPackage ./musl {
          gcc = gcc46;
          make = make-musl;
        };

        musl-headers = callPackage ./musl/headers.nix {
          gcc = gcc46;
          make = make-musl;
          tar = tar-latest;
        };

        musl-static = callPackage ./musl/static.nix {
          libgcc = gcc-latest-unwrapped;
          gcc = gcc-latest;
          make = make-musl;
        };

        patchelf-static = callPackage ./patchelf/static.nix {
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        python = callPackage ./python {
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        stage0-posix = callPackage ./stage0-posix { };

        inherit (self.stage0-posix)
          kaem
          m2libc
          mescc-tools
          mescc-tools-extra
          ;

        tinycc-bootstrappable = lib.recurseIntoAttrs (callPackage ./tinycc/bootstrappable.nix { });

        tinycc-mes = lib.recurseIntoAttrs (callPackage ./tinycc/mes.nix { });

        tinycc-musl-intermediate = lib.recurseIntoAttrs (
          callPackage ./tinycc/musl.nix {
            bash = bash_2_05;
            musl = musl-tcc-intermediate;
            tinycc = tinycc-mes;
          }
        );

        tinycc-musl = lib.recurseIntoAttrs (
          callPackage ./tinycc/musl.nix {
            bash = bash_2_05;
            musl = musl-tcc;
            tinycc = tinycc-musl-intermediate;
          }
        );

        gawk-static = callPackage ./gawk/static.nix {
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        xz = callPackage ./xz {
          bash = bash_2_05;
          tinycc = tinycc-musl;
          make = make-musl;
          tar = tar-musl;
        };

        xz-static = callPackage ./xz/static.nix {
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        zlib = callPackage ./zlib {
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        inherit (callPackage ./utils.nix { inherit hostPlatform; })
          derivationWithMeta
          writeTextFile
          writeText
          ;

        tests = {
          bootstrap-chain = kaem.runCommand "minimal-bootstrap-bootstrap-chain-test" { } ''
            echo ${bash.tests.get-version}
            echo ${bash_2_05.tests.get-version}
            echo ${binutils.tests.get-version}
            echo ${bison.tests.get-version}
            echo ${bzip2.tests.get-version}
            echo ${coreutils-musl.tests.get-version}
            echo ${diffutils.tests.get-version}
            echo ${findutils.tests.get-version}
            echo ${gawk.tests.get-version}
            echo ${gawk-mes.tests.get-version}
            echo ${grep.tests.get-version}
            echo ${gnum4.tests.get-version}
            echo ${make-musl.tests.get-version}
            echo ${sed.tests.get-version}
            echo ${sed-mes.tests.get-version}
            echo ${tar.tests.get-version}
            echo ${tar-latest.tests.get-version}
            echo ${tar-musl.tests.get-version}
            echo ${gzip.tests.get-version}
            echo ${heirloom.tests.get-version}
            echo ${mes.compiler.tests.get-version}
            echo ${musl.tests.hello-world}
            echo ${python.tests.get-version}
            echo ${tinycc-mes.compiler.tests.chain}
            echo ${tinycc-musl.compiler.tests.hello-world}
            echo ${xz.tests.get-version}
            mkdir ''${out}
          '';

          static-tools = kaem.runCommand "minimal-bootstrap-static-tools-test" { } ''
            echo ${bash-static.tests.get-version}
            echo ${binutils-static.tests.get-version}
            echo ${bzip2-static.tests.get-version}
            echo ${bzip2-static.tests.compress}
            echo ${coreutils-static.tests.get-version}
            echo ${diffutils-static.tests.get-version}
            echo ${findutils-static.tests.get-version}
            echo ${gawk-static.tests.get-version}
            echo ${grep-static.tests.get-version}
            echo ${make-static.tests.get-version}
            echo ${patch-static.tests.get-version}
            echo ${sed-static.tests.get-version}
            echo ${tar-static.tests.get-version}
            echo ${gzip-static.tests.get-version}
            echo ${patchelf-static.tests.get-version}
            echo ${xz-static.tests.get-version}
            mkdir ''${out}
          '';

          compiler = kaem.runCommand "minimal-bootstrap-compiler-test" { } (
            ''
              echo ${gcc46.tests.get-version}
              echo ${gcc46-cxx.tests.hello-world}
              echo ${gcc10.tests.hello-world}
              echo ${gcc-latest-unwrapped.tests.hello-world}
            ''
            + (lib.strings.optionalString (hostPlatform.libc == "glibc") ''
              echo ${gcc-glibc.tests.hello-world}
              echo ${glibc.tests.hello-world}
            '')
            + ''
              mkdir ''${out}
            ''
          );

          full = kaem.runCommand "minimal-bootstrap-test" { } ''
            echo ${tests.bootstrap-chain}
            echo ${tests.static-tools}
            echo ${tests.compiler}
            mkdir ''${out}
          '';
        };

        test = tests.full;
      }
      // (lib.optionalAttrs (hostPlatform.libc == "glibc")) {
        gcc-glibc = callPackage ./gcc/glibc.nix {
          gcc = gcc-latest;
          make = make-musl;
          tar = tar-latest;
        };

        glibc = callPackage ./glibc {
          gcc = gcc-latest-unwrapped;
          make = make-musl;
          tar = tar-latest;
          grep = grep-static;
        };

        glibc-headers = callPackage ./glibc/headers.nix {
          gcc = gcc-latest;
          binutils-build = binutils;
          make = make-musl;
          tar = tar-latest;
        };
      }
    )
  )
