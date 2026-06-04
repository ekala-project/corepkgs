{ lib }:

{
  meta = {
    description = "GNU implementation of the Awk programming language";
    homepage = "https://www.gnu.org/software/gawk";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.unix;
  };
}
