{
  lib,
  buildPerlPackage,
  fetchurl,
}:

buildPerlPackage {
  pname = "Image-ExifTool";
  version = "13.55";

  src = fetchurl {
    url = "mirror://cpan/authors/id/E/EX/EXIFTOOL/Image-ExifTool-13.55.tar.gz";
    hash = "sha256-X0yB00rUBlOMKHGtctv8612bQSsvFsu+tNcS0nCEZmc=";
  };

  meta = {
    description = "Read and write meta information in files";
    homepage = "https://exiftool.org/";
    license = with lib.licenses; [
      artistic1
      gpl1Plus
    ];
  };
}
