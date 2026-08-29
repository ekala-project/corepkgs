{
  lib,
  stdenv,
  perl,
  toPerlModule,
}:

{
  buildInputs ? [ ],
  nativeBuildInputs ? [ ],
  outputs ? [
    "out"
    "devdoc"
  ],
  src ? null,

  doCheck ? false, # TODO(corepkgs): enable in passthru
  checkTarget ? "test",

  # Prevent CPAN downloads.
  PERL_AUTOINSTALL ? "--skipdeps",

  # From http://wiki.cpantesters.org/wiki/CPANAuthorNotes: "allows
  # authors to skip certain tests (or include certain tests) when
  # the results are not being monitored by a human being."
  AUTOMATED_TESTING ? "1",

  # current directory (".") is removed from @INC in Perl 5.26 but many old libs rely on it
  # https://metacpan.org/pod/release/XSAWYERX/perl-5.26.0/pod/perldelta.pod#Removal-of-the-current-directory-%28%22.%22%29-from-@INC
  PERL_USE_UNSAFE_INC ? "1",

  # Skip tests that need the network; the build sandbox has none.
  NO_NETWORK_TESTING ? "1",

  env ? { },

  postPatch ? "patchShebangs .",

  ...
}@attrs:

# TODO(corepkgs): support finalAttrs and dont hardcode version in urls
(
  let
    fromCpan = lib.hasPrefix "mirror://cpan/" (attrs.src.url or "");

    defaultMeta = {
      inherit (perl.meta) platforms;
    }
    // lib.optionalAttrs fromCpan {
      homepage = "https://metacpan.org/dist/${attrs.pname}";
      license = with lib.licenses; [
        artistic1
        gpl1Plus
      ];
    };

    package = stdenv.mkDerivation (
      attrs
      // {
        name = "perl${perl.version}-${attrs.pname}-${attrs.version}";

        builder = ./builder.sh;

        buildInputs = buildInputs ++ [ perl ];
        nativeBuildInputs =
          nativeBuildInputs
          ++ (if !(stdenv.buildPlatform.canExecute stdenv.hostPlatform) then [ perl.mini ] else [ perl ]);

        # enabling or disabling does nothing for perl packages
        enableParallelBuilding = true;

        inherit
          outputs
          src
          doCheck
          checkTarget
          postPatch
          ;

        env = {
          inherit
            PERL_AUTOINSTALL
            AUTOMATED_TESTING
            PERL_USE_UNSAFE_INC
            NO_NETWORK_TESTING
            ;
          fullperl = perl.__spliced.buildHost or perl;
        }
        // env;

        meta = defaultMeta // (attrs.meta or { });
      }
    );

  in
  toPerlModule package
)
