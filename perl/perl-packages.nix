/*
  This file defines the composition for CPAN (Perl) packages.  It has
  been factored out of top-level.nix because there are so many of
  them.  Also, because most Nix expressions for CPAN packages are
  trivial, most are actually defined here.  I.e. there's no function
  for each package in a separate file: the call to the function would
  be almost as much code as the function itself.
*/

{
  lib,
  perl,
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

  PerlMagick = throw "Use ImageMagick instead";
  version = self.Version;
}
