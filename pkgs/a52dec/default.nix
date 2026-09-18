{
  lib,
  stdenv,
  fetchFromGitLab,
  autoreconfHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "a52dec";
  version = "0.8.0";

  src = fetchFromGitLab {
    domain = "git.adelielinux.org";
    owner = "community";
    repo = "a52dec";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Z4riiwetJkhQYa+AD8qOiwB1+cuLbOyN/g7D8HM8Pkw=";
  };

  nativeBuildInputs = [ autoreconfHook ];

  configureFlags = [
    "--enable-shared"
    "ac_cv_c_inline=yes"
    "CFLAGS=-std=gnu17"
  ];

  makeFlags = [ "AR=${stdenv.cc.targetPrefix}ar" ];

  doCheck = !stdenv.hostPlatform.isi686;

  meta = {
    description = "ATSC A/52 stream decoder";
    homepage = "https://liba52.sourceforge.io/";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.unix;
  };
})
