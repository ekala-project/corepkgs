{ lib }:
{
  meta = {
    description = "A tool to control the generation of non-source files from sources";
    homepage = "https://www.gnu.org/software/make";
    license = lib.licenses.gpl3Plus;
    mainProgram = "make";
    platforms = lib.platforms.unix;
  };
}
