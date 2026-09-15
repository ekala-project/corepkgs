{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
}:

let
  version = "0.115.1";

  sources = {
    "x86_64-linux" = fetchurl {
      url = "https://github.com/nushell/nushell/releases/download/${version}/nu-${version}-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-ipciF33dQh66kntLquSuNBpNHDQ0UEvnsbF9mYuv3Yc=";
    };
    "aarch64-linux" = fetchurl {
      url = "https://github.com/nushell/nushell/releases/download/${version}/nu-${version}-aarch64-unknown-linux-musl.tar.gz";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
    };
  };
in
stdenvNoCC.mkDerivation {
  pname = "nushell";
  inherit version;

  src =
    sources.${stdenvNoCC.hostPlatform.system}
      or (throw "nushell: unsupported system ${stdenvNoCC.hostPlatform.system}");

  dontFixup = true;

  installPhase = ''
    install -Dm755 nu $out/bin/nu
  '';

  meta = {
    description = "Modern shell written in Rust";
    homepage = "https://www.nushell.sh/";
    license = lib.licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
}
