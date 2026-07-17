{
  lib,
  stdenv,
  fetchurl,
  ncurses,
  pcre2,
  versionCheckHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "less";
  version = "692";

  src = fetchurl {
    url = "https://www.greenwoodsoftware.com/less/less-${finalAttrs.version}.tar.gz";
    hash = "sha256-YTAPYDeY7PHXeGVweJ8P8/WhrPB1pvufdWg30WbjfRQ=";
  };

  buildInputs = [
    ncurses
    pcre2
  ];

  outputs = [
    "out"
    "man"
  ];

  configureFlags = [
    "--sysconfdir=/etc"
    (lib.withFeatureAs true "regex" "pcre2")
  ];

  strictDeps = true;

  nativeInstallCheckInputs = [
    versionCheckHook
  ];
  doInstallCheck = true;

  meta = {
    homepage = "https://www.greenwoodsoftware.com/less/";
    description = "More advanced file pager than 'more'";
    license = lib.licenses.gpl3Plus;
    mainProgram = "less";
    platforms = lib.platforms.unix;
    maintainers = [ ];
  };
})
