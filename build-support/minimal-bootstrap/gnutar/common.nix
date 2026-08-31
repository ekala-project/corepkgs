{ lib }:
{
  meta = {
    description = "GNU implementation of the `tar' archiver";
    homepage = "https://www.gnu.org/software/tar";
    license = lib.licenses.gpl3Plus;
    mainProgram = "tar";
    platforms = lib.platforms.unix;
  };
}
