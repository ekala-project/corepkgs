# nix-build -A tests.testers.pkg-config-testLink
{
  lib,
  testers,
  zlib,
  openssl,
  writeText,
}:

lib.recurseIntoAttrs {

  # Basic test: zlib should compile+link via pkg-config
  zlib-links = testers.pkg-config.testLink {
    package = zlib;
    modules = [ "zlib" ];
  };

  # Test with user-provided example source that calls a real symbol
  zlib-links-example = testers.pkg-config.testLink {
    package = zlib;
    modules = [ "zlib" ];
    example = writeText "zlib-test.c" ''
      #include <zlib.h>
      int main(void) {
        zlibVersion();
        return 0;
      }
    '';
  };

  # Test with multiple modules from a single package
  openssl-links = testers.pkg-config.testLink {
    package = openssl;
    modules = [ "openssl" ];
  };

}
