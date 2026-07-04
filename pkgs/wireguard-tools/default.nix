{
  lib,
  stdenv,
  fetchzip,
  iptables,
  iproute2,
  makeWrapper,
  openresolv ? null,
  procps,
  bash,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "wireguard-tools";
  version = "1.0.20260223";

  src = fetchzip {
    url = "https://git.zx2c4.com/wireguard-tools/snapshot/wireguard-tools-${finalAttrs.version}.tar.xz";
    sha256 = "sha256-jOFEE9CcCjU52nPO/+ib72rqki7H1qkIinv7Z8yWQBA=";
  };

  outputs = [
    "out"
    "man"
  ];

  sourceRoot = "${finalAttrs.src.name}/src";

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ bash ];

  makeFlags = [
    "DESTDIR=$(out)"
    "PREFIX=/"
    "WITH_BASHCOMPLETION=yes"
    "WITH_SYSTEMDUNITS=yes"
    "WITH_WGQUICK=yes"
  ];

  postFixup =
    ''
      substituteInPlace $out/lib/systemd/system/wg-quick@.service \
        --replace /usr/bin $out/bin
    ''
    + lib.optionalString stdenv.hostPlatform.isLinux ''
      for f in $out/bin/*; do
        wrapProgram $f \
          --prefix PATH : ${
            lib.makeBinPath [
              procps
              iproute2
            ]
          } \
          --suffix PATH : ${
            lib.makeBinPath (
              [ iptables ]
              ++ lib.optional (openresolv != null) openresolv
            )
          }
      done
    '';

  meta = {
    description = "Tools for the WireGuard secure network tunnel";
    homepage = "https://www.wireguard.com/";
    license = lib.licenses.gpl2Only;
    mainProgram = "wg";
    platforms = lib.platforms.unix;
    maintainers = [ ];
  };
})
