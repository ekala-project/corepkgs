{ lib }:

{
  pname = "musl";

  meta = {
    description = "Efficient, small, quality libc implementation";
    homepage = "https://musl.libc.org";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
