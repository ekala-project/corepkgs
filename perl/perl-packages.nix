/*
  This file defines the composition for CPAN (Perl) packages.  It has
  been factored out of top-level.nix because there are so many of
  them.  Also, because most Nix expressions for CPAN packages are
  trivial, most are actually defined here.  I.e. there's no function
  for each package in a separate file: the call to the function would
  be almost as much code as the function itself.
*/

{
  config,
  stdenv,
  lib,
  buildPackages,
  pkgs,
  fetchurl,
  fetchpatch,
  fetchpatch2,
  fetchDebianPatch,
  fetchFromGitHub,
  fetchFromGitLab,
  perl,
  shortenPerlShebang,
}:

self:

# cpan2nix assumes that perl-packages.nix will be used only with perl 5.30.3 or above
assert lib.versionAtLeast perl.version "5.30.3";
with self;
{

  inherit perl;
  perlPackages = self;

  # Check whether a derivation provides a perl module.
  hasPerlModule = drv: drv ? perlModule;

  requiredPerlModules =
    drvs:
    let
      modules = lib.filter hasPerlModule drvs;
    in
    lib.unique ([ perl ] ++ modules ++ lib.concatLists (lib.catAttrs "requiredPerlModules" modules));

  # Convert derivation to a perl module.
  toPerlModule =
    drv:
    drv.overrideAttrs (oldAttrs: {
      # Use passthru in order to prevent rebuilds when possible.
      passthru = (oldAttrs.passthru or { }) // {
        perlModule = perl;
        requiredPerlModules = requiredPerlModules drv.propagatedBuildInputs;
      };
    });

  buildPerlPackage = callPackage ./buildPerlPackage { };

  # Helper functions for packages that use Module::Build to build.
  buildPerlModule =
    args:
    buildPerlPackage (
      {
        buildPhase = ''
          runHook preBuild
          perl Build.PL --prefix=$out; ./Build build
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          ./Build install
          runHook postInstall
        '';
        checkPhase = ''
          runHook preCheck
          ./Build test
          runHook postCheck
        '';
      }
      // args
      // {
        preConfigure = ''
          touch Makefile.PL
          ${args.preConfigure or ""}
        '';
        buildInputs = (args.buildInputs or [ ]) ++ [ ModuleBuild ];
      }
    );

  /*
    Construct a perl search path (such as $PERL5LIB)

    Example:
      pkgs = import <nixpkgs> { }
      makePerlPath [ pkgs.perlPackages.libnet ]
      => "/nix/store/n0m1fk9c960d8wlrs62sncnadygqqc6y-perl-Net-SMTP-1.25/lib/perl5/site_perl"
  */
  makePerlPath = lib.makeSearchPathOutput "lib" perl.libPrefix;

  /*
    Construct a perl search path recursively including all dependencies (such as $PERL5LIB)

    Example:
      pkgs = import <nixpkgs> { }
      makeFullPerlPath [ pkgs.perlPackages.CGI ]
      => "/nix/store/fddivfrdc1xql02h9q500fpnqy12c74n-perl-CGI-4.38/lib/perl5/site_perl:/nix/store/8hsvdalmsxqkjg0c5ifigpf31vc4vsy2-perl-HTML-Parser-3.72/lib/perl5/site_perl:/nix/store/zhc7wh0xl8hz3y3f71nhlw1559iyvzld-perl-HTML-Tagset-3.20/lib/perl5/site_perl"
  */
  makeFullPerlPath = deps: makePerlPath (lib.misc.closePropagation deps);

  AlgorithmDiff = buildPerlPackage {
    pname = "Algorithm-Diff";
    version = "1.1903";
    src = fetchurl {
      url = "mirror://cpan/authors/id/T/TY/TYEMQ/Algorithm-Diff-1.1903.tar.gz";
      hash = "sha256-MOhKxLMdQLZik/exIhMxxaUFYaOdWA2FAE2cH/+ZF1E=";
    };
    buildInputs = [ pkgs.unzip ];
    meta = {
      description = "Compute 'intelligent' differences between two files / lists";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  AppFatPacker = buildPerlPackage {
    pname = "App-FatPacker";
    version = "0.010008";
    src = fetchurl {
      url = "mirror://cpan/authors/id/M/MS/MSTROUT/App-FatPacker-0.010008.tar.gz";
      hash = "sha256-Ep2zbchFZhpYIoaBDP4tUhbrLOCCutQK4fzc4PRd7M8=";
    };
    meta = {
      description = "Pack your dependencies onto your script file";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
      mainProgram = "fatpack";
    };
  };

  ArchiveZip = buildPerlPackage {
    pname = "Archive-Zip";
    version = "1.68";
    src = fetchurl {
      url = "mirror://cpan/authors/id/P/PH/PHRED/Archive-Zip-1.68.tar.gz";
      hash = "sha256-mE4YXXhbr2EpxudfjrREEXRawAv2Ei+xyOgio4YexlA=";
    };
    buildInputs = [ TestMockModule ];
    meta = {
      description = "Provide an interface to ZIP archive files";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
      mainProgram = "crc32";
    };
  };

  AuthenSASL = buildPerlPackage {
    pname = "Authen-SASL";
    version = "2.1900";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/EH/EHUELS/Authen-SASL-2.1900.tar.gz";
      hash = "sha256-vjUzpokbLmdxULR5waDUvxHIu+6+0+e466NAU+k5I7A=";
    };
    propagatedBuildInputs = [
      CryptURandom
      DigestHMAC
    ];
    meta = {
      description = "SASL Authentication framework";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  BC = buildPerlPackage {
    pname = "B-C";
    version = "1.57";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RU/RURBAN/B-C-1.57.tar.gz";
      hash = "sha256-BFKmEdNDrfnZX86ra6a2YXbjrX/MzlKAkiwOQx9RSf8=";
    };
    propagatedBuildInputs = [
      BFlags
      IPCRun
      Opcodes
    ];
    env = lib.optionalAttrs stdenv.cc.isGNU {
      NIX_CFLAGS_COMPILE = "-Wno-error=incompatible-pointer-types";
    };
    doCheck = false; # test fails
    meta = {
      description = "Perl compiler";
      homepage = "https://github.com/rurban/perl-compiler";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
      mainProgram = "perlcc";
    };
  };

  BCOW = buildPerlPackage {
    pname = "B-COW";
    version = "0.007";
    src = fetchurl {
      url = "mirror://cpan/authors/id/A/AT/ATOOMIC/B-COW-0.007.tar.gz";
      hash = "sha256-EpDa8ifosJiJoxzxguKRBvHPnxpOm/d1L53pLtEVi0Q=";
    };
    meta = {
      description = "B::COW additional B helpers to check COW status";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  BFlags = buildPerlPackage {
    pname = "B-Flags";
    version = "0.17";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RU/RURBAN/B-Flags-0.17.tar.gz";
      hash = "sha256-wduX0BMVvtEJtMSJWM0yGVz8nvXTt3B+tHhAwdV8ELI=";
    };
    meta = {
      description = "Friendlier flags for B";
      license = with lib.licenses; [
        artistic1
        gpl1Only
      ];
    };
  };

  BHooksEndOfScope = buildPerlPackage {
    pname = "B-Hooks-EndOfScope";
    version = "0.26";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETHER/B-Hooks-EndOfScope-0.26.tar.gz";
      hash = "sha256-Od8vjAB6dUZyB1+VuQeXuuvpetptlEsZemNScJyzBnE=";
    };
    propagatedBuildInputs = [
      ModuleImplementation
      SubExporterProgressive
    ];
    meta = {
      description = "Execute code after a scope finished compilation";
      homepage = "https://github.com/karenetheridge/B-Hooks-EndOfScope";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  boolean = buildPerlPackage {
    pname = "boolean";
    version = "0.46";
    src = fetchurl {
      url = "mirror://cpan/authors/id/I/IN/INGY/boolean-0.46.tar.gz";
      hash = "sha256-lcCICFw+g79oD+bOFtgmTsJjEEkPfRaA5BbqehGPFWo=";
    };
    meta = {
      description = "Boolean support for Perl";
      homepage = "https://github.com/ingydotnet/boolean-pm";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  CaptureTiny = buildPerlPackage {
    pname = "Capture-Tiny";
    version = "0.48";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DA/DAGOLDEN/Capture-Tiny-0.48.tar.gz";
      hash = "sha256-bCMRPoe605MwjJCiBwE+UF9lknRzZjjYx5usnGfMPhk=";
    };
    meta = {
      description = "Capture STDOUT and STDERR from Perl, XS or external programs";
      homepage = "https://github.com/dagolden/Capture-Tiny";
      license = with lib.licenses; [ asl20 ];
    };
  };

  CGI = buildPerlPackage {
    pname = "CGI";
    version = "4.59";
    src = fetchurl {
      url = "mirror://cpan/authors/id/L/LE/LEEJO/CGI-4.59.tar.gz";
      hash = "sha256-be5LibiLEOd8lvPAjRm1hq74M7F6Ql1hiq19KMJi+Rw=";
    };
    buildInputs = [
      TestDeep
      TestNoWarnings
      TestWarn
    ];
    propagatedBuildInputs = [ HTMLParser ];
    meta = {
      description = "Handle Common Gateway Interface requests and responses";
      homepage = "https://metacpan.org/module/CGI";
      license = with lib.licenses; [ artistic2 ];
    };
  };

  CGIFast = buildPerlPackage {
    pname = "CGI-Fast";
    version = "2.16";
    src = fetchurl {
      url = "mirror://cpan/authors/id/L/LE/LEEJO/CGI-Fast-2.16.tar.gz";
      hash = "sha256-AiPX+RuAA3ud/183NgZAtx9dyNvZiaBZPV0i8/c8s9Q=";
    };
    propagatedBuildInputs = [
      CGI
      FCGI
    ];
    doCheck = false;
    meta = {
      description = "CGI Interface for Fast CGI";
      homepage = "https://metacpan.org/module/CGI::Fast";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ClassDataInheritable = buildPerlPackage {
    pname = "Class-Data-Inheritable";
    version = "0.09";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RS/RSHERER/Class-Data-Inheritable-0.09.tar.gz";
      hash = "sha256-RAiNbpBxLhh7ilsFDKWxxw7+K6oyrhI+m9j1nynwbk0=";
    };
    meta = {
      description = "Inheritable, overridable class data";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ClassInspector = buildPerlPackage {
    pname = "Class-Inspector";
    version = "1.36";
    src = fetchurl {
      url = "mirror://cpan/authors/id/P/PL/PLICEASE/Class-Inspector-1.36.tar.gz";
      hash = "sha256-zCldI6RyaHwkSJ1YIm6tI7n9wliOUi8LXwdHdBcAaU4=";
    };
    meta = {
      description = "Get information about a class and its structure";
      homepage = "https://metacpan.org/pod/Class::Inspector";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ClassMethodModifiers = buildPerlPackage {
    pname = "Class-Method-Modifiers";
    version = "2.15";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETHER/Class-Method-Modifiers-2.15.tar.gz";
      hash = "sha256-Zc2Fv+R10GbpGG96jMY2BwmFswsOuxzehoHPBiwuFfw=";
    };
    buildInputs = [
      TestFatal
      TestNeeds
    ];
    meta = {
      description = "Provides Moose-like method modifiers";
      homepage = "https://github.com/moose/Class-Method-Modifiers";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ClassLoad = buildPerlPackage {
    pname = "Class-Load";
    version = "0.25";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETHER/Class-Load-0.25.tar.gz";
      hash = "sha256-Kkj6d5tSl+VhVjgOizJjfGxY3stPSn88c1BSPhEnX48=";
    };
    buildInputs = [
      TestFatal
      TestNeeds
    ];
    propagatedBuildInputs = [
      DataOptList
      PackageStash
    ];
    meta = {
      description = "Working (require \"Class::Name\") and more";
      homepage = "https://github.com/moose/Class-Load";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ClassLoadXS = buildPerlPackage {
    pname = "Class-Load-XS";
    version = "0.10";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETHER/Class-Load-XS-0.10.tar.gz";
      hash = "sha256-W8Is9Tbr/SVkxb2vQvDYpM7j0ZMPyLRLfUpCA4YirdE=";
    };
    buildInputs = [
      TestFatal
      TestNeeds
    ];
    propagatedBuildInputs = [ ClassLoad ];
    meta = {
      description = "XS implementation of parts of Class::Load";
      homepage = "https://github.com/moose/Class-Load-XS";
      license = with lib.licenses; [ artistic2 ];
    };
  };

  Clone = buildPerlPackage {
    pname = "Clone";
    version = "0.46";
    src = fetchurl {
      url = "mirror://cpan/authors/id/G/GA/GARU/Clone-0.46.tar.gz";
      hash = "sha256-qt7tXkyL1rvfaMDdAGbLUT4Wq55bQ4LcSgqv1ViQaXs=";
    };
    buildInputs = [ BCOW ];
    meta = {
      description = "Recursively copy Perl datatypes";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  CompressBzip2 = buildPerlPackage {
    pname = "Compress-Bzip2";
    version = "2.28";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RU/RURBAN/Compress-Bzip2-2.28.tar.gz";
      hash = "sha256-hZ+DXD9cmYgQ2LKm+eKC/5nWy2bM+lXK5+Ztr7A1EW4=";
    };
    meta = {
      description = "Interface to Bzip2 compression library";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  CPAN = buildPerlPackage {
    pname = "CPAN";
    version = "2.36";
    src = fetchurl {
      url = "mirror://cpan/authors/id/A/AN/ANDK/CPAN-2.36.tar.gz";
      hash = "sha256-HXKl60DliOPBDx88hckC6HGxaDdH1ncjOvd3yCv8kJ4=";
    };
    propagatedBuildInputs = [
      ArchiveZip
      CPANChecksums
      CPANPerlReleases
      CompressBzip2
      Expect
      FileHomeDir
      FileWhich
      LWP
      LogLog4perl
      ModuleSignature
      TermReadKey
      TextGlob
      YAML
      YAMLLibYAML
      YAMLSyck
      IOSocketSSL
    ];
    meta = {
      description = "Query, download and build perl modules from CPAN sites";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
      mainProgram = "cpan";
    };
  };

  CPANChecksums = buildPerlPackage {
    pname = "CPAN-Checksums";
    version = "2.14";
    src = fetchurl {
      url = "mirror://cpan/authors/id/A/AN/ANDK/CPAN-Checksums-2.14.tar.gz";
      hash = "sha256-QIBxbF2n4DtQTjzA6h/V757WkV9vtzdWTp4T01Wonjk=";
    };
    propagatedBuildInputs = [
      CompressBzip2
      DataCompare
      ModuleSignature
    ];
    meta = {
      description = "Write a CHECKSUMS file for a directory as on CPAN";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  CPANMetaCheck = buildPerlPackage {
    pname = "CPAN-Meta-Check";
    version = "0.018";
    src = fetchurl {
      url = "mirror://cpan/authors/id/L/LE/LEONT/CPAN-Meta-Check-0.018.tar.gz";
      hash = "sha256-9hnS316g/ZHIz4PrVKzMteQ9nm7Bo/cns9CsFdDPN4o=";
    };
    buildInputs = [ TestDeep ];
    meta = {
      description = "Verify requirements in a CPAN::Meta object";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  CPANPerlReleases = buildPerlPackage {
    pname = "CPAN-Perl-Releases";
    version = "5.20230920";
    src = fetchurl {
      url = "mirror://cpan/authors/id/B/BI/BINGOS/CPAN-Perl-Releases-5.20230920.tar.gz";
      hash = "sha256-MbyTiJR2uOx1iRjdmSSmKYPgh7BsjN6Sb7mnp+h60cA=";
    };
    meta = {
      description = "Mapping Perl releases on CPAN to the location of the tarballs";
      homepage = "https://github.com/bingos/cpan-perl-releases";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  CryptRC4 = buildPerlPackage {
    pname = "Crypt-RC4";
    version = "2.02";
    src = fetchurl {
      url = "mirror://cpan/authors/id/S/SI/SIFUKURT/Crypt-RC4-2.02.tar.gz";
      hash = "sha256-XsRCXGvCIgeIljC+c1DZlobmKkTGE2lgEQIDzVlK4Oo=";
    };
    meta = {
      description = "Perl implementation of the RC4 encryption algorithm";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  CryptURandom = buildPerlPackage {
    pname = "Crypt-URandom";
    version = "0.54";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DD/DDICK/Crypt-URandom-0.54.tar.gz";
      hash = "sha256-SnPNOUkzMo2khKrrhkXXNbNUZd9gEJ5VngoosGYFOlc=";
    };
    meta = {
      description = "Provide non blocking randomness";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];

    };
  };

  CwdGuard = buildPerlModule {
    pname = "Cwd-Guard";
    version = "0.05";
    src = fetchurl {
      url = "mirror://cpan/authors/id/K/KA/KAZEBURO/Cwd-Guard-0.05.tar.gz";
      hash = "sha256-evx8orlQLkQCQZOK2Xo+fr1VAYDr1hQuHbOUGGsmjnc=";
    };
    buildInputs = [ TestRequires ];
    meta = {
      description = "Temporary changing working directory (chdir)";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  DataCompare = buildPerlPackage {
    pname = "Data-Compare";
    version = "1.29";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DC/DCANTRELL/Data-Compare-1.29.tar.gz";
      hash = "sha256-U8nbO5MmPIiqo8QHLYGere0CTXo2s4wMN3N9KI1a+ow=";
    };
    propagatedBuildInputs = [
      Clone
      FileFindRule
    ];
    meta = {
      description = "Compare perl data structures";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  DataOptList = buildPerlPackage {
    pname = "Data-OptList";
    version = "0.114";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RJ/RJBS/Data-OptList-0.114.tar.gz";
      hash = "sha256-n9EJO5F6Ift5rhYH21PRE7TgrY/grndssHen5QBE/fM=";
    };
    propagatedBuildInputs = [
      ParamsUtil
      SubInstall
    ];
    meta = {
      description = "Parse and validate simple name/value option pairs";
      homepage = "https://github.com/rjbs/Data-OptList";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  DataUUID = buildPerlPackage {
    pname = "Data-UUID";
    version = "1.226";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RJ/RJBS/Data-UUID-1.226.tar.gz";
      hash = "sha256-CT1X/6DUEalLr6+uSVaX2yb1ydAncZj+P3zyviKZZFM=";
    };
    patches = [
      ./patches/Data-UUID-CVE-2013-4184.patch
    ];
    meta = {
      description = "Globally/Universally Unique Identifiers (GUIDs/UUIDs)";
      license = with lib.licenses; [ bsd0 ];
    };
  };

  DevelCheckBin = buildPerlPackage {
    pname = "Devel-CheckBin";
    version = "0.04";
    src = fetchurl {
      url = "mirror://cpan/authors/id/T/TO/TOKUHIROM/Devel-CheckBin-0.04.tar.gz";
      hash = "sha256-FX89tZwp7R1JEzpGnO53LIha1O5k6GkqkbPr/b4v4+Q=";
    };
    meta = {
      description = "Check that a command is available";
      homepage = "https://github.com/tokuhirom/Devel-CheckBin";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  DevelCheckCompiler = buildPerlModule {
    pname = "Devel-CheckCompiler";
    version = "0.07";
    src = fetchurl {
      url = "mirror://cpan/authors/id/S/SY/SYOHEX/Devel-CheckCompiler-0.07.tar.gz";
      hash = "sha256-dot2l7S41NNyx1B7ZendJqpCI/cQAYO7tNOvRtQ4abU=";
    };
    buildInputs = [ ModuleBuildTiny ];
    meta = {
      description = "Check the compiler's availability";
      homepage = "https://github.com/tokuhirom/Devel-CheckCompiler";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  DBDSQLite = buildPerlPackage {
    pname = "DBD-SQLite";
    version = "1.74";

    src = fetchurl {
      url = "mirror://cpan/authors/id/I/IS/ISHIGAKI/DBD-SQLite-1.74.tar.gz";
      hash = "sha256-iZSZfYS5/rRUd5X3h0bGYfty48tqJdvdeJtzH1aIpN0=";
    };

    propagatedBuildInputs = [ DBI ];
    buildInputs = [ pkgs.sqlite ];

    patches = [
      # Support building against our own sqlite.
      ./patches/DBD-SQLite/external-sqlite.patch

      # Pull upstream fix for test failures against sqlite-3.37.
      (fetchpatch {
        name = "sqlite-3.37-compat.patch";
        url = "https://github.com/DBD-SQLite/DBD-SQLite/commit/ba4f472e7372dbf453444c7764d1c342e7af12b8.patch";
        hash = "sha256-nn4JvaIGlr2lUnUC+0ABe9AFrRrC5bfdTQiefo0Pjwo=";
      })
    ];

    makeMakerFlags = [
      "SQLITE_INC=${pkgs.sqlite.dev}/include"
      "SQLITE_LIB=${pkgs.sqlite.out}/lib"
    ];

    postInstall = ''
      # Get rid of a pointless copy of the SQLite sources.
      rm -rf $out/${perl.libPrefix}/*/*/auto/share
    '';

    preCheck = "rm t/65_db_config.t"; # do not run failing tests

    meta = {
      description = "Self Contained SQLite RDBMS in a DBI Driver";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
      platforms = lib.platforms.unix;
    };
  };

  DBI = buildPerlPackage {
    pname = "DBI";
    version = "1.644";

    src = fetchurl {
      url = "mirror://cpan/authors/id/H/HM/HMBRAND/DBI-1.644.tar.gz";
      hash = "sha256-Ipe5neCeZwhmQLWQaZ4OmC+0adpjqT/ijcFHgtt6U8g=";
    };

    env = lib.optionalAttrs stdenv.cc.isGNU {
      NIX_CFLAGS_COMPILE = "-Wno-error=incompatible-pointer-types";
    };

    postInstall = lib.optionalString (perl ? crossVersion) ''
      mkdir -p $out/${perl.libPrefix}/cross_perl/${perl.version}/DBI
      cat > $out/${perl.libPrefix}/cross_perl/${perl.version}/DBI.pm <<EOF
      package DBI;
      BEGIN {
      our \$VERSION = "$version";
      }
      1;
      EOF

      autodir=$(echo $out/${perl.libPrefix}/${perl.version}/*/auto/DBI)
      cat > $out/${perl.libPrefix}/cross_perl/${perl.version}/DBI/DBD.pm <<EOF
      package DBI::DBD;
      use Exporter ();
      use vars qw (@ISA @EXPORT);
      @ISA = qw(Exporter);
      @EXPORT = qw(dbd_postamble);
      sub dbd_postamble {
          return '
      # --- This section was generated by DBI::DBD::dbd_postamble()
      DBI_INSTARCH_DIR=$autodir
      DBI_DRIVER_XST=$autodir/Driver.xst

      # The main dependency (technically correct but probably not used)
      \$(BASEEXT).c: \$(BASEEXT).xsi

      # This dependency is needed since MakeMaker uses the .xs.o rule
      \$(BASEEXT)\$(OBJ_EXT): \$(BASEEXT).xsi

      \$(BASEEXT).xsi: \$(DBI_DRIVER_XST) $autodir/Driver_xst.h
      ''\t\$(PERL) -p -e "s/~DRIVER~/\$(BASEEXT)/g" \$(DBI_DRIVER_XST) > \$(BASEEXT).xsi

      # ---
      ';
      }
      1;
      EOF
    '';

    meta = {
      description = "Database independent interface for Perl";
      homepage = "https://dbi.perl.org";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  DevelCycle = buildPerlPackage {
    pname = "Devel-Cycle";
    version = "1.12";
    src = fetchurl {
      url = "mirror://cpan/authors/id/L/LD/LDS/Devel-Cycle-1.12.tar.gz";
      hash = "sha256-/TNlxNiYsrK927eKRtUHoYzKhJCikBmVR9q38ec5C8I=";
    };
    meta = {
      description = "Find memory cycles in objects";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  DevelGlobalDestruction = buildPerlPackage {
    pname = "Devel-GlobalDestruction";
    version = "0.14";
    src = fetchurl {
      url = "mirror://cpan/authors/id/H/HA/HAARG/Devel-GlobalDestruction-0.14.tar.gz";
      hash = "sha256-NLil8pmRMRRo/mkTytq6df1dKws+47tB/ltT76uRVKs=";
    };
    propagatedBuildInputs = [ SubExporterProgressive ];
    meta = {
      description = "Provides function returning the equivalent of \${^GLOBAL_PHASE} eq 'DESTRUCT' for older perls";
      homepage = "https://metacpan.org/release/Devel-GlobalDestruction";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  DevelOverloadInfo = buildPerlPackage {
    pname = "Devel-OverloadInfo";
    version = "0.007";
    src = fetchurl {
      url = "mirror://cpan/authors/id/I/IL/ILMARI/Devel-OverloadInfo-0.007.tar.gz";
      hash = "sha256-IaGEFjuQ+R8G/8f13guWg1ZUaum0AKnXXFc8lYwkYiI=";
    };
    propagatedBuildInputs = [
      MROCompat
      PackageStash
      SubIdentify
    ];
    buildInputs = [ TestFatal ];
    meta = {
      description = "Introspect overloaded operators";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  DevelStackTrace = buildPerlPackage {
    pname = "Devel-StackTrace";
    version = "2.04";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DR/DROLSKY/Devel-StackTrace-2.04.tar.gz";
      hash = "sha256-zTwD7VR9PULGH6WBTJgpYTk5LnlxwJLgmkMfLJ9daFU=";
    };
    meta = {
      description = "Object representing a stack trace";
      homepage = "https://metacpan.org/release/Devel-StackTrace";
      license = with lib.licenses; [ artistic2 ];
    };
  };

  DigestHMAC = buildPerlPackage {
    pname = "Digest-HMAC";
    version = "1.05";
    src = fetchurl {
      url = "mirror://cpan/authors/id/A/AR/ARODLAND/Digest-HMAC-1.05.tar.gz";
      hash = "sha256-IVy1nLphB0XPstSz+O91bVkOV+OteYapkuh8SWn83Ho=";
    };
    meta = {
      description = "Keyed-Hashing for Message Authentication";
      homepage = "https://metacpan.org/release/Digest-HMAC";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  DigestPerlMD5 = buildPerlPackage {
    pname = "Digest-Perl-MD5";
    version = "1.9";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DE/DELTA/Digest-Perl-MD5-1.9.tar.gz";
      hash = "sha256-cQDLoXEPRfsOkH2LGnvYyu81xkrNMdfyJa/1r/7s2bE=";
    };
    meta = {
      description = "Perl Implementation of Rivest's MD5 algorithm";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  DigestSHA1 = buildPerlPackage {
    pname = "Digest-SHA1";
    version = "2.13";
    src = fetchurl {
      url = "mirror://cpan/authors/id/G/GA/GAAS/Digest-SHA1-2.13.tar.gz";
      hash = "sha256-aMHawhh0IfDrer9xRSoG8ZAYG4/Eso7e31uQKW+5Q8w=";
    };
    meta = {
      description = "Perl interface to the SHA-1 algorithm";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  DistCheckConflicts = buildPerlPackage {
    pname = "Dist-CheckConflicts";
    version = "0.11";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DO/DOY/Dist-CheckConflicts-0.11.tar.gz";
      hash = "sha256-6oRLlobJTWZtnURDIddkSQss3i+YXEFltMLHdmXK7cQ=";
    };
    buildInputs = [ TestFatal ];
    propagatedBuildInputs = [ ModuleRuntime ];
    meta = {
      description = "Declare version conflicts for your dist";
      homepage = "https://metacpan.org/release/Dist-CheckConflicts";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  EncodeLocale = buildPerlPackage {
    pname = "Encode-Locale";
    version = "1.05";
    src = fetchurl {
      url = "mirror://cpan/authors/id/G/GA/GAAS/Encode-Locale-1.05.tar.gz";
      hash = "sha256-F2+gJ3H1QqTvsdvCpMko6PQ5G/QHhHO9YEDY8RrbDsE=";
    };
    preCheck =
      if stdenv.hostPlatform.isCygwin then
        ''
          sed -i -e "s@plan tests => 13@plan tests => 10@" t/env.t
          sed -i -e "s@ok(env(\"\\\x@#ok(env(\"\\\x@" t/env.t
          sed -i -e "s@ok(\$ENV{\"\\\x@#ok(\$ENV{\"\\\x@" t/env.t
        ''
      else
        null;
    meta = {
      description = "Determine the locale encoding";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  EvalClosure = buildPerlPackage {
    pname = "Eval-Closure";
    version = "0.14";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DO/DOY/Eval-Closure-0.14.tar.gz";
      hash = "sha256-6glE8vXsmNiVvvbVA+bko3b+pjg6a8ZMdnDUb/IhjK0=";
    };
    buildInputs = [
      TestFatal
      TestRequires
    ];
    meta = {
      description = "Safely and cleanly create closures via string eval";
      homepage = "https://metacpan.org/release/Eval-Closure";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ExceptionClass = buildPerlPackage {
    pname = "Exception-Class";
    version = "1.45";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DR/DROLSKY/Exception-Class-1.45.tar.gz";
      hash = "sha256-VIKnfvAnyh+fOeH0jFWDVulUk2/I+73ubIEcUScBskk=";
    };
    propagatedBuildInputs = [
      ClassDataInheritable
      DevelStackTrace
    ];
    meta = {
      description = "Exception Object Class";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ExporterTiny = buildPerlPackage {
    pname = "Exporter-Tiny";
    version = "1.006002";
    src = fetchurl {
      url = "mirror://cpan/authors/id/T/TO/TOBYINK/Exporter-Tiny-1.006002.tar.gz";
      hash = "sha256-byleLL/7HbwVvbna3DQWccHgzSvfLTErF1Jic8MiY40=";
    };
    meta = {
      description = "Exporter with the features of Sub::Exporter but only core dependencies";
      homepage = "https://metacpan.org/release/Exporter-Tiny";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  Expect = buildPerlPackage {
    pname = "Expect";
    version = "1.35";
    src = fetchurl {
      url = "mirror://cpan/authors/id/J/JA/JACOBY/Expect-1.35.tar.gz";
      hash = "sha256-CdknYUId7NSVhTEDN5FlqZ779FLHIPMCd2As8jZ5/QY=";
    };
    propagatedBuildInputs = [ IOTty ];
    meta = {
      description = "Automate interactions with command line programs that expose a text terminal interface";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ExtUtilsCChecker = buildPerlModule {
    pname = "ExtUtils-CChecker";
    version = "0.11";
    src = fetchurl {
      url = "mirror://cpan/authors/id/P/PE/PEVANS/ExtUtils-CChecker-0.11.tar.gz";
      hash = "sha256-EXc2Z343/GEfW3Y3TX+VLhlw64Dh9q1RUNUW565TG/U=";
    };
    buildInputs = [ TestFatal ];
    meta = {
      description = "Configure-time utilities for using C headers";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ExtUtilsConfig = buildPerlPackage {
    pname = "ExtUtils-Config";
    version = "0.008";
    src = fetchurl {
      url = "mirror://cpan/authors/id/L/LE/LEONT/ExtUtils-Config-0.008.tar.gz";
      hash = "sha256-rlEE9jRlDc6KebftE/tZ1no5whOmd2z9qj7nSeYvGow=";
    };
    meta = {
      description = "Wrapper for perl's configuration";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ExtUtilsHelpers = buildPerlPackage {
    pname = "ExtUtils-Helpers";
    version = "0.026";
    src = fetchurl {
      url = "mirror://cpan/authors/id/L/LE/LEONT/ExtUtils-Helpers-0.026.tar.gz";
      hash = "sha256-3pAbZ5CkVXz07JCBSeA1eDsSW/EV65ZA/rG8HCTDNBY=";
    };
    meta = {
      description = "Various portability utilities for module builders";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ExtUtilsInstallPaths = buildPerlPackage {
    pname = "ExtUtils-InstallPaths";
    version = "0.012";
    src = fetchurl {
      url = "mirror://cpan/authors/id/L/LE/LEONT/ExtUtils-InstallPaths-0.012.tar.gz";
      hash = "sha256-hHNeMDe6sf3/o8JQhWetQSp4XJFZnbPBJZOlCh3UNO0=";
    };
    propagatedBuildInputs = [ ExtUtilsConfig ];
    meta = {
      description = "Build.PL install path logic made easy";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ExtUtilsPkgConfig = buildPerlPackage {
    pname = "ExtUtils-PkgConfig";
    version = "1.16";
    src = fetchurl {
      url = "mirror://cpan/authors/id/X/XA/XAOC/ExtUtils-PkgConfig-1.16.tar.gz";
      hash = "sha256-u+rO2ZXX2NEM/FGjpaZtpBzrK8BP7cq1DhDmMA6AHG4=";
    };
    nativeBuildInputs = [ buildPackages.pkg-config ];
    propagatedNativeBuildInputs = [ pkgs.pkg-config ];
    postPatch = ''
      # no pkg-config binary when cross-compiling so the check fails
      substituteInPlace Makefile.PL \
        --replace "pkg-config" "$PKG_CONFIG"
      # use correctly prefixed pkg-config binary
      substituteInPlace lib/ExtUtils/PkgConfig.pm \
        --replace-fail '`pkg-config' '`${stdenv.cc.targetPrefix}pkg-config' \
        --replace-fail '"pkg-config' '"${stdenv.cc.targetPrefix}pkg-config' \
        --replace-fail '/pkg-config' '/${stdenv.cc.targetPrefix}pkg-config'
    '';
    doCheck = false; # expects test_glib-2.0.pc in PKG_CONFIG_PATH
    meta = {
      description = "Simplistic interface to pkg-config";
      homepage = "https://gitlab.gnome.org/GNOME/perl-extutils-pkgconfig";
      license = with lib.licenses; [ lgpl21Plus ];

    };
  };

  FCGI = buildPerlPackage {
    pname = "FCGI";
    version = "0.82";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETHER/FCGI-0.82.tar.gz";
      hash = "sha256-TH1g4m2iwH8Fik40UCHpJQUnOzPJVCIVl34IRhHwns8=";
    };
    buildInputs = [ FCGIClient ];
    postPatch = lib.optionalString (stdenv.hostPlatform != stdenv.buildPlatform) ''
      sed -i '/use IO::File/d' Makefile.PL
    '';
    meta = {
      description = "Fast CGI module";
      license = with lib.licenses; [ oml ];
    };
  };

  FCGIClient = buildPerlModule {
    pname = "FCGI-Client";
    version = "0.09";
    src = fetchurl {
      url = "mirror://cpan/authors/id/T/TO/TOKUHIROM/FCGI-Client-0.09.tar.gz";
      hash = "sha256-1TfLCc5aqz9Eemu0QV5GzAbv4BYRzVYom1WCvbRiIeg=";
    };
    propagatedBuildInputs = [
      Moo
      TypeTiny
    ];
    buildInputs = [ ModuleBuildTiny ];
    meta = {
      description = "Client library for fastcgi protocol";
      homepage = "https://github.com/tokuhirom/p5-fcgi-client";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  FCGIProcManager = buildPerlPackage {
    pname = "FCGI-ProcManager";
    version = "0.28";
    src = fetchurl {
      url = "mirror://cpan/authors/id/A/AR/ARODLAND/FCGI-ProcManager-0.28.tar.gz";
      hash = "sha256-4clYwEJCehdeBR4ACPICXo7IBhPTx3UFl7+OUpsEQg4=";
    };
    meta = {
      description = "Perl-based FastCGI process manager";
      license = with lib.licenses; [ gpl2Plus ];
    };
  };

  FileCopyRecursive = buildPerlPackage {
    pname = "File-Copy-Recursive";
    version = "0.45";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DM/DMUEY/File-Copy-Recursive-0.45.tar.gz";
      hash = "sha256-05cc94qDReOAQrIIu3s5y2lQgDhq9in0oE/9ZUnfEVc=";
    };
    buildInputs = [
      PathTiny
      TestDeep
      TestFatal
      TestFile
      TestWarnings
    ];
    meta = {
      description = "Perl extension for recursively copying files and directories";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  FileCopyRecursiveReduced = buildPerlPackage {
    pname = "File-Copy-Recursive-Reduced";
    version = "0.007";
    src = fetchurl {
      url = "mirror://cpan/authors/id/J/JK/JKEENAN/File-Copy-Recursive-Reduced-0.007.tar.gz";
      hash = "sha256-07WFIuaYA6kUN+KcCZ63Bug3Px7vBRik3DZp3T383Cc=";
    };
    buildInputs = [
      CaptureTiny
      PathTiny
    ];
    meta = {
      description = "Recursive copying of files and directories within Perl 5 toolchain";
      homepage = "http://thenceforward.net/perl/modules/File-Copy-Recursive-Reduced";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  FileFindRule = buildPerlPackage {
    pname = "File-Find-Rule";
    version = "0.34";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RC/RCLAMP/File-Find-Rule-0.34.tar.gz";
      hash = "sha256-fm8WzDPrHyn/Jb7lHVE/S4qElHu/oY7bLTzECi1kyv4=";
    };
    patches = [
      ./patches/FileFindRule-CVE-2011-10007.patch
    ];
    propagatedBuildInputs = [
      NumberCompare
      TextGlob
    ];
    meta = {
      description = "File::Find::Rule is a friendlier interface to File::Find";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
      mainProgram = "findrule";
    };
  };

  FileHomeDir = buildPerlPackage {
    pname = "File-HomeDir";
    version = "1.006";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RE/REHSACK/File-HomeDir-1.006.tar.gz";
      hash = "sha256-WTc3xi3w9tq11BIuC0R2QXlFu2Jiwz7twAlmXvFUiFI=";
    };
    propagatedBuildInputs = [ FileWhich ];
    preCheck = "export HOME=$TMPDIR";
    doCheck = !stdenv.hostPlatform.isDarwin;
    meta = {
      description = "Find your home and other directories on any platform";
      homepage = "https://metacpan.org/release/File-HomeDir";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  FileListing = buildPerlPackage {
    pname = "File-Listing";
    version = "6.16";
    src = fetchurl {
      url = "mirror://cpan/authors/id/P/PL/PLICEASE/File-Listing-6.16.tar.gz";
      hash = "sha256-GJs6E/wKG6QSudnsWQHp5eREzHRrnwFW1DmTcNM2VcY=";
    };
    propagatedBuildInputs = [ HTTPDate ];
    meta = {
      description = "Parse directory listing";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  Filepushd = buildPerlPackage {
    pname = "File-pushd";
    version = "1.016";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DA/DAGOLDEN/File-pushd-1.016.tar.gz";
      hash = "sha256-1zp/CUQpg7CYJg3z33qDKl9mB3OjE8onP6i1ZmX5fNw=";
    };
    meta = {
      description = "Change directory temporarily for a limited scope";
      homepage = "https://github.com/dagolden/File-pushd";
      license = with lib.licenses; [ asl20 ];
    };
  };

  FileShareDir = buildPerlPackage {
    pname = "File-ShareDir";
    version = "1.118";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RE/REHSACK/File-ShareDir-1.118.tar.gz";
      hash = "sha256-O7KiC6Nd+VjcCk8jBvwF2QPYuMTePIvu/OF3OdKByVg=";
    };
    # Fix dynamic loading not available when cross compiling
    postPatch = lib.optionalString (stdenv.hostPlatform != stdenv.buildPlatform) ''
      sed -i '/install_share/d' Makefile.PL
      sed -i '/File::ShareDir::Install/d' Makefile.PL
    '';
    propagatedBuildInputs = [ ClassInspector ];
    buildInputs = [ FileShareDirInstall ];
    meta = {
      description = "Locate per-dist and per-module shared files";
      homepage = "https://metacpan.org/release/File-ShareDir";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  FileShareDirInstall = buildPerlPackage {
    pname = "File-ShareDir-Install";
    version = "0.14";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETHER/File-ShareDir-Install-0.14.tar.gz";
      hash = "sha256-j5UzsZjy1KmlKIy8fSJPdnmtBaeoVzdFWZeJQovFrqA=";
    };
    meta = {
      description = "Install shared files";
      homepage = "https://github.com/Perl-Toolchain-Gang/File-ShareDir-Install";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  FileSlurper = buildPerlPackage {
    pname = "File-Slurper";
    version = "0.014";
    src = fetchurl {
      url = "mirror://cpan/authors/id/L/LE/LEONT/File-Slurper-0.014.tar.gz";
      hash = "sha256-1aNkhzOYiMPNdY5kgWDuHXDrQVPKy6/1eEbbzvs0Sww=";
    };
    buildInputs = [ TestWarnings ];
    meta = {
      description = "Simple, sane and efficient module to slurp a file";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  FileWhich = buildPerlPackage {
    pname = "File-Which";
    version = "1.27";
    src = fetchurl {
      url = "mirror://cpan/authors/id/P/PL/PLICEASE/File-Which-1.27.tar.gz";
      hash = "sha256-MgHxpg4/FkhAguYEXIloQiYfw0Xen7LmIP0qLHrzqTo=";
    };
    meta = {
      description = "Perl implementation of the which utility as an API";
      homepage = "https://metacpan.org/pod/File::Which";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  FontAFM = buildPerlPackage {
    pname = "Font-AFM";
    version = "1.20";
    src = fetchurl {
      url = "mirror://cpan/authors/id/G/GA/GAAS/Font-AFM-1.20.tar.gz";
      hash = "sha256-MmcRZtoyWWoPa6rNDBIzglpgrK8lgF15yBo/GNYIi8E=";
    };
    meta = {
      description = "Interface to Adobe Font Metrics files";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  FontTTF = buildPerlPackage {
    pname = "Font-TTF";
    version = "1.06";
    src = fetchurl {
      url = "mirror://cpan/authors/id/B/BH/BHALLISSY/Font-TTF-1.06.tar.gz";
      hash = "sha256-S2l9REJZdZ6gLSxELJv/5f/hTJIUCEoB90NpOpRMwpM=";
    };
    buildInputs = [ IOString ];
    meta = {
      description = "TTF font support for Perl";
      license = with lib.licenses; [ artistic2 ];
    };
  };

  GD = buildPerlPackage {
    pname = "GD";
    version = "2.78";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RU/RURBAN/GD-2.78.tar.gz";
      hash = "sha256-aDEFS/VCS09cI9NifT0UhEgPb5wsZmMiIpFfKFG+buQ=";
    };

    nativeBuildInputs = [
      pkgs.pkg-config
    ];
    buildInputs = [
      pkgs.gd
      pkgs.libjpeg
      pkgs.zlib
      pkgs.freetype
      pkgs.libpng
      pkgs.fontconfig
      pkgs.libxpm
      ExtUtilsPkgConfig
      TestFork
      TestNoWarnings
    ];

    # otherwise "cc1: error: -Wformat-security ignored without -Wformat [-Werror=format-security]"
    hardeningDisable = [ "format" ];

    makeMakerFlags = [
      "--lib_png_path=${pkgs.libpng.out}"
      "--lib_jpeg_path=${pkgs.libjpeg.out}"
      "--lib_zlib_path=${pkgs.zlib.out}"
      "--lib_ft_path=${pkgs.freetype.out}"
      "--lib_fontconfig_path=${pkgs.fontconfig.lib}"
      "--lib_xpm_path=${pkgs.libxpm.out}"
    ];

    meta = {
      description = "Perl interface to the gd2 graphics library";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
      mainProgram = "bdf2gdfont.pl";
    };
  };

  gotofile = buildPerlPackage {
    pname = "goto-file";
    version = "0.005";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/EX/EXODIST/goto-file-0.005.tar.gz";
      hash = "sha256-xs3V7kps3L2/MU2SpPmYXbzfnkJYBIyudhJcBSqjH3c=";
    };
    buildInputs = [ Test2Suite ];
    meta = {
      description = "Stop parsing the current file and move on to a different one";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  HTMLForm = buildPerlPackage {
    pname = "HTML-Form";
    version = "6.11";
    src = fetchurl {
      url = "mirror://cpan/authors/id/S/SI/SIMBABQUE/HTML-Form-6.11.tar.gz";
      hash = "sha256-Q7+qcIc5NIfS1RJhoap/b4Gpex2P73pI/PbvMrFtZFQ=";
    };
    buildInputs = [ TestWarnings ];
    propagatedBuildInputs = [
      HTMLParser
      URI
    ];
    meta = {
      description = "Class that represents an HTML form element";
      homepage = "https://github.com/libwww-perl/HTML-Form";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  HTMLFormatter = buildPerlPackage {
    pname = "HTML-Formatter";
    version = "2.16";
    src = fetchurl {
      url = "mirror://cpan/authors/id/N/NI/NIGELM/HTML-Formatter-2.16.tar.gz";
      hash = "sha256-ywoN2Kpei6nKIUzkUb9N8zqgnBPpB+jTCC3a/rMBUcw=";
    };
    buildInputs = [
      FileSlurper
      TestWarnings
    ];
    propagatedBuildInputs = [
      FontAFM
      HTMLTree
    ];
    meta = {
      description = "Base class for HTML formatters";
      homepage = "https://metacpan.org/release/HTML-Formatter";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  HTMLParser = buildPerlPackage {
    pname = "HTML-Parser";
    version = "3.81";
    src = fetchurl {
      url = "mirror://cpan/authors/id/O/OA/OALDERS/HTML-Parser-3.81.tar.gz";
      hash = "sha256-wJEKXI+S+IF+3QbM/SJLocLr6MEPVR8DJYeh/IPWL/I=";
    };
    propagatedBuildInputs = [
      HTMLTagset
      HTTPMessage
    ];
    meta = {
      description = "HTML parser class";
      homepage = "https://github.com/libwww-perl/HTML-Parser";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  HTMLTagCloud = buildPerlModule {
    pname = "HTML-TagCloud";
    version = "0.38";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RO/ROBERTSD/HTML-TagCloud-0.38.tar.gz";
      hash = "sha256-SYCZRy3vhmtEi/YvQYLfrfWUcuE/JMuGZKZxynm2cBU=";
    };
    meta = {
      description = "Generate An HTML Tag Cloud";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  HTMLTagset = buildPerlPackage {
    pname = "HTML-Tagset";
    version = "3.20";
    src = fetchurl {
      url = "mirror://cpan/authors/id/P/PE/PETDANCE/HTML-Tagset-3.20.tar.gz";
      hash = "sha256-rbF9rJ42zQEfUkOIHJc5QX/RAvznYPjeTpvkxxMRCOI=";
    };
    meta = {
      description = "Data tables useful in parsing HTML";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  HTMLTree = buildPerlModule {
    pname = "HTML-Tree";
    version = "5.07";
    src = fetchurl {
      url = "mirror://cpan/authors/id/K/KE/KENTNL/HTML-Tree-5.07.tar.gz";
      hash = "sha256-8DdNuEcxwgS4bB1bkJdf7w0wqGvZ3vkZND5VTjGp278=";
    };
    buildInputs = [ TestFatal ];
    propagatedBuildInputs = [ HTMLParser ];
    meta = {
      description = "Work with HTML in a DOM-like tree structure";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
      mainProgram = "htmltree";
    };
  };

  HTTPCookieJar = buildPerlPackage {
    pname = "HTTP-CookieJar";
    version = "0.014";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DA/DAGOLDEN/HTTP-CookieJar-0.014.tar.gz";
      hash = "sha256-cJTqXJH1NtJjuF6Dq06alj4RxECM4I7K5VP6nAzEfnM=";
    };
    propagatedBuildInputs = [ HTTPDate ];
    buildInputs = [
      TestDeep
      TestRequires
      URI
    ];
    # Broken on Hydra since 2021-06-17: https://hydra.nixos.org/build/146507373
    doCheck = false;
    meta = {
      description = "Minimalist HTTP user agent cookie jar";
      homepage = "https://github.com/dagolden/HTTP-CookieJar";
      license = with lib.licenses; [ asl20 ];
    };
  };

  HTTPCookies = buildPerlPackage {
    pname = "HTTP-Cookies";
    version = "6.10";
    src = fetchurl {
      url = "mirror://cpan/authors/id/O/OA/OALDERS/HTTP-Cookies-6.10.tar.gz";
      hash = "sha256-4282Yzxc5rXkuHb/z3R4fMXv4HNt1/SHvdc8FPC9cAc=";
    };
    propagatedBuildInputs = [ HTTPMessage ];
    meta = {
      description = "HTTP cookie jars";
      homepage = "https://github.com/libwww-perl/HTTP-Cookies";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  HTTPDaemon = buildPerlPackage {
    pname = "HTTP-Daemon";
    version = "6.16";
    src = fetchurl {
      url = "mirror://cpan/authors/id/O/OA/OALDERS/HTTP-Daemon-6.16.tar.gz";
      hash = "sha256-s40JJyXm+k4MTcKkfhVwcEkbr6Db4Wx4o1joBqp+Fz0=";
    };
    buildInputs = [
      ModuleBuildTiny
      TestNeeds
    ];
    propagatedBuildInputs = [ HTTPMessage ];
    __darwinAllowLocalNetworking = true;
    meta = {
      description = "Simple http server class";
      homepage = "https://github.com/libwww-perl/HTTP-Daemon";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  HTTPDate = buildPerlPackage {
    pname = "HTTP-Date";
    version = "6.06";
    src = fetchurl {
      url = "mirror://cpan/authors/id/O/OA/OALDERS/HTTP-Date-6.06.tar.gz";
      hash = "sha256-e2hRkcasw+dz0fwCyV7h+frpT3d4MXX154wYHMktK1I=";
    };
    propagatedBuildInputs = [ TimeDate ];
    meta = {
      description = "Date conversion routines";
      homepage = "https://github.com/libwww-perl/HTTP-Date";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  HTTPMessage = buildPerlPackage {
    pname = "HTTP-Message";
    version = "6.45";
    src = fetchurl {
      url = "mirror://cpan/authors/id/O/OA/OALDERS/HTTP-Message-6.45.tar.gz";
      hash = "sha256-AcuEBmEqP3OIQtHpcxOuTYdIcNG41tZjMfFgAJQ9TL4=";
    };
    buildInputs = [
      TestNeeds
      TryTiny
    ];
    propagatedBuildInputs = [
      Clone
      EncodeLocale
      HTTPDate
      IOHTML
      LWPMediaTypes
      URI
    ];
    meta = {
      description = "HTTP style message (base class)";
      homepage = "https://github.com/libwww-perl/HTTP-Message";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  HTTPNegotiate = buildPerlPackage {
    pname = "HTTP-Negotiate";
    version = "6.01";
    src = fetchurl {
      url = "mirror://cpan/authors/id/G/GA/GAAS/HTTP-Negotiate-6.01.tar.gz";
      hash = "sha256-HHKcHqYxAOh4QFzafWb5rf0+1PHWysrKDukVLfco4BY=";
    };
    propagatedBuildInputs = [ HTTPMessage ];
    meta = {
      description = "Choose a variant to serve";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  HTTPServerSimple = buildPerlPackage {
    pname = "HTTP-Server-Simple";
    version = "0.52";
    src = fetchurl {
      url = "mirror://cpan/authors/id/B/BP/BPS/HTTP-Server-Simple-0.52.tar.gz";
      hash = "sha256-2JOfpPEr1rjAQ1N/0L+WsFWsNoa5zdn6dz3KauZ5y0w=";
    };
    doCheck = false;
    propagatedBuildInputs = [ CGI ];
    meta = {
      description = "Lightweight HTTP server";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  Importer = buildPerlPackage {
    pname = "Importer";
    version = "0.026";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/EX/EXODIST/Importer-0.026.tar.gz";
      hash = "sha256-4I+oThPLmYt6iX/I7Jw0WfzBcWr/Jcw0Pjbvh1iRsO8=";
    };
    meta = {
      description = "Alternative but compatible interface to modules that export symbols";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  IO = buildPerlPackage {
    pname = "IO";
    version = "1.51";
    src = fetchurl {
      url = "mirror://cpan/authors/id/T/TO/TODDR/IO-1.51.tar.gz";
      hash = "sha256-VJPqVZmHKM0rfsuCNMWPtdXfJwmNDwet3KIkRNdhbOA=";
    };
    doCheck = false;
    meta = {
      description = "Perl core IO modules";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  IOHTML = buildPerlPackage {
    pname = "IO-HTML";
    version = "1.004";
    src = fetchurl {
      url = "mirror://cpan/authors/id/C/CJ/CJM/IO-HTML-1.004.tar.gz";
      hash = "sha256-yHst9ZRju/LDlZZ3PftcA73g9+EFGvM5+WP1jBy9i/U=";
    };
    meta = {
      description = "Open an HTML file with automatic charset detection";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  IOSocketSSL = buildPerlPackage {
    pname = "IO-Socket-SSL";
    version = "2.083";
    src = fetchurl {
      url = "mirror://cpan/authors/id/S/SU/SULLR/IO-Socket-SSL-2.083.tar.gz";
      hash = "sha256-kE7yh2VECpfYqaDfWX+MPX88sKBT0bCCwQvtA7yAIGk=";
    };
    propagatedBuildInputs = [
      MozillaCA
      NetSSLeay
    ];
    # Fix path to default certificate store.
    postPatch = ''
      substituteInPlace lib/IO/Socket/SSL.pm \
        --replace "\$openssldir/cert.pem" "/etc/ssl/certs/ca-certificates.crt"
    '';
    doCheck = false; # tries to connect to facebook.com etc.
    meta = {
      description = "Nearly transparent SSL encapsulation for IO::Socket::INET";
      homepage = "https://github.com/noxxi/p5-io-socket-ssl";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  IOString = buildPerlPackage {
    pname = "IO-String";
    version = "1.08";
    src = fetchurl {
      url = "mirror://cpan/authors/id/G/GA/GAAS/IO-String-1.08.tar.gz";
      hash = "sha256-Kj9K2EQtkHB4DljvQ3ItGdHuIagDv3yCBod6EEgt5aA=";
    };
    meta = {
      description = "Emulate file interface for in-core strings";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  IOStringy = buildPerlPackage {
    pname = "IO-Stringy";
    version = "2.113";
    src = fetchurl {
      url = "mirror://cpan/authors/id/C/CA/CAPOEIRAB/IO-Stringy-2.113.tar.gz";
      hash = "sha256-USIPyvn2amObadJR17B1e/QgL0+d69Rb3TQaaspi/k4=";
    };
    meta = {
      description = "I/O on in-core objects like strings and arrays";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  IOTty = buildPerlPackage rec {
    pname = "IO-Tty";
    version = "1.20";
    src = fetchurl {
      url = "mirror://cpan/authors/id/T/TO/TODDR/IO-Tty-${version}.tar.gz";
      hash = "sha256-sVMJ/IViOJMonLmyuI36ntHmkVa3XymThVOkW+bXMK8=";
    };
    # Fix dynamic loading not available when cross compiling
    postPatch = lib.optionalString (stdenv.hostPlatform != stdenv.buildPlatform) ''
      sed -i '/use IO::File/d' Makefile.PL
    '';
    doCheck = !stdenv.hostPlatform.isDarwin; # openpty fails in the sandbox
    meta = {
      homepage = "https://github.com/toddr/IO-Tty";
      description = "Low-level allocate a pseudo-Tty, import constants";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  IPCRun = buildPerlPackage {
    pname = "IPC-Run";
    version = "20231003.0";
    src = fetchurl {
      url = "mirror://cpan/authors/id/T/TO/TODDR/IPC-Run-20231003.0.tar.gz";
      hash = "sha256-6yW731kT0pF5fvG/6ZjxUTC0VdPtAqrN5oVvCyXk/lc=";
    };
    doCheck = false; # attempts a network connection to localhost
    propagatedBuildInputs = [ IOTty ];
    buildInputs = [ Readonly ];
    meta = {
      description = "System() and background procs w/ piping, redirs, ptys (Unix, Win32)";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  IPCRun3 = buildPerlPackage {
    pname = "IPC-Run3";
    version = "0.048";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RJ/RJBS/IPC-Run3-0.048.tar.gz";
      hash = "sha256-PYHDzBtc/2nMqTYeLG443wNSJRrntB4v8/68hQ5GNWU=";
    };
    meta = {
      description = "Run a subprocess with input/output redirection";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
        bsd3
      ];
    };
  };

  IPCSystemSimple = buildPerlPackage {
    pname = "IPC-System-Simple";
    version = "1.30";
    src = fetchurl {
      url = "mirror://cpan/authors/id/J/JK/JKEENAN/IPC-System-Simple-1.30.tar.gz";
      hash = "sha256-Iub1IitQXuUTBY/co1q3oeq4BTm5jlykqSOnCorpup4=";
    };
    meta = {
      description = "Run commands simply, with detailed diagnostics";
      homepage = "http://thenceforward.net/perl/modules/IPC-System-Simple";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ImageExifTool = callPackage ./patches/ImageExifTool { };

  libnet = buildPerlPackage {
    pname = "libnet";
    version = "3.15";
    src = fetchurl {
      url = "mirror://cpan/authors/id/S/SH/SHAY/libnet-3.15.tar.gz";
      hash = "sha256-px9NtYDhp2fWk2+qW6848fpheCQ0LaB4tWEoPob49KI=";
    };
    meta = {
      description = "Collection of network protocol modules";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  LocaleGettext = buildPerlPackage {
    pname = "gettext";
    version = "1.07";
    strictDeps = true;
    buildInputs = [ pkgs.gettext ];
    src = fetchurl {
      url = "mirror://cpan/authors/id/P/PV/PVANDRY/gettext-1.07.tar.gz";
      hash = "sha256-kJ1HlUaX58BCGPlykVt4e9EkTXXjvQFiC8Fn1bvEnBU=";
    };
    LANG = "C";
    meta = {
      description = "Perl extension for emulating gettext-related API";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  LogDispatch = buildPerlPackage {
    pname = "Log-Dispatch";
    version = "2.71";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DR/DROLSKY/Log-Dispatch-2.71.tar.gz";
      hash = "sha256-nWDZZIw1zidUcx603rfwWAns4b1jO3TXR5Wu2exzJXA=";
    };
    propagatedBuildInputs = [
      DevelGlobalDestruction
      ParamsValidationCompiler
      Specio
      namespaceautoclean
    ];
    buildInputs = [
      IPCRun3
      TestFatal
      TestNeeds
    ];
    meta = {
      description = "Dispatches messages to one or more outputs";
      homepage = "https://metacpan.org/release/Log-Dispatch";
      license = with lib.licenses; [ artistic2 ];
    };
  };

  LogLog4perl = buildPerlPackage {
    pname = "Log-Log4perl";
    version = "1.57";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETJ/Log-Log4perl-1.57.tar.gz";
      hash = "sha256-D4/Ldjio89tMeX35T9vFYBN0kULy+Uy8lbQ8n8oJahM=";
    };
    meta = {
      description = "Log4j implementation for Perl";
      homepage = "https://mschilli.github.io/log4perl/";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
      mainProgram = "l4p-tmpl";
    };
  };

  LongJump = buildPerlPackage {
    pname = "Long-Jump";
    version = "0.000001";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/EX/EXODIST/Long-Jump-0.000001.tar.gz";
      hash = "sha256-1dZFbYaZK1Wdj2b8kJYPkZKSzTgDwTQD+qxXV2LHevQ=";
    };
    buildInputs = [ Test2Suite ];
    meta = {
      description = "Mechanism for returning to a specific point from a deeply nested stack";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  LWP = buildPerlPackage {
    pname = "libwww-perl";
    version = "6.72";
    src = fetchurl {
      url = "mirror://cpan/authors/id/O/OA/OALDERS/libwww-perl-6.72.tar.gz";
      hash = "sha256-6bg1T9XiC+IHr+I93VhPzVm/gpmNwHfez2hLodrloF0=";
    };
    propagatedBuildInputs = [
      FileListing
      HTMLParser
      HTTPCookies
      HTTPCookieJar
      HTTPNegotiate
      NetHTTP
      TryTiny
      WWWRobotRules
    ];
    preCheck = ''
      export NO_NETWORK_TESTING=1
    '';
    # support cross-compilation by avoiding using `has_module` which does not work in miniperl (it requires B native module)
    postPatch = lib.optionalString (stdenv.buildPlatform != stdenv.hostPlatform) ''
      substituteInPlace Makefile.PL --replace 'if has_module' 'if 0; #'
    '';
    doCheck = !stdenv.hostPlatform.isDarwin;
    nativeCheckInputs = [
      HTTPDaemon
      TestFatal
      TestNeeds
      TestRequiresInternet
    ];
    meta = {
      description = "World-Wide Web library for Perl";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  LWPMediaTypes = buildPerlPackage {
    pname = "LWP-MediaTypes";
    version = "6.04";
    src = fetchurl {
      url = "mirror://cpan/authors/id/O/OA/OALDERS/LWP-MediaTypes-6.04.tar.gz";
      hash = "sha256-jxvKEtqxahwqfAOknF5YzOQab+yVGfCq37qNrZl5Gdk=";
    };
    buildInputs = [ TestFatal ];
    meta = {
      description = "Guess media type for a file or a URL";
      homepage = "https://github.com/libwww-perl/lwp-mediatypes";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  LWPProtocolHttps = buildPerlPackage {
    pname = "LWP-Protocol-https";
    version = "6.11";
    src = fetchurl {
      url = "mirror://cpan/authors/id/O/OA/OALDERS/LWP-Protocol-https-6.11.tar.gz";
      hash = "sha256-ATLdvwNmFWXKhQUPKlCU+5Jjy7w8yxpNnEGsm7CDuRc=";
    };
    patches = [ ./patches/lwp-protocol-https-cert-file.patch ];
    propagatedBuildInputs = [
      IOSocketSSL
      LWP
    ];
    preCheck = ''
      export NO_NETWORK_TESTING=1
    '';
    buildInputs = [
      TestRequiresInternet
      TestNeeds
    ];
    meta = {
      description = "Provide https support for LWP::UserAgent";
      homepage = "https://github.com/libwww-perl/LWP-Protocol-https";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  meta = buildPerlModule {
    pname = "meta";
    version = "0.012";
    src = fetchurl {
      url = "mirror://cpan/authors/id/P/PE/PEVANS/meta-0.012.tar.gz";
      hash = "sha256-Fx0J0wn4APVTTQE4tXMDmpYfEDtDaKhBC3dogzFuuFk=";
    };
    buildInputs = [ Test2Suite ];
    meta = {
      description = "Meta-programming API";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];

    };
  };

  MIMECharset = buildPerlPackage {
    pname = "MIME-Charset";
    version = "1.013.1";
    src = fetchurl {
      url = "mirror://cpan/authors/id/N/NE/NEZUMI/MIME-Charset-1.013.1.tar.gz";
      hash = "sha256-G7em4MDSUfI9bmC/hMmt78W3TuxYR1v+5NORB+YIcPA=";
    };
    meta = {
      description = "Charset Information for MIME";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ModuleBuild = buildPerlPackage {
    pname = "Module-Build";
    version = "0.4234";
    src = fetchurl {
      url = "mirror://cpan/authors/id/L/LE/LEONT/Module-Build-0.4234.tar.gz";
      hash = "sha256-Zq6sYSdBi+XkcerTdEZIx2a9AUgoJcW2ZlJnXyvIao8=";
    };
    postConfigure = lib.optionalString (stdenv.hostPlatform != stdenv.buildPlatform) ''
      # for unknown reason, the first run of Build fails
      ./Build || true
    '';
    postPatch = lib.optionalString (stdenv.hostPlatform != stdenv.buildPlatform) ''
      # remove version check since miniperl uses a stub of File::Temp, which do not provide a version:
      # https://github.com/arsv/perl-cross/blob/master/cnf/stub/File/Temp.pm
      sed -i '/File::Temp/d' \
        Build.PL

      # fix discover perl function, it can not handle a wrapped perl
      sed -i "s,\$self->_discover_perl_interpreter,'$(type -p perl)',g" \
        lib/Module/Build/Base.pm
    '';
    meta = {
      description = "Build and install Perl modules";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
      mainProgram = "config_data";
    };
  };

  ModuleBuildTiny = buildPerlModule {
    pname = "Module-Build-Tiny";
    version = "0.047";
    src = fetchurl {
      url = "mirror://cpan/authors/id/L/LE/LEONT/Module-Build-Tiny-0.047.tar.gz";
      hash = "sha256-cSYOlCG5PDPdGz59DPFfdZwMp8dT+oQCeew75w+PjJ0=";
    };
    buildInputs = [ FileShareDir ];
    propagatedBuildInputs = [
      ExtUtilsHelpers
      ExtUtilsInstallPaths
    ];
    meta = {
      description = "Tiny replacement for Module::Build";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ModuleBuildXSUtil = buildPerlModule {
    pname = "Module-Build-XSUtil";
    version = "0.19";
    src = fetchurl {
      url = "mirror://cpan/authors/id/H/HI/HIDEAKIO/Module-Build-XSUtil-0.19.tar.gz";
      hash = "sha256-kGOzw0bt60IoB//kn/sjA4xPkA1Kd7hFzktT2XvylAA=";
    };
    buildInputs = [
      CaptureTiny
      CwdGuard
      FileCopyRecursiveReduced
    ];
    propagatedBuildInputs = [ DevelCheckCompiler ];
    meta = {
      description = "Module::Build class for building XS modules";
      homepage = "https://github.com/hideo55/Module-Build-XSUtil";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ModuleImplementation = buildPerlPackage {
    pname = "Module-Implementation";
    version = "0.09";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DR/DROLSKY/Module-Implementation-0.09.tar.gz";
      hash = "sha256-wV8aEvDCEwye//PC4a/liHsIzNAzvRMhhtHn1Qh/1m0=";
    };
    buildInputs = [
      TestFatal
      TestRequires
    ];
    propagatedBuildInputs = [
      ModuleRuntime
      TryTiny
    ];
    meta = {
      description = "Loads one of several alternate underlying implementations for a module";
      homepage = "https://metacpan.org/release/Module-Implementation";
      license = with lib.licenses; [ artistic2 ];
    };
  };

  ModulePluggable = buildPerlPackage {
    pname = "Module-Pluggable";
    version = "5.2";
    src = fetchurl {
      url = "mirror://cpan/authors/id/S/SI/SIMONW/Module-Pluggable-5.2.tar.gz";
      hash = "sha256-s/KtReT9ELP7kNkS142LeVqylUgNtW3GToa5+nXFpt8=";
    };
    patches = [
      # !!! merge this patch into Perl itself (which contains Module::Pluggable as well)
      ./patches/module-pluggable.patch
    ];
    buildInputs = [ AppFatPacker ];
    meta = {
      description = "Automatically give your module the ability to have plugins";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ModuleRuntime = buildPerlModule {
    pname = "Module-Runtime";
    version = "0.016";
    src = fetchurl {
      url = "mirror://cpan/authors/id/Z/ZE/ZEFRAM/Module-Runtime-0.016.tar.gz";
      hash = "sha256-aDAuxkaDNUfUEL4o4JZ223UAb0qlihHzvbRP/pnw8CQ=";
    };
    meta = {
      description = "Runtime module handling";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ModuleRuntimeConflicts = buildPerlPackage {
    pname = "Module-Runtime-Conflicts";
    version = "0.003";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETHER/Module-Runtime-Conflicts-0.003.tar.gz";
      hash = "sha256-cHzcdQOMcP6Rd5uIisBQ8ShWXTlnupZoDhscfMlzOHU=";
    };
    propagatedBuildInputs = [ DistCheckConflicts ];
    meta = {
      description = "Provide information on conflicts for Module::Runtime";
      homepage = "https://github.com/karenetheridge/Module-Runtime-Conflicts";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ModuleSignature = buildPerlPackage {
    pname = "Module-Signature";
    version = "0.87";
    src = fetchurl {
      url = "mirror://cpan/authors/id/A/AU/AUDREYT/Module-Signature-0.87.tar.gz";
      hash = "sha256-IU6AVcUP7DcalXQ1IP4mlAAE52FpBjsrROyQoNRdaYI=";
    };
    buildInputs = [ IPCRun ];
    meta = {
      description = "Module signature file manipulation";
      license = with lib.licenses; [ cc0 ];
      mainProgram = "cpansign";
    };
  };

  Moo = buildPerlPackage {
    pname = "Moo";
    version = "2.005005";
    src = fetchurl {
      url = "mirror://cpan/authors/id/H/HA/HAARG/Moo-2.005005.tar.gz";
      hash = "sha256-+1opUmSfrtBzc/Igt4AEqcaro4dzkTN0DBdw6bH0sQg=";
    };
    buildInputs = [ TestFatal ];
    propagatedBuildInputs = [
      ClassMethodModifiers
      ModuleRuntime
      RoleTiny
      SubQuote
    ];
    meta = {
      description = "Minimalist Object Orientation (with Moose compatibility)";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  Moose = buildPerlPackage {
    pname = "Moose";
    version = "2.2206";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETHER/Moose-2.2206.tar.gz";
      hash = "sha256-Z5csTivDn72jhRgXevDme7vrVIVi5OxLdZoaelg+UFs=";
    };
    buildInputs = [
      DistCheckConflicts
      CPANMetaCheck
      TestCleanNamespaces
      TestFatal
      TestNeeds
      TestRequires
    ];
    propagatedBuildInputs = [
      ClassLoadXS
      DataOptList
      DevelGlobalDestruction
      DevelOverloadInfo
      DevelStackTrace
      EvalClosure
      MROCompat
      ModuleRuntimeConflicts
      PackageDeprecationManager
      PackageStashXS
      ParamsUtil
      SubExporter
      TryTiny
    ];
    meta = {
      description = "Postmodern object system for Perl 5";
      homepage = "http://moose.perl.org";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];

      mainProgram = "moose-outdated";
    };
  };

  Mouse = buildPerlModule {
    pname = "Mouse";
    version = "2.5.10";
    src = fetchurl {
      url = "mirror://cpan/authors/id/S/SK/SKAJI/Mouse-v2.5.10.tar.gz";
      hash = "sha256-zo3COUYVOkZ/8JdlFn7iWQ9cUCEg9IotlEFzPzmqMu4=";
    };
    buildInputs = [
      ModuleBuildXSUtil
      TestException
      TestFatal
      TestLeakTrace
      TestOutput
      TestRequires
      TryTiny
    ];
    env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.hostPlatform.isi686 "-fno-stack-protector";
    hardeningDisable = lib.optional stdenv.hostPlatform.isi686 "stackprotector";
    meta = {
      description = "Moose minus the antlers";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  MozillaCA = buildPerlPackage {
    pname = "Mozilla-CA";
    version = "20230821";
    src = fetchurl {
      url = "mirror://cpan/authors/id/L/LW/LWP/Mozilla-CA-20230821.tar.gz";
      hash = "sha256-MuHQBFKZAEBFucTRbC2q5FOiFiCIc97qJED3EmCnzaE=";
    };

    postPatch = ''
      ln -s --force ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt lib/Mozilla/CA/cacert.pem
    '';

    meta = {
      description = "Mozilla's CA cert bundle in PEM format";
      homepage = "https://github.com/gisle/mozilla-ca";
      license = with lib.licenses; [ mpl20 ];
    };
  };

  MROCompat = buildPerlPackage {
    pname = "MRO-Compat";
    version = "0.15";
    src = fetchurl {
      url = "mirror://cpan/authors/id/H/HA/HAARG/MRO-Compat-0.15.tar.gz";
      hash = "sha256-DUU1+I5Dur2Eq2BIZiFfxNBDmL1Nt7IYUtSjGxwV72E=";
    };
    meta = {
      description = "Mro::* interface compatibility for Perls < 5.9.5";
      homepage = "https://metacpan.org/release/MRO-Compat";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  namespaceautoclean = buildPerlPackage {
    pname = "namespace-autoclean";
    version = "0.29";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETHER/namespace-autoclean-0.29.tar.gz";
      hash = "sha256-RevY5kpUqG+I2OAa5VISlnyKqP7VfoFAhd73YIrGWAQ=";
    };
    buildInputs = [ TestNeeds ];
    propagatedBuildInputs = [
      SubIdentify
      namespaceclean
    ];
    meta = {
      description = "Keep imports out of your namespace";
      homepage = "https://github.com/moose/namespace-autoclean";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  namespaceclean = buildPerlPackage {
    pname = "namespace-clean";
    version = "0.27";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RI/RIBASUSHI/namespace-clean-0.27.tar.gz";
      hash = "sha256-ihCoPD4YPcePnnt6pNCbR8EftOfTozuaEpEv0i4xr50=";
    };
    propagatedBuildInputs = [
      BHooksEndOfScope
      PackageStash
    ];
    meta = {
      description = "Keep imports and functions out of your namespace";
      homepage = "https://search.cpan.org/dist/namespace-clean";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  NetHTTP = buildPerlPackage {
    pname = "Net-HTTP";
    version = "6.23";
    src = fetchurl {
      url = "mirror://cpan/authors/id/O/OA/OALDERS/Net-HTTP-6.23.tar.gz";
      hash = "sha256-DWXAndbIWJsq4RGBdNPBphcDtuz8FKNEKox0r2XgyU4=";
    };
    propagatedBuildInputs = [ URI ];
    __darwinAllowLocalNetworking = true;
    doCheck = false; # wants network
    meta = {
      description = "Low-level HTTP connection (client)";
      homepage = "https://github.com/libwww-perl/Net-HTTP";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  NetSMTPSSL = buildPerlPackage {
    pname = "Net-SMTP-SSL";
    version = "1.04";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RJ/RJBS/Net-SMTP-SSL-1.04.tar.gz";
      hash = "sha256-eynEWt0Z09UIS3Ufe6iajkBHmkRs4hz9nMdB5VgzKgA=";
    };
    propagatedBuildInputs = [ IOSocketSSL ];
    meta = {
      description = "SSL support for Net::SMTP";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  NetSSLeay = buildPerlPackage {
    pname = "Net-SSLeay";
    version = "1.92";
    src = fetchurl {
      url = "mirror://cpan/authors/id/C/CH/CHRISN/Net-SSLeay-1.92.tar.gz";
      hash = "sha256-R8LyswDy5xYtcdaZ9jPdajWwYloAy9qMUKwBFEqTlqk=";
    };
    buildInputs = [
      pkgs.openssl
      pkgs.zlib
    ];
    doCheck = false; # Test performs network access.
    preConfigure = ''
      mkdir openssl
      ln -s ${lib.getLib pkgs.openssl}/lib openssl
      ln -s ${pkgs.openssl.bin}/bin openssl
      ln -s ${pkgs.openssl.dev}/include openssl
      export OPENSSL_PREFIX=$(realpath openssl)
    '';
    meta = {
      description = "Perl bindings for OpenSSL and LibreSSL";
      license = with lib.licenses; [ artistic2 ];
    };
  };

  NumberCompare = buildPerlPackage {
    pname = "Number-Compare";
    version = "0.03";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RC/RCLAMP/Number-Compare-0.03.tar.gz";
      hash = "sha256-gyk3N+gDtDESgwRD+1II7FIIoubqUS7VTvjk3SuICCc=";
    };
    meta = {
      description = "Numeric comparisons";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  OLEStorage_Lite = buildPerlPackage {
    pname = "OLE-Storage_Lite";
    version = "0.22";
    src = fetchurl {
      url = "mirror://cpan/authors/id/J/JM/JMCNAMARA/OLE-Storage_Lite-0.22.tar.gz";
      hash = "sha256-0FZtbCnTl+pzY3ncUVw2hJ9rlxB89wC6glBQXJhM+WU=";
    };
    meta = {
      description = "Read and write OLE storage files";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  Opcodes = buildPerlPackage {
    pname = "Opcodes";
    version = "0.14";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RU/RURBAN/Opcodes-0.14.tar.gz";
      hash = "sha256-f3NlRH5NHFuHtDCRRI8EiOZ8nwNrJsAipUCc1z00OJM=";
    };
    meta = {
      description = "More Opcodes information from opnames.h and opcode.h";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  PackageDeprecationManager = buildPerlPackage {
    pname = "Package-DeprecationManager";
    version = "0.18";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DR/DROLSKY/Package-DeprecationManager-0.18.tar.gz";
      hash = "sha256-to0/DO1Vt2Ff3btgKbifkqNP4N2Mb9a87/wVfVaDT+g=";
    };
    buildInputs = [
      TestFatal
      TestWarnings
    ];
    propagatedBuildInputs = [
      PackageStash
      ParamsUtil
      SubInstall
      SubName
    ];
    meta = {
      description = "Manage deprecation warnings for your distribution";
      homepage = "https://metacpan.org/release/Package-DeprecationManager";
      license = with lib.licenses; [ artistic2 ];
    };
  };

  PackageStash = buildPerlPackage {
    pname = "Package-Stash";
    version = "0.40";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETHER/Package-Stash-0.40.tar.gz";
      hash = "sha256-WpcixtnLKe4TPl97CKU2J2KgtWM/9RcGQqWwaG6V4GY=";
    };
    buildInputs = [
      CPANMetaCheck
      TestFatal
      TestNeeds
      TestRequires
    ];
    propagatedBuildInputs = [
      DistCheckConflicts
      ModuleImplementation
    ];
    meta = {
      description = "Routines for manipulating stashes";
      homepage = "https://github.com/moose/Package-Stash";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
      mainProgram = "package-stash-conflicts";
    };
  };

  PackageStashXS = buildPerlPackage {
    pname = "Package-Stash-XS";
    version = "0.30";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETHER/Package-Stash-XS-0.30.tar.gz";
      hash = "sha256-JrrWXBlZxXN5s+E53HdvvsX3ApBmF+8nzcKT3fEjkjE=";
    };
    buildInputs = [
      TestFatal
      TestNeeds
    ];
    meta = {
      description = "Faster and more correct implementation of the Package::Stash API";
      homepage = "https://github.com/moose/Package-Stash-XS";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ParamsUtil = buildPerlPackage {
    pname = "Params-Util";
    version = "1.102";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RE/REHSACK/Params-Util-1.102.tar.gz";
      hash = "sha256-SZuxtILbJP2id6UVJVlq0JLCvVHdUI+o/sLp+EkJdAI=";
    };
    meta = {
      description = "Simple, compact and correct param-checking functions";
      homepage = "https://metacpan.org/release/Params-Util";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ParamsValidationCompiler = buildPerlPackage {
    pname = "Params-ValidationCompiler";
    version = "0.31";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DR/DROLSKY/Params-ValidationCompiler-0.31.tar.gz";
      hash = "sha256-e2SXFz8batsp9dUdjPnsNtLxIZQStLJBDp13qQHoSm0=";
    };
    propagatedBuildInputs = [
      EvalClosure
      ExceptionClass
    ];
    buildInputs = [
      Specio
      Test2PluginNoWarnings
      Test2Suite
      TestWithoutModule
    ];
    meta = {
      description = "Build an optimized subroutine parameter validator once, use it forever";
      homepage = "https://metacpan.org/release/Params-ValidationCompiler";
      license = with lib.licenses; [ artistic2 ];
    };
  };

  PathTiny = buildPerlPackage {
    pname = "Path-Tiny";
    version = "0.144";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DA/DAGOLDEN/Path-Tiny-0.144.tar.gz";
      hash = "sha256-9uoJTs6EXJUqAsJ4kzJXk1TejUEKcH+bcEW9JBIGSH0=";
    };
    preConfigure = ''
      substituteInPlace lib/Path/Tiny.pm --replace 'use File::Spec 3.40' \
        'use File::Spec 3.39'
    '';
    # This appears to be currently failing tests, though I don't know why.
    # -- ocharles
    doCheck = false;
    meta = {
      description = "File path utility";
      homepage = "https://github.com/dagolden/Path-Tiny";
      license = with lib.licenses; [ asl20 ];
    };
  };

  PerlMagick = ImageMagick; # added 2021-08-02
  ImageMagick = buildPerlPackage rec {
    pname = "Image-Magick";
    inherit (pkgs.imagemagick) version src;
    sourceRoot = "${src.name}/PerlMagick";
    buildInputs = [ pkgs.imagemagick ];
    preConfigure = ''
      pushd ..
      chmod -R +rwX .
      ./configure --with-perl
      make perl-quantum-sources
      popd
    '';
    meta = {
      description = "Objected-oriented Perl interface to ImageMagick. Use it to read, manipulate, or write an image or image sequence from within a Perl script";
      license = with lib.licenses; [ imagemagick ];
    };
  };

  PkgConfig = buildPerlPackage rec {
    pname = "PkgConfig";
    version = "0.25026";
    src = fetchurl {
      url = "mirror://cpan/authors/id/P/PL/PLICEASE/PkgConfig-0.25026.tar.gz";
      hash = "sha256-Tbpe08LWpoG5XF6/FLammVzmmRrkcZutfxqvOOmHwqA=";
    };
    # support cross-compilation by simplifying the way we get version during build
    postPatch = ''
      substituteInPlace Makefile.PL --replace \
        'do { require "./lib/PkgConfig.pm"; $PkgConfig::VERSION; }' \
        '"${version}"'
    '';
    meta = {
      description = "Pure-Perl Core-Only replacement for pkg-config";
      homepage = "https://metacpan.org/pod/PkgConfig";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
      mainProgram = "ppkg-config";
    };
  };

  Po4a = callPackage ./Po4a { };

  ProcProcessTable = buildPerlPackage {
    pname = "Proc-ProcessTable";
    version = "0.636";
    src = fetchurl {
      url = "mirror://cpan/authors/id/J/JW/JWB/Proc-ProcessTable-0.636.tar.gz";
      hash = "sha256-lEIk/7APwe81BpYzdwoK/ahiO1x1MtHkq0ip3zlIkP0=";
    };
    meta = {
      description = "Perl extension to access the unix process table";
      license = with lib.licenses; [ artistic2 ];
    };
  };

  PadWalker = buildPerlPackage {
    pname = "PadWalker";
    version = "2.5";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RO/ROBIN/PadWalker-2.5.tar.gz";
      hash = "sha256-B7Jqu4QRRq8yByqNaMuQF2/7F2/ZJo5vL30Qb4F6DNA=";
    };
    meta = {
      description = "Play with other peoples' lexical variables";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  PodParser = buildPerlPackage {
    pname = "Pod-Parser";
    version = "1.66";
    src = fetchurl {
      url = "mirror://cpan/authors/id/M/MA/MAREKR/Pod-Parser-1.66.tar.gz";
      hash = "sha256-IpKKe//mG0UsBbu7j1IW1LnPn+KoSbd2wlUA0k0g33w=";
    };
    meta = {
      description = "Modules for parsing/translating POD format documents";
      license = with lib.licenses; [ artistic1 ];
      mainProgram = "podselect";
    };
  };

  Readonly = buildPerlModule {
    pname = "Readonly";
    version = "2.05";
    src = fetchurl {
      url = "mirror://cpan/authors/id/S/SA/SANKO/Readonly-2.05.tar.gz";
      hash = "sha256-SyNUJJGvAQ1EpcfIYSRHOKzHSrq65riDjTVN+xlGK14=";
    };
    buildInputs = [ ModuleBuildTiny ];
    meta = {
      description = "Facility for creating read-only scalars, arrays, hashes";
      homepage = "https://github.com/sanko/readonly";
      license = with lib.licenses; [ artistic2 ];
    };
  };

  RoleTiny = buildPerlPackage {
    pname = "Role-Tiny";
    version = "2.002004";
    src = fetchurl {
      url = "mirror://cpan/authors/id/H/HA/HAARG/Role-Tiny-2.002004.tar.gz";
      hash = "sha256-173unhOKT4OqUtCpgWJWRL2of/FmQt+oRdy0TZokK0U=";
    };
    meta = {
      description = "Roles: a nouvelle cuisine portion size slice of Moose";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  ScopeGuard = buildPerlPackage {
    pname = "Scope-Guard";
    version = "0.21";
    src = fetchurl {
      url = "mirror://cpan/authors/id/C/CH/CHOCOLATE/Scope-Guard-0.21.tar.gz";
      hash = "sha256-jJsb6lxWRI4sP63GXQW+nkaQo4I6gPOdLxD92Pd30ng=";
    };
    meta = {
      description = "Lexically-scoped resource management";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  SGMLSpm = buildPerlModule {
    pname = "SGMLSpm";
    version = "1.1";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RA/RAAB/SGMLSpm-1.1.tar.gz";
      hash = "sha256-VQySRSkcjfIkL36I95IaD2NsfuySxkRBjn2Jz+pwsr0=";
    };
    meta = {
      description = "Library for parsing the output from SGMLS and NSGMLS parsers";
      license = with lib.licenses; [ gpl2Plus ];
      mainProgram = "sgmlspl.pl";
    };
  };

  Specio = buildPerlPackage {
    pname = "Specio";
    version = "0.48";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DR/DROLSKY/Specio-0.48.tar.gz";
      hash = "sha256-DIV5NYDxJ07wgXMHkTHRAfd7IqzOp6+oJVIC8IEWgrI=";
    };
    propagatedBuildInputs = [
      DevelStackTrace
      EvalClosure
      MROCompat
      ModuleRuntime
      RoleTiny
      SubQuote
      TryTiny
    ];
    buildInputs = [
      TestFatal
      TestNeeds
    ];
    meta = {
      description = "Type constraints and coercions for Perl";
      homepage = "https://metacpan.org/release/Specio";
      license = with lib.licenses; [ artistic2 ];
    };
  };

  Spiffy = buildPerlPackage {
    pname = "Spiffy";
    version = "0.46";
    src = fetchurl {
      url = "mirror://cpan/authors/id/I/IN/INGY/Spiffy-0.46.tar.gz";
      hash = "sha256-j1hiCoQgJVxJtsQ8X/WAK9JeTwkkDFHlvysCKDPUHaM=";
    };
    meta = {
      description = "Spiffy Perl Interface Framework For You";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  SpreadsheetParseExcel = buildPerlPackage {
    pname = "Spreadsheet-ParseExcel";
    version = "0.66";
    src = fetchurl {
      url = "mirror://cpan/authors/id/J/JM/JMCNAMARA/Spreadsheet-ParseExcel-0.66.tar.gz";
      hash = "sha256-v9dqz7qYhgHcBRvac7S7JfaDmgBt2WC2p0AcJJJF9ls=";
    };
    propagatedBuildInputs = [
      CryptRC4
      DigestPerlMD5
      IOStringy
      OLEStorage_Lite
    ];
    meta = {
      description = "Read information from an Excel file";
      homepage = "https://github.com/runrig/spreadsheet-parseexcel";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  StringShellQuote = buildPerlPackage {
    pname = "String-ShellQuote";
    version = "1.04";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RO/ROSCH/String-ShellQuote-1.04.tar.gz";
      hash = "sha256-5gY2UDjOINZG0lXIBe/90y+GR18Y1DynVFWwDk2G3TU=";
    };
    doCheck = !stdenv.hostPlatform.isDarwin;
    meta = {
      description = "Quote strings for passing through the shell";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
      mainProgram = "shell-quote";
    };
  };

  strip-nondeterminism = callPackage ./patches/strip-nondeterminism { };

  SubExporter = buildPerlPackage {
    pname = "Sub-Exporter";
    version = "0.990";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RJ/RJBS/Sub-Exporter-0.990.tar.gz";
      hash = "sha256-vGTsWgaGX5zGdiFcBqlEizoMizl0/7I6JPjirQkFRPw=";
    };
    propagatedBuildInputs = [ DataOptList ];
    meta = {
      description = "Sophisticated exporter for custom-built routines";
      homepage = "https://github.com/rjbs/Sub-Exporter";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  SubExporterProgressive = buildPerlPackage {
    pname = "Sub-Exporter-Progressive";
    version = "0.001013";
    src = fetchurl {
      url = "mirror://cpan/authors/id/F/FR/FREW/Sub-Exporter-Progressive-0.001013.tar.gz";
      hash = "sha256-1TW3lU1k2hrBMFsfrfmCAnaeNZk3aFSyztkMOCvqwFY=";
    };
    meta = {
      description = "Only use Sub::Exporter if you need it";
      homepage = "https://github.com/frioux/Sub-Exporter-Progressive";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  SubIdentify = buildPerlPackage {
    pname = "Sub-Identify";
    version = "0.14";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RG/RGARCIA/Sub-Identify-0.14.tar.gz";
      hash = "sha256-Bo0nIIZRTdHoQrakCxvtuv7mOQDlsIiQ72cAA53vrW8=";
    };
    meta = {
      description = "Retrieve names of code references";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  SubInfo = buildPerlPackage {
    pname = "Sub-Info";
    version = "0.002";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/EX/EXODIST/Sub-Info-0.002.tar.gz";
      hash = "sha256-6jBW1pa97/IamdNA1VcIh9OajMR7/yOt/ILfZ1jN0Oo=";
    };
    propagatedBuildInputs = [ Importer ];
    meta = {
      description = "Tool for inspecting subroutines";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  SubInstall = buildPerlPackage {
    pname = "Sub-Install";
    version = "0.929";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RJ/RJBS/Sub-Install-0.929.tar.gz";
      hash = "sha256-gLHigdjNOysx2scR9cihZXqHzYC75przkkvL605dsHc=";
    };
    meta = {
      description = "Install subroutines into packages easily";
      homepage = "https://github.com/rjbs/Sub-Install";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  SubName = buildPerlPackage {
    pname = "Sub-Name";
    version = "0.27";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETHER/Sub-Name-0.27.tar.gz";
      hash = "sha256-7PNvuhxHypPh2qOUlo7TnEGGhnRZ2c0XPEIeK5cgQ+g=";
    };
    buildInputs = [
      BC
      DevelCheckBin
    ];
    meta = {
      description = "(Re)name a sub";
      homepage = "https://github.com/p5sagit/Sub-Name";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  SubQuote = buildPerlPackage {
    pname = "Sub-Quote";
    version = "2.006008";
    src = fetchurl {
      url = "mirror://cpan/authors/id/H/HA/HAARG/Sub-Quote-2.006008.tar.gz";
      hash = "sha256-lL69UAr1V2LoPqLyvFlNh6+CgHI3DHEQxgwjioANFbI=";
    };
    buildInputs = [ TestFatal ];
    meta = {
      description = "Efficient generation of subroutines via string eval";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  SubUplevel = buildPerlPackage {
    pname = "Sub-Uplevel";
    version = "0.2800";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DA/DAGOLDEN/Sub-Uplevel-0.2800.tar.gz";
      hash = "sha256-tPP2O4D2gKQhMy2IUd2+Wo5y/Kp01dHZjzyMxKPs4pM=";
    };
    meta = {
      description = "Apparently run a function in a higher stack frame";
      homepage = "https://github.com/Perl-Toolchain-Gang/Sub-Uplevel";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  syntax = buildPerlPackage {
    pname = "syntax";
    version = "0.004";
    src = fetchurl {
      url = "mirror://cpan/authors/id/P/PH/PHAYLON/syntax-0.004.tar.gz";
      hash = "sha256-/hm22oqPQ6WqLuVxRBvA4zn7FW0AgcFXoaJOmBLH02U=";
    };
    propagatedBuildInputs = [
      DataOptList
      namespaceclean
    ];
    meta = {
      description = "Activate syntax extensions";
      homepage = "https://github.com/phaylon/syntax/wiki";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  SyntaxKeywordTry = buildPerlModule {
    pname = "Syntax-Keyword-Try";
    version = "0.29";
    src = fetchurl {
      url = "mirror://cpan/authors/id/P/PE/PEVANS/Syntax-Keyword-Try-0.29.tar.gz";
      hash = "sha256-zDIHGdNgjaqVFHQ6Q9rCvpnLjM2Ymx/vooUpDLHVnY8=";
    };
    buildInputs = [ Test2Suite ];
    propagatedBuildInputs = [ XSParseKeyword ];
    meta = {
      description = "Try/catch/finally syntax for perl";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];

    };
  };

  TermReadKey =
    let
      cross = stdenv.hostPlatform != stdenv.buildPlatform;
    in
    buildPerlPackage {
      pname = "TermReadKey";
      version = "2.38";
      src = fetchurl {
        url = "mirror://cpan/authors/id/J/JS/JSTOWE/TermReadKey-2.38.tar.gz";
        hash = "sha256-WmRYeNxXCsM2YVgfuwkP8k684X1D6lP9IuEFqFakcpA=";
      };

      # use native libraries from the host when running build commands
      postConfigure = lib.optionalString cross (
        let
          host_perl = perl.perlOnBuild;
          host_self = perl.perlOnBuild.pkgs.TermReadKey;
          perl_lib = "${host_perl}/lib/perl5/${host_perl.version}";
          self_lib = "${host_self}/lib/perl5/site_perl/${host_perl.version}";
        in
        ''
          sed -i -e 's|"-I$(INST_ARCHLIB)"|"-I${perl_lib}" "-I${self_lib}"|g' Makefile
        ''
      );

      # TermReadKey uses itself in the build process
      nativeBuildInputs = lib.optionals cross [
        perl.perlOnBuild.pkgs.TermReadKey
      ];
      meta = {
        description = "Perl module for simple terminal control";
        license = with lib.licenses; [
          artistic1
          gpl1Plus
        ];
      };
    };

  TermTable = buildPerlPackage {
    pname = "Term-Table";
    version = "0.017";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/EX/EXODIST/Term-Table-0.017.tar.gz";
      hash = "sha256-8R20JorYBE9uGhrJU0ygzTrXecQAb/83+uUA25j6yRo=";
    };
    propagatedBuildInputs = [ Importer ];
    meta = {
      description = "Format a header and rows into a table";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  Test2Harness = buildPerlPackage rec {
    pname = "Test2-Harness";
    version = "1.000161";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/EX/EXODIST/Test2-Harness-${version}.tar.gz";
      hash = "sha256-SXO3mx7tUwVxXuc9itySNtp5XH1AkNg7FQ6hMc1ltBQ=";
    };

    checkPhase = ''
      patchShebangs ./t ./scripts/yath
      export AUTOMATED_TESTING=1
      ./scripts/yath test -j $NIX_BUILD_CORES
    '';

    # The t/integration/preload.t test is broken on riscv64
    # https://github.com/Test-More/Test2-Harness/issues/290
    doCheck = !stdenv.hostPlatform.isRiscV;

    propagatedBuildInputs = [
      DataUUID
      Importer
      LongJump
      ScopeGuard
      TermTable
      Test2PluginMemUsage
      Test2PluginUUID
      Test2Suite
      YAMLTiny
      gotofile
    ];
    meta = {
      changelog = "https://github.com/Test-More/Test2-Harness/blob/v${version}/Changes";
      description = "New and improved test harness with better Test2 integration";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
      mainProgram = "yath";
      broken = stdenv.hostPlatform.isDarwin; # never built on Hydra https://hydra.nixos.org/job/nixpkgs/staging-next/perl534Packages.Test2Harness.x86_64-darwin
    };
  };

  Test2PluginMemUsage = buildPerlPackage {
    pname = "Test2-Plugin-MemUsage";
    version = "0.002003";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/EX/EXODIST/Test2-Plugin-MemUsage-0.002003.tar.gz";
      hash = "sha256-XgZi1agjrggWQfXOgoQxEe7BgxzTH4g6bG3lSv34fCU=";
    };
    buildInputs = [ Test2Suite ];
    meta = {
      description = "Collect and display memory usage information";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  Test2PluginUUID = buildPerlPackage {
    pname = "Test2-Plugin-UUID";
    version = "0.002001";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/EX/EXODIST/Test2-Plugin-UUID-0.002001.tar.gz";
      hash = "sha256-TGyNSE1xU9h3ncFVqZKyAwlbXFqhz7Hui87c0GAYeMk=";
    };
    buildInputs = [ Test2Suite ];
    propagatedBuildInputs = [ DataUUID ];
    meta = {
      description = "Use REAL UUIDs in Test2";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  Test2PluginNoWarnings = buildPerlPackage {
    pname = "Test2-Plugin-NoWarnings";
    version = "0.09";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DR/DROLSKY/Test2-Plugin-NoWarnings-0.09.tar.gz";
      hash = "sha256-vj3YAAQu7zYr8X0gVs+ek03ukczOmOTxeLj7V3Ly+3Q=";
    };
    buildInputs = [
      IPCRun3
      Test2Suite
    ];
    propagatedBuildInputs = [ TestSimple13 ];
    meta = {
      description = "Fail if tests warn";
      homepage = "https://metacpan.org/release/Test2-Plugin-NoWarnings";
      license = with lib.licenses; [ artistic2 ];
    };
  };

  Test2Suite = buildPerlPackage {
    pname = "Test2-Suite";
    version = "0.000156";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/EX/EXODIST/Test2-Suite-0.000156.tar.gz";
      hash = "sha256-vzgq5y86k79+02iFEY+uL/qw/xF3Q/WQON8lTv7yyU4=";
    };
    propagatedBuildInputs = [
      ModulePluggable
      ScopeGuard
      SubInfo
      TermTable
      TestSimple13
    ];
    meta = {
      description = "Distribution with a rich set of tools built upon the Test2 framework";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TestBase = buildPerlPackage {
    pname = "Test-Base";
    version = "0.89";
    src = fetchurl {
      url = "mirror://cpan/authors/id/I/IN/INGY/Test-Base-0.89.tar.gz";
      hash = "sha256-J5Shqq6x06KH3SxyhiWGY3llYvfbnMxrQkvE8d6K0BQ=";
    };
    propagatedBuildInputs = [ Spiffy ];
    buildInputs = [
      AlgorithmDiff
      TextDiff
    ];
    meta = {
      description = "Data Driven Testing Framework";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TestCleanNamespaces = buildPerlPackage {
    pname = "Test-CleanNamespaces";
    version = "0.24";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETHER/Test-CleanNamespaces-0.24.tar.gz";
      hash = "sha256-M41VaejommVJNfhD7AvISqpIb+jdGJj7nKs+zOzVMno=";
    };
    buildInputs = [
      Filepushd
      Moo
      Mouse
      RoleTiny
      SubExporter
      TestDeep
      TestNeeds
      TestWarnings
      namespaceclean
    ];
    propagatedBuildInputs = [
      PackageStash
      SubIdentify
    ];
    meta = {
      description = "Check for uncleaned imports";
      homepage = "https://github.com/karenetheridge/Test-CleanNamespaces";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TestDeep = buildPerlPackage {
    pname = "Test-Deep";
    version = "1.204";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RJ/RJBS/Test-Deep-1.204.tar.gz";
      hash = "sha256-tlkfbM3YU8fvyf88V1Y3BAMhHP/kYEfwgrHNFhGoTl8=";
    };
    meta = {
      description = "Extremely flexible deep comparison";
      homepage = "https://github.com/rjbs/Test-Deep";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TestException = buildPerlPackage {
    pname = "Test-Exception";
    version = "0.43";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/EX/EXODIST/Test-Exception-0.43.tar.gz";
      hash = "sha256-FWsT8Hdk92bYtFpDco8kOa+Bo1EmJUON6reDt4g+tTM=";
    };
    propagatedBuildInputs = [ SubUplevel ];
    meta = {
      description = "Test exception-based code";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TestFatal = buildPerlPackage {
    pname = "Test-Fatal";
    version = "0.017";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RJ/RJBS/Test-Fatal-0.017.tar.gz";
      hash = "sha256-N9//2vuEt2Lv6WsC+yqkHzcCbHPmuDWQ23YilpfzxKY=";
    };
    propagatedBuildInputs = [ TryTiny ];
    meta = {
      description = "Incredibly simple helpers for testing code with exceptions";
      homepage = "https://github.com/rjbs/Test-Fatal";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TestFile = buildPerlPackage {
    pname = "Test-File";
    version = "1.993";
    src = fetchurl {
      url = "mirror://cpan/authors/id/B/BD/BDFOY/Test-File-1.993.tar.gz";
      hash = "sha256-7y/+Gq7HtC2HStQR7GR1R7m5vC9fuT5J4zmUiEVq/Ho=";
    };
    meta = {
      description = "Test file attributes";
      homepage = "https://github.com/briandfoy/test-file";
      license = with lib.licenses; [ artistic2 ];
    };
  };

  TestFork = buildPerlModule {
    pname = "Test-Fork";
    version = "0.02";
    src = fetchurl {
      url = "mirror://cpan/authors/id/M/MS/MSCHWERN/Test-Fork-0.02.tar.gz";
      hash = "sha256-/P77+yT4havoJ8KtB6w9Th/s8hOhRxf8rzw3F1BF0D4=";
    };
    meta = {
      description = "Test code which forks";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TestLeakTrace = buildPerlPackage {
    pname = "Test-LeakTrace";
    version = "0.17";
    src = fetchurl {
      url = "mirror://cpan/authors/id/L/LE/LEEJO/Test-LeakTrace-0.17.tar.gz";
      hash = "sha256-d31k0pOPXqWGMA7vl+8D6stD1MGFPJw7EJHrMxFGeXA=";
    };
    meta = {
      description = "Traces memory leaks";
      homepage = "https://metacpan.org/release/Test-LeakTrace";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TestMemoryCycle = buildPerlPackage {
    pname = "Test-Memory-Cycle";
    version = "1.06";
    src = fetchurl {
      url = "mirror://cpan/authors/id/P/PE/PETDANCE/Test-Memory-Cycle-1.06.tar.gz";
      hash = "sha256-nVPd/clkzYRUyw2kxpW2o65HtFg5KRw0y52NHPqrMgI=";
    };
    propagatedBuildInputs = [
      DevelCycle
      PadWalker
    ];
    meta = {
      description = "Verifies code hasn't left circular references";
      license = with lib.licenses; [ artistic2 ];
    };
  };

  TestMockModule = buildPerlModule {
    pname = "Test-MockModule";
    version = "0.177.0";
    src = fetchurl {
      url = "mirror://cpan/authors/id/G/GF/GFRANKS/Test-MockModule-v0.177.0.tar.gz";
      hash = "sha256-G9p6SdzqdgdtQKe2psPz4V5rGchLYXHfRFNNkROPEEU=";
    };
    propagatedBuildInputs = [ SUPER ];
    buildInputs = [ TestWarnings ];
    meta = {
      description = "Override subroutines in a module for unit testing";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  SUPER = buildPerlModule {
    pname = "SUPER";
    version = "1.20190531";
    src = fetchurl {
      url = "mirror://cpan/authors/id/C/CH/CHROMATIC/SUPER-1.20190531.tar.gz";
      hash = "sha256-aF0e525/DpAGlCkjv334sRwQcTKZKRdZPc9zl9QX05o=";
    };
    propagatedBuildInputs = [ SubIdentify ];
    meta = {
      description = "Control superclass method dispatch";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TestNeeds = buildPerlPackage {
    pname = "Test-Needs";
    version = "0.002010";
    src = fetchurl {
      url = "mirror://cpan/authors/id/H/HA/HAARG/Test-Needs-0.002010.tar.gz";
      hash = "sha256-kj/9x4/LqWYJdT5LriawugGGiT3kpjzVI24BLHyQ4gg=";
    };
    meta = {
      description = "Skip tests when modules not available";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TestNoWarnings = buildPerlPackage {
    pname = "Test-NoWarnings";
    version = "1.06";
    src = fetchurl {
      url = "mirror://cpan/authors/id/H/HA/HAARG/Test-NoWarnings-1.06.tar.gz";
      hash = "sha256-wtxRFDt+tjIxIQ4n3yDSyDk3cuCjM1R+yLeiBe1i9zc=";
    };
    meta = {
      description = "Make sure you didn't emit any warnings while testing";
      license = with lib.licenses; [ lgpl21Only ];
    };
  };

  TestOutput = buildPerlPackage {
    pname = "Test-Output";
    version = "1.034";
    src = fetchurl {
      url = "mirror://cpan/authors/id/B/BD/BDFOY/Test-Output-1.034.tar.gz";
      hash = "sha256-zULigBwNK0gtGMn7SwbHVwVIGLy7KCTl378zrXo9aaA=";
    };
    propagatedBuildInputs = [ CaptureTiny ];
    meta = {
      description = "Utilities to test STDOUT and STDERR messages";
      license = with lib.licenses; [ artistic2 ];
    };
  };

  TestRequires = buildPerlPackage {
    pname = "Test-Requires";
    version = "0.11";
    src = fetchurl {
      url = "mirror://cpan/authors/id/T/TO/TOKUHIROM/Test-Requires-0.11.tar.gz";
      hash = "sha256-S4jeVJWX7s3ffDw4pNAgShb1mtgEV3tnGJasBOJOBA8=";
    };
    meta = {
      description = "Checks to see if the module can be loaded";
      homepage = "https://github.com/tokuhirom/Test-Requires";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TestRequiresInternet = buildPerlPackage {
    pname = "Test-RequiresInternet";
    version = "0.05";
    src = fetchurl {
      url = "mirror://cpan/authors/id/M/MA/MALLEN/Test-RequiresInternet-0.05.tar.gz";
      hash = "sha256-u6ezKhzA1Yzi7CCyAKc0fGljFkHoyuj/RWetJO8egz4=";
    };
    meta = {
      description = "Easily test network connectivity";
      homepage = "https://metacpan.org/dist/Test-RequiresInternet";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TestSimple13 = buildPerlPackage {
    pname = "Test-Simple";
    version = "1.302195";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/EX/EXODIST/Test-Simple-1.302195.tar.gz";
      hash = "sha256-s5C7I1kuC5Rsla27PDCxG8Y0ooayhHvmEa2SnFfjmmw=";
    };
    meta = {
      description = "Basic utilities for writing tests";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TestWarn = buildPerlPackage {
    pname = "Test-Warn";
    version = "0.37";
    src = fetchurl {
      url = "mirror://cpan/authors/id/B/BI/BIGJ/Test-Warn-0.37.tar.gz";
      hash = "sha256-mMoy5/L16om4v7mgYJl389FT4kLi5RcFEmy5VPGga1c=";
    };
    propagatedBuildInputs = [ SubUplevel ];
    meta = {
      description = "Perl extension to test methods for warnings";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TestWarnings = buildPerlPackage {
    pname = "Test-Warnings";
    version = "0.032";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETHER/Test-Warnings-0.032.tar.gz";
      hash = "sha256-Ryfa4kFunwfkHi3DqRQ7pq/8HsV2UhF8mdUAOOMT6dk=";
    };
    buildInputs = [
      CPANMetaCheck
      PadWalker
    ];
    meta = {
      description = "Test for warnings and the lack of them";
      homepage = "https://github.com/karenetheridge/Test-Warnings";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TestWithoutModule = buildPerlPackage {
    pname = "Test-Without-Module";
    version = "0.21";
    src = fetchurl {
      url = "mirror://cpan/authors/id/C/CO/CORION/Test-Without-Module-0.21.tar.gz";
      hash = "sha256-PN6vraxIU+vq/miTRtVV2l36PPqdTITj5ee/7lC+7EY=";
    };
    meta = {
      description = "Test fallback behaviour in absence of modules";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TestYAML = buildPerlPackage {
    pname = "Test-YAML";
    version = "1.07";
    src = fetchurl {
      url = "mirror://cpan/authors/id/T/TI/TINITA/Test-YAML-1.07.tar.gz";
      hash = "sha256-HzANA09GKYy5KWCRLMBLrDP7J/BbiFLY8FHhELnNmV8=";
    };
    buildInputs = [ TestBase ];
    meta = {
      description = "Testing Module for YAML Implementations";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
      mainProgram = "test-yaml";
    };
  };

  TextCharWidth = buildPerlPackage {
    pname = "Text-CharWidth";
    version = "0.04";
    src = fetchurl {
      url = "mirror://cpan/authors/id/K/KU/KUBOTA/Text-CharWidth-0.04.tar.gz";
      hash = "sha256-q97V9P3ZM46J/S8dgnHESYna5b9Qrs5BthedjiMHBPg=";
    };
    meta = {
      description = "Get number of occupied columns of a string on terminal";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TextDiff = buildPerlPackage {
    pname = "Text-Diff";
    version = "1.45";
    src = fetchurl {
      url = "mirror://cpan/authors/id/N/NE/NEILB/Text-Diff-1.45.tar.gz";
      hash = "sha256-6Lqgexs/U+AK82NomLv3OuyaD/OPlFNu3h2+lu8IbwQ=";
    };
    propagatedBuildInputs = [ AlgorithmDiff ];
    meta = {
      description = "Perform diffs on files and record sets";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TextGlob = buildPerlPackage {
    pname = "Text-Glob";
    version = "0.11";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RC/RCLAMP/Text-Glob-0.11.tar.gz";
      hash = "sha256-BpzNSdPwot7bEV9L3J+6wHqDWShAlT0fzfw5650wUoc=";
    };
    meta = {
      description = "Match globbing patterns against text";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TextWrapI18N = buildPerlPackage {
    pname = "Text-WrapI18N";
    version = "0.06";
    src = fetchurl {
      url = "mirror://cpan/authors/id/K/KU/KUBOTA/Text-WrapI18N-0.06.tar.gz";
      hash = "sha256-S9KaF/DCx5LRLBAFs8J28qsPrjnACFmuF0HXlBhGpIg=";
    };
    buildInputs = lib.optionals (!stdenv.hostPlatform.isDarwin) [ pkgs.glibcLocales ];
    propagatedBuildInputs = [ TextCharWidth ];
    preConfigure = ''
      substituteInPlace WrapI18N.pm --replace '/usr/bin/locale' '${pkgs.unixtools.locale}/bin/locale'
    '';
    meta = {
      description = "Line wrapping module with support for multibyte, fullwidth, and combining characters and languages without whitespaces between words";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TimeDate = buildPerlPackage {
    pname = "TimeDate";
    version = "2.33";
    src = fetchurl {
      url = "mirror://cpan/authors/id/A/AT/ATOOMIC/TimeDate-2.33.tar.gz";
      hash = "sha256-wLacSwOd5vUBsNnxPsWMhrBAwffpsn7ySWUcFD1gXrI=";
    };
    meta = {
      description = "Miscellaneous timezone manipulations routines";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  TimeDuration = buildPerlPackage {
    pname = "Time-Duration";
    version = "1.21";
    src = fetchurl {
      url = "mirror://cpan/authors/id/N/NE/NEILB/Time-Duration-1.21.tar.gz";
      hash = "sha256-/jQOuodl+SY2lGdOXf8UgzRD4Zhl5f9Ce715t7X4qbg=";
    };
    meta = {
      description = "Rounded or exact English expression of durations";
      homepage = "https://github.com/neilbowers/Time-Duration";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  Tk = buildPerlPackage {
    pname = "Tk";
    version = "804.036";
    src = fetchurl {
      url = "mirror://cpan/authors/id/S/SR/SREZIC/Tk-804.036.tar.gz";
      hash = "sha256-Mqpycaa9/twzMBGbOCXa3dCqS1yTb4StdOq7kyogCl4=";
    };
    patches = [
      # Fix failing configure test due to implicit int return value of main, which results
      # in an error with clang 16.
      ./patches/tk-configure-implicit-int-fix.patch
    ];
    postPatch = ''
      substituteInPlace pTk/mTk/additions/imgWindow.c \
        --replace-fail '"X11/Xproto.h"' "<X11/Xproto.h>"
      substituteInPlace PNG/zlib/Makefile.in \
        --replace-fail '$(AR) $@' '$(AR) rc $@'
      substituteInPlace PNG/libpng/scripts/makefile.gcc \
        --replace-fail 'AR_RC = ar rcs' 'AR_RC = ${pkgs.stdenv.cc.targetPrefix}ar rcs'
      substituteInPlace JPEG/jpeg/makefile.cfg \
        --replace-fail 'AR= ar rc' 'AR= ${pkgs.stdenv.cc.targetPrefix}ar rc'
    '';
    makeMakerFlags = [
      "AR=${pkgs.stdenv.cc.targetPrefix}ar"
      "X11INC=${pkgs.libx11.dev}/include"
      "X11LIB=${pkgs.libx11.out}/lib"
    ];
    buildInputs = [
      pkgs.libx11
      pkgs.libpng
    ];
    env = lib.optionalAttrs stdenv.cc.isGNU {
      NIX_CFLAGS_COMPILE = toString [
        "-Wno-error=implicit-int"
        "-Wno-error=incompatible-pointer-types"
      ];
    };
    doCheck = false; # Expects working X11.
    meta = {
      description = "Tk - a Graphical User Interface Toolkit";
      license = with lib.licenses; [ tcltk ];
    };
  };

  TryTiny = buildPerlPackage {
    pname = "Try-Tiny";
    version = "0.31";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETHER/Try-Tiny-0.31.tar.gz";
      hash = "sha256-MwDTHYpAdbJtj0bOhkodkT4OhGfO66ZlXV0rLiBsEb4=";
    };
    buildInputs = [
      CPANMetaCheck
      CaptureTiny
    ];
    meta = {
      description = "Minimal try/catch with proper preservation of $@";
      homepage = "https://github.com/p5sagit/Try-Tiny";
      license = with lib.licenses; [ mit ];
    };
  };

  TypeTiny = buildPerlPackage {
    pname = "Type-Tiny";
    version = "2.004000";
    src = fetchurl {
      url = "mirror://cpan/authors/id/T/TO/TOBYINK/Type-Tiny-2.004000.tar.gz";
      hash = "sha256-aX5/d17fyF9M8HeS0E/RmwnCUoX5j1k46O/E90UHoSg=";
    };
    propagatedBuildInputs = [ ExporterTiny ];
    buildInputs = [ TestMemoryCycle ];
    meta = {
      description = "Tiny, yet Moo(se)-compatible type constraint";
      homepage = "https://typetiny.toby.ink";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  UnicodeLineBreak = buildPerlPackage {
    pname = "Unicode-LineBreak";
    version = "2019.001";
    src = fetchurl {
      url = "mirror://cpan/authors/id/N/NE/NEZUMI/Unicode-LineBreak-2019.001.tar.gz";
      hash = "sha256-SGdi5MrN3Md7E5ifl5oCn4RjC4F15/7xeYnhV9S2MYo=";
    };
    propagatedBuildInputs = [ MIMECharset ];
    meta = {
      description = "UAX #14 Unicode Line Breaking Algorithm";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  URI = buildPerlPackage {
    pname = "URI";
    version = "5.21";
    src = fetchurl {
      url = "mirror://cpan/authors/id/O/OA/OALDERS/URI-5.21.tar.gz";
      hash = "sha256-liZYYM1hveFuhBXc+/EIBW3hYsqgrDf4HraVydLgq3c=";
    };
    buildInputs = [
      TestFatal
      TestNeeds
      TestWarnings
    ];
    meta = {
      description = "Uniform Resource Identifiers (absolute and relative)";
      homepage = "https://github.com/libwww-perl/URI";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  Version = buildPerlPackage {
    pname = "version";
    version = "0.9930";
    src = fetchurl {
      url = "mirror://cpan/authors/id/L/LE/LEONT/version-0.9930.tar.gz";
      hash = "sha256-YduVX7yzn1kC+myLlXrrJ0HiPUhA+Eq/hGrx9nCu7jA=";
    };
    meta = {
      description = "Structured version objects";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  WWWMechanize = buildPerlPackage {
    pname = "WWW-Mechanize";
    version = "2.17";
    src = fetchurl {
      url = "mirror://cpan/authors/id/S/SI/SIMBABQUE/WWW-Mechanize-2.17.tar.gz";
      hash = "sha256-nAIAPoRiHeoSyYDEEB555PjK5OOCzT2iOfqovRmPBjo=";
    };
    propagatedBuildInputs = [
      HTMLForm
      HTMLTree
      LWP
    ];
    doCheck = false;
    buildInputs = [
      CGI
      HTTPServerSimple
      PathTiny
      TestDeep
      TestFatal
      TestOutput
      TestWarnings
    ];
    meta = {
      description = "Handy web browsing in a Perl object";
      homepage = "https://github.com/libwww-perl/WWW-Mechanize";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
      mainProgram = "mech-dump";
    };
  };

  WWWRobotRules = buildPerlPackage {
    pname = "WWW-RobotRules";
    version = "6.02";
    src = fetchurl {
      url = "mirror://cpan/authors/id/G/GA/GAAS/WWW-RobotRules-6.02.tar.gz";
      hash = "sha256-RrUC56KI1VlCmJHutdl5Rh3T7MalxJHq2F0WW24DpR4=";
    };
    propagatedBuildInputs = [ URI ];
    meta = {
      description = "Database of robots.txt-derived permissions";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  XMLNamespaceSupport = buildPerlPackage {
    pname = "XML-NamespaceSupport";
    version = "1.12";
    src = fetchurl {
      url = "mirror://cpan/authors/id/P/PE/PERIGRIN/XML-NamespaceSupport-1.12.tar.gz";
      hash = "sha256-R+mVhZ+N0EE6o/ItNQxKYtplLoVCZ6oFhq5USuK65e8=";
    };
    meta = {
      description = "Simple generic namespace processor";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  XMLParser = buildPerlPackage {
    pname = "XML-Parser";
    version = "2.46";
    src = fetchurl {
      url = "mirror://cpan/authors/id/T/TO/TODDR/XML-Parser-2.46.tar.gz";
      hash = "sha256-0zEzJJHFHMz7TLlP/ET5zXM3jmGEmNSjffngQ2YcUV0=";
    };
    patches = [ ./patches/xml-parser-0001-HACK-Assumes-Expat-paths-are-good.patch ];
    postPatch =
      lib.optionalString (stdenv.buildPlatform != stdenv.hostPlatform) ''
        substituteInPlace Expat/Makefile.PL --replace 'use English;' '#'
      ''
      + lib.optionalString stdenv.hostPlatform.isCygwin ''
        sed -i -e "s@my \$compiler = File::Spec->catfile(\$path, \$cc\[0\]) \. \$Config{_exe};@my \$compiler = File::Spec->catfile(\$path, \$cc\[0\]) \. (\$^O eq 'cygwin' ? \"\" : \$Config{_exe});@" inc/Devel/CheckLib.pm
      '';
    makeMakerFlags = [
      "EXPATLIBPATH=${pkgs.expat.out}/lib"
      "EXPATINCPATH=${pkgs.expat.dev}/include"
    ];
    propagatedBuildInputs = [ LWP ];
    meta = {
      description = "Perl module for parsing XML documents";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  XMLSAX = buildPerlPackage {
    pname = "XML-SAX";
    version = "1.02";
    src = fetchurl {
      url = "mirror://cpan/authors/id/G/GR/GRANTM/XML-SAX-1.02.tar.gz";
      hash = "sha256-RQbDhwQ6pqd7RV8A9XQJ83IKp+VTSVqyU1JjtO0eoSo=";
    };
    propagatedBuildInputs = [
      XMLNamespaceSupport
      XMLSAXBase
    ];
    postPatch = ''
      substituteInPlace Makefile.PL \
        --replace-fail "\$(PERL)" "${lib.getExe perl.perlOnBuild}"
    '';
    meta = {
      description = "Simple API for XML";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  XMLSAXBase = buildPerlPackage {
    pname = "XML-SAX-Base";
    version = "1.09";
    src = fetchurl {
      url = "mirror://cpan/authors/id/G/GR/GRANTM/XML-SAX-Base-1.09.tar.gz";
      hash = "sha256-Zss1W6TvR8EMpzi9NZmXI2RDhqyFOrvrUTKEH16KKtA=";
    };
    meta = {
      description = "Base class for SAX Drivers and Filters";
      homepage = "https://github.com/grantm/XML-SAX-Base";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  XMLSAXExpat = buildPerlPackage {
    pname = "XML-SAX-Expat";
    version = "0.51";
    src = fetchurl {
      url = "mirror://cpan/authors/id/B/BJ/BJOERN/XML-SAX-Expat-0.51.tar.gz";
      hash = "sha256-TAFiE9DOfbLElOMAhrWZF7MC24wpLc0h853uvZeAyD8=";
    };
    propagatedBuildInputs = [
      XMLParser
      XMLSAX
    ];
    # Avoid creating perllocal.pod, which contains a timestamp
    installTargets = [ "pure_install" ];
    meta = {
      description = "SAX Driver for Expat";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  XMLSimple = buildPerlPackage {
    pname = "XML-Simple";
    version = "2.25";
    src = fetchurl {
      url = "mirror://cpan/authors/id/G/GR/GRANTM/XML-Simple-2.25.tar.gz";
      hash = "sha256-Ux/drr6iQWdD61xP36sCj1AhI9miIEBaQQDmj8SA2/g=";
    };
    propagatedBuildInputs = [ XMLSAXExpat ];
    meta = {
      description = "API for simple XML files";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  XMLWriter = buildPerlPackage {
    pname = "XML-Writer";
    version = "0.900";
    src = fetchurl {
      url = "mirror://cpan/authors/id/J/JO/JOSEPHW/XML-Writer-0.900.tar.gz";
      hash = "sha256-c8j1vT7PKzUPStrm1mdtUuCOzC199KnwifpoNg1ADR8=";
    };
    meta = {
      description = "Module for creating a XML document object oriented with on the fly validating towards the given DTD";
      license = with lib.licenses; [ gpl1Only ];
    };
  };

  XSParseKeyword = buildPerlModule {
    pname = "XS-Parse-Keyword";
    version = "0.48";
    src = fetchurl {
      url = "mirror://cpan/authors/id/P/PE/PEVANS/XS-Parse-Keyword-0.48.tar.gz";
      hash = "sha256-hXoHC6Rlq1uJ1NjTbZI1jt1m5ee0qRWEYR2FElrJqcc=";
    };
    buildInputs = [
      ExtUtilsCChecker
      Test2Suite
    ];
    propagatedBuildInputs = [ FileShareDir ];
    meta = {
      description = "XS functions to assist in parsing keyword syntax";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];

    };
  };

  YAML = buildPerlPackage {
    pname = "YAML";
    version = "1.30";
    src = fetchurl {
      url = "mirror://cpan/authors/id/T/TI/TINITA/YAML-1.30.tar.gz";
      hash = "sha256-UDCm1sv/rxJYMFC/VSqoANRkbKlnjBh63WSSJ/V0ec0=";
    };

    buildInputs = [
      TestBase
      TestDeep
      TestYAML
    ];

    meta = {
      description = "YAML Ain't Markup Language (tm)";
      homepage = "https://github.com/ingydotnet/yaml-pm";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  YAMLSyck = buildPerlPackage {
    pname = "YAML-Syck";
    version = "1.34";
    src = fetchurl {
      url = "mirror://cpan/authors/id/T/TO/TODDR/YAML-Syck-1.34.tar.gz";
      hash = "sha256-zJFWzK69p5jr/i8xthnoBld/hg7RcEJi8X/608bjQVk=";
    };
    meta = {
      description = "Fast, lightweight YAML loader and dumper";
      homepage = "https://github.com/toddr/YAML-Syck";
      license = with lib.licenses; [ mit ];
    };
  };

  YAMLTiny = buildPerlPackage {
    pname = "YAML-Tiny";
    version = "1.74";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETHER/YAML-Tiny-1.74.tar.gz";
      hash = "sha256-ezjKn1084kIwpri9wfR/Wy2zSOf3+WZsJvWVVjbjPWw=";
    };
    meta = {
      description = "Read/Write YAML files with as little code as possible";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };

  YAMLLibYAML = buildPerlPackage {
    pname = "YAML-LibYAML";
    version = "0.89";
    src = fetchurl {
      url = "mirror://cpan/authors/id/T/TI/TINITA/YAML-LibYAML-0.89.tar.gz";
      hash = "sha256-FVq4NnU0XFCt0DMRrPndkVlVcH+Qmiq9ixfXeShZsuw=";
    };
    meta = {
      description = "Perl YAML Serialization using XS and libyaml";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };
  };
  Exporter = null; # part of Perl 5.22
  Test = null; # part of Perl 5.22
  base = null; # part of Perl 5.26
  Socket = null; # part of Perl 5.28
  version = self.Version;
}
