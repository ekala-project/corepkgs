{
  lib,
  stdenv,
  fetchurl,
  ed,
  autoreconfHook,
  gnupatch,
  runCommand,
  testers,
}:

stdenv.mkDerivation rec {
  pname = "patch";
  version = "2.8";

  src = fetchurl {
    url = "mirror://gnu/patch/patch-${version}.tar.xz";
    hash = "sha256-+Hzuae7CtPy/YKOWsDCtaqNBXxkqpffuhMrV4R9/WuM=";
  };

  # This test is filesystem-dependent - observed failing on ZFS
  postPatch = lib.optionalString stdenv.hostPlatform.isFreeBSD ''
    sed -E -i -e '/bad-filenames/d' tests/Makefile.am
  '';

  nativeBuildInputs = [ autoreconfHook ];

  configureFlags = lib.optionals (stdenv.hostPlatform != stdenv.buildPlatform) [
    "ac_cv_func_strnlen_working=yes"
  ];

  doCheck = stdenv.hostPlatform.libc != "musl"; # not cross;
  nativeCheckInputs = [ ed ];

  passthru.tests = {
    version = testers.testVersion {
      package = gnupatch;
      command = "patch --version";
    };
    simple = runCommand "gnupatch-test" { } ''
      echo "hello" > file.txt
      echo "--- file.txt
      +++ file.txt
      @@ -1 +1 @@
      -hello
      +world" > patch.diff
      ${gnupatch}/bin/patch file.txt patch.diff
      test "$(cat file.txt)" = "world"
      touch $out
    '';
  };

  meta = {
    description = "GNU Patch, a program to apply differences to files";
    mainProgram = "patch";
    longDescription = ''
      GNU Patch takes a patch file containing a difference listing
      produced by the diff program and applies those differences to one or
      more original files, producing patched versions.
    '';
    homepage = "https://savannah.gnu.org/projects/patch";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.all;
  };
}
