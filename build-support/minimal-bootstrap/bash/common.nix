{ lib }:
{
  meta = {
    description = "GNU Bourne-Again Shell, the de facto standard shell on Linux";
    homepage = "https://www.gnu.org/software/bash";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.unix;
    mainProgram = "bash";
  };
}
