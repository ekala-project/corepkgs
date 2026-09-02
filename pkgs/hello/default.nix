{
  lib,
  stdenv,
  fetchzip,
  versionCheckHook,
  gettext,
  runUnitTests,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "hello";
  version = "2.12.3";

  # __structuredAttrs and strictDeps are true by default in corepkgs

  src = fetchzip {
    url = "mirror://gnu/hello/hello-${finalAttrs.version}.tar.gz";
    hash = "sha256-ao/kj5UbJ+X0Deywrc5EYkktEy7b3tnfK4IxrLI8eEI=";
  };

  # The GNU Hello `configure` script detects how to link libiconv but fails to actually make use of that.
  # Unfortunately, this cannot be a patch to `Makefile.am` because `autoreconfHook` causes a gettext
  # infrastructure mismatch error when trying to build `hello`.
  env = lib.optionalAttrs stdenv.hostPlatform.isDarwin {
    NIX_LDFLAGS = "-liconv";
  };

  buildInputs = lib.optionals stdenv.hostPlatform.isFreeBSD [
    gettext
  ];

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    versionCheckHook
  ];

  passthru.tests.unittests = runUnitTests finalAttrs.finalPackage;

  meta = {
    description = "Program that produces a familiar, friendly greeting";
    longDescription = ''
      GNU Hello is a program that prints "Hello, world!" when you run it.
      It is fully customizable.
    '';
    homepage = "https://www.gnu.org/software/hello/manual/";
    changelog = "https://git.savannah.gnu.org/cgit/hello.git/plain/NEWS?h=v${finalAttrs.version}";
    license = lib.licenses.gpl3Plus;
    mainProgram = "hello";
    platforms = lib.platforms.all;
    identifiers.cpeParts.vendor = "gnu";
  };
})
