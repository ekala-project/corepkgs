{ lib }:
{
  meta = {
    description = "The GNU Core Utilities";
    homepage = "https://www.gnu.org/software/coreutils";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.unix;
  };
}
