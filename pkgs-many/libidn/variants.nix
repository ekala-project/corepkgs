{
  v1_44 = rec {
    version = "1.44";
    src-url = "mirror://gnu/libidn/libidn-${version}.tar.gz";
    src-hash = "sha256-SZYIurOmVlCg6lKIjBOo3uvj9xQI4xms2exS4C6xOVk=";
  };

  v2 = rec {
    version = "2.3.8";
    src-url = "https://ftp.gnu.org/gnu/libidn/libidn2-${version}.tar.gz";
    src-hash = "sha256-9VeRG/YXFiHh9y/zX1sYJbs1tS7UUyXc3ukx5dPAeHo=";
  };
}
