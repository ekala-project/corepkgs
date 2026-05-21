{
  version,
  hash,
  mkVariantPassthru,
  packageBetween,
  ...
}@variantArgs:

{
  lib,
  stdenv,
  fetchurl,
  openssl,
  fetchpatch,
  lksctp-tools ? null,
}:

let
  isVersion2 = packageBetween "2" "3";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "iperf";
  inherit version;

  src = fetchurl (
    if isVersion2 then
      {
        url = "mirror://sourceforge/iperf2/files/iperf-${finalAttrs.version}.tar.gz";
        inherit hash;
      }
    else
      {
        url = "https://downloads.es.net/pub/iperf/iperf-${finalAttrs.version}.tar.gz";
        inherit hash;
      }
  );

  buildInputs = lib.optionals (!isVersion2) (
    [ openssl ] ++ lib.optionals stdenv.hostPlatform.isLinux [ lksctp-tools ]
  );

  configureFlags =
    if isVersion2 then [ "--enable-fastsampling" ] else [ "--with-openssl=${openssl.dev}" ];

  outputs =
    if isVersion2 then
      [ "out" ]
    else
      [
        "out"
        "dev"
        "lib"
        "man"
      ];

  patches =
    if isVersion2 then
      [ ]
    else
      lib.optionals stdenv.hostPlatform.isMusl [
        (fetchpatch {
          url = "https://git.alpinelinux.org/aports/plain/main/iperf3/remove-pg-flags.patch?id=7f979fc51ae31d5c695d8481ba84a4afc5080efb";
          name = "remove-pg-flags.patch";
          sha256 = "0z3zsmf7ln08rg1mmzl8s8jm5gp8x62f5cxiqcmi8dcs2nsxwgbi";
        })
      ];

  postInstall =
    if isVersion2 then
      ''
        mv $out/bin/iperf $out/bin/iperf2
        ln -s $out/bin/iperf2 $out/bin/iperf
      ''
    else
      ''
        ln -s $out/bin/iperf3 $out/bin/iperf
        ln -s $man/share/man/man1/iperf3.1 $man/share/man/man1/iperf.1
      '';

  passthru = mkVariantPassthru variantArgs;

  meta = {
    homepage =
      if isVersion2 then "https://sourceforge.net/projects/iperf/" else "https://software.es.net/iperf/";
    description = "Tool to measure IP bandwidth using UDP or TCP";
    platforms = lib.platforms.unix;
    license = if isVersion2 then lib.licenses.mit else lib.licenses.bsd3;
    mainProgram = if isVersion2 then "iperf2" else "iperf3";
    # prioritize iperf3
    priority = if isVersion2 then 10 else null;
  };
})
