{
  lib,
  mkEkaPackage,
  fetchurl,
  interactive ? false,
  gawk,
  runCommand,
  testers,

  /*
    Test suite broke on:
        stdenv.hostPlatform.isCygwin # XXX: `test-dup2' segfaults on Cygwin 6.1
     || stdenv.hostPlatform.isDarwin # XXX: `locale' segfaults
     || stdenv.hostPlatform.isSunOS  # XXX: `_backsmalls1' fails, locale stuff?
     || stdenv.hostPlatform.isFreeBSD
  */
  doCheck ? (interactive && mkEkaPackage.stdenv.hostPlatform.isLinux),
  glibcLocales ? null,
  locale ? null,
}:

let
  stdenv = mkEkaPackage.stdenv;
in

assert (doCheck && stdenv.hostPlatform.isLinux) -> glibcLocales != null;

mkEkaPackage rec {
  pname = "gawk" + lib.optionalString interactive "-interactive";
  version = "5.3.2";

  src = fetchurl {
    url = "mirror://gnu/gawk/gawk-${version}.tar.xz";
    hash = "sha256-+MNIZQnecFGSE4sA7ywAu73Q6Eww1cB9I/xzqdxMycw=";
  };

  # When we do build separate interactive version, it makes sense to always include man.
  outputs = [
    "out"
    "info"
  ]
  ++ lib.optional (!interactive) "man";

  strictDeps = true;

  # no-pma fix
  commands =
    scope:
    {
      inherit (scope) autoreconfHook texinfo;
    }
    // lib.optionalAttrs interactive {
      inherit (scope) removeReferencesTo;
    }
    // lib.optionalAttrs (doCheck && stdenv.hostPlatform.isLinux) {
      inherit glibcLocales;
    };

  libraries =
    scope:
    lib.optionalAttrs interactive {
      inherit (scope) runtimeShellPackage readline;
    }
    // lib.optionalAttrs stdenv.hostPlatform.isDarwin {
      inherit locale;
    };

  configureFlags = [
    (
      if interactive then
        "--with-readline=${(mkEkaPackage.scopes.hostTarget.readline or null).dev or ""}"
      else
        "--without-readline"
    )
  ];

  env = lib.optionalAttrs stdenv.hostPlatform.isDarwin {
    # TODO: figure out a better way to unbreak _NSGetExecutablePath invocations
    NIX_CFLAGS_COMPILE = "-Wno-implicit-function-declaration";
  };

  makeFlags = [
    "AR=${stdenv.cc.targetPrefix}ar"
  ];

  inherit doCheck;

  passthru.tests = {
    version = testers.testVersion {
      package = gawk;
      command = "gawk --version";
    };
    simple = runCommand "gawk-test" { } ''
      result=$(echo "hello world" | ${gawk}/bin/gawk '{ print $2 }')
      test "$result" = "world"
      touch $out
    '';
  };

  postInstall =
    (
      if interactive then
        ''
          remove-references-to -t "$NIX_CC" "$out"/bin/gawkbug
          patchShebangs --host "$out"/bin/gawkbug
        ''
      else
        ''
          rm "$out"/bin/gawkbug
        ''
    )
    + ''
      rm "$out"/bin/gawk-*
      ln -s gawk.1 "''${!outputMan}"/share/man/man1/awk.1
    '';

  meta = {
    homepage = "https://www.gnu.org/software/gawk/";
    description = "GNU implementation of the Awk programming language";
    longDescription = ''
      Many computer users need to manipulate text files: extract and then
      operate on data from parts of certain lines while discarding the rest,
      make changes in various text files wherever certain patterns appear,
      and so on.  To write a program to do these things in a language such as
      C or Pascal is a time-consuming inconvenience that may take many lines
      of code.  The job is easy with awk, especially the GNU implementation:
      Gawk.

      The awk utility interprets a special-purpose programming language that
      makes it possible to handle many data-reformatting jobs with just a few
      lines of code.
    '';
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.unix ++ lib.platforms.windows;
    mainProgram = "gawk";
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "gnu" version;
  };
}
