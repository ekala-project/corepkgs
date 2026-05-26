{
  version,
  src-hash,
  upstreamPatches,
  packageAtLeast,
  packageOlder,
  ...
}@variantArgs:

{
  lib,
  stdenv,
  fetchpatch,
  fetchurl,
  updateAutotoolsGnuConfigScriptsHook,
  ncurses,
  termcap,
  curses-library ? if stdenv.hostPlatform.isWindows then termcap else ncurses,
}:

let
  branch = lib.versions.majorMinor version;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "readline";
  version = "${version}p${toString (builtins.length finalAttrs.upstreamPatches)}";

  src = fetchurl {
    url = "mirror://gnu/readline/readline-${branch}.tar.gz";
    hash = src-hash;
  };

  outputs = [
    "out"
    "dev"
    "man"
    "doc"
    "info"
  ];

  strictDeps = true;
  propagatedBuildInputs = [ curses-library ];
  nativeBuildInputs = lib.optionals (packageAtLeast "8.3") [
    updateAutotoolsGnuConfigScriptsHook
  ];

  patchFlags = [ "-p0" ];

  upstreamPatches = (
    let
      patch =
        nr: sha256:
        fetchurl {
          url = "mirror://gnu/readline/readline-${branch}-patches/readline${
            lib.replaceStrings [ "." ] [ "" ] branch
          }-${nr}";
          inherit sha256;
        };
    in
    upstreamPatches patch
  );

  patches =
    lib.optionals (curses-library.pname == "ncurses") [
      ./patches/link-against-ncurses.patch
    ]
    ++ lib.optionals (packageOlder "8.0") [
      ./patches/no-arch_only-6.3.patch
    ]
    ++ lib.optionals (packageAtLeast "8.0") [
      ./patches/no-arch_only-8.2.patch
    ]
    ++ finalAttrs.upstreamPatches
    ++ lib.optionals (packageAtLeast "8.0" && stdenv.hostPlatform.isWindows) [
      (fetchpatch {
        name = "0001-sigwinch.patch";
        url = "https://github.com/msys2/MINGW-packages/raw/90e7536e3b9c3af55c336d929cfcc32468b2f135/mingw-w64-readline/0001-sigwinch.patch";
        stripLen = 1;
        hash = "sha256-sFK6EJrSNl0KLWqFv5zBXaQRuiQoYIZVoZfa8BZqfKA=";
      })
      (fetchpatch {
        name = "0002-event-hook.patch";
        url = "https://github.com/msys2/MINGW-packages/raw/3476319d2751a676b911f3de9e1ec675081c03b8/mingw-w64-readline/0002-event-hook.patch";
        stripLen = 1;
        hash = "sha256-F8ytYuIjBtH83ZCJdf622qjwSw+wZEVyu53E/mPsoAo=";
      })
      (fetchpatch {
        name = "0003-fd_set.patch";
        url = "https://github.com/msys2/MINGW-packages/raw/35830ab27e5ed35c2a8d486961ab607109f5af50/mingw-w64-readline/0003-fd_set.patch";
        stripLen = 1;
        hash = "sha256-UiaXZRPjKecpSaflBMCphI2kqOlcz1JkymlCrtpMng4=";
      })
      (fetchpatch {
        name = "0004-locale.patch";
        url = "https://github.com/msys2/MINGW-packages/raw/f768c4b74708bb397a77e3374cc1e9e6ef647f20/mingw-w64-readline/0004-locale.patch";
        stripLen = 1;
        hash = "sha256-dk4343KP4EWXdRRCs8GRQlBgJFgu1rd79RfjwFD/nJc=";
      })
    ];

  meta = {
    description = "Library for interactive line editing";
    longDescription = ''
      The GNU Readline library provides a set of functions for use by
      applications that allow users to edit command lines as they are
      typed in.  Both Emacs and vi editing modes are available.  The
      Readline library includes additional functions to maintain a
      list of previously-entered command lines, to recall and perhaps
      reedit those lines, and perform csh-like history expansion on
      previous commands.

      The history facilities are also placed into a separate library,
      the History library, as part of the build process.  The History
      library may be used without Readline in applications which
      desire its capabilities.
    '';
    homepage = "https://savannah.gnu.org/projects/readline/";
    license = lib.licenses.gpl3Plus;
    platforms =
      lib.platforms.unix ++ lib.optionals (packageAtLeast "8.0") lib.platforms.windows;
    inherit branch;
  };
}
// lib.optionalAttrs (packageAtLeast "8.0") {
  # Make mingw-w64 provide a dummy alarm() function
  #
  # Method borrowed from
  # https://github.com/msys2/MINGW-packages/commit/35830ab27e5ed35c2a8d486961ab607109f5af50
  CFLAGS = lib.optionalString stdenv.hostPlatform.isMinGW "-D__USE_MINGW_ALARM -D_POSIX";

  # This install error is caused by a very old libtool. We can't autoreconfHook this package,
  # so this is the best we've got!
  postInstall = lib.optionalString stdenv.hostPlatform.isOpenBSD ''
    ln -s $out/lib/libhistory.so* $out/lib/libhistory.so
    ln -s $out/lib/libreadline.so* $out/lib/libreadline.so
  '';
})
