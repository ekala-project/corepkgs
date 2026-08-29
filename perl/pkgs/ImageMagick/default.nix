{
  buildPerlPackage,
  imagemagick,
  lib,
  version,
}:

buildPerlPackage rec {
  pname = "Image-Magick";
  inherit (imagemagick) version src;
  sourceRoot = "${src.name}/PerlMagick";
  buildInputs = [ imagemagick ];
  preConfigure = ''
    pushd ..
    chmod -R +rwX .
    ./configure --with-perl
    make perl-quantum-sources
    popd
  '';
  meta = {
    homepage = "https://metacpan.org/dist/Image-Magick";
    description = "Objected-oriented Perl interface to ImageMagick. Use it to read, manipulate, or write an image or image sequence from within a Perl script";
    license = with lib.licenses; [ imagemagick ];
  };
}
