{
  php,
  stdenv,
  lib,
  autoreconfHook,
  pkg-config,
}:

{
  pname,
  version,
  src,
  buildInputs ? [ ],
  nativeBuildInputs ? [ ],
  configureFlags ? [ ],
  makeFlags ? [ ],
  ...
}@args:

stdenv.mkDerivation (
  args
  // {
    pname = "php-${pname}";
    inherit version src;

    nativeBuildInputs = [
      php
      autoreconfHook
      pkg-config
    ]
    ++ nativeBuildInputs;

    buildInputs = [ php ] ++ buildInputs;

    configureFlags = [ "--with-php-config=${php}/bin/php-config" ] ++ configureFlags;

    inherit makeFlags;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/php/extensions
      cp modules/*.so $out/lib/php/extensions/

      runHook postInstall
    '';

    meta = args.meta or { } // {
      platforms = php.meta.platforms;
    };
  }
)
