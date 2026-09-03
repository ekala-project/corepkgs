# erlang-language-platform — IDE-first library for Erlang (pre-built binary)
{
  stdenv,
  lib,
  fetchurl,
  autoPatchelfHook,
  erlang,
}:

let
  arch = if stdenv.hostPlatform.isAarch64 then "aarch64" else "x86_64";
  platform =
    if stdenv.hostPlatform.isDarwin then
      "elp-macos-${arch}-apple-darwin"
    else
      "elp-linux-${arch}-unknown-linux-gnu";
  otp_version = "otp-${lib.versions.major erlang.version}";
  release_major = "${platform}-${otp_version}";

  hashes = builtins.fromJSON (builtins.readFile ./hashes.json);

  release_name =
    let
      hash_names = builtins.attrNames hashes;
      found_name = lib.lists.findFirst (name: lib.strings.hasPrefix release_major name) false hash_names;
    in
    if found_name != false then
      found_name
    else
      throw "erlang-language-platform does not support OTP version ${otp_version}";
in
stdenv.mkDerivation {
  pname = "erlang-language-platform";
  version = "2026-08-10";

  src = fetchurl {
    url = "https://github.com/WhatsApp/erlang-language-platform/releases/download/2026-08-10/${release_name}.tar.gz";
    hash = hashes.${release_name};
  };

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isElf [ autoPatchelfHook ];

  buildInputs = lib.optionals stdenv.hostPlatform.isElf [ (lib.getLib stdenv.cc.cc) ];

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -m755 -D elp $out/bin/elp
    runHook postInstall
  '';

  meta = {
    description = "IDE-first library for the semantic analysis of Erlang code, including LSP server";
    homepage = "https://github.com/WhatsApp/erlang-language-platform/";
    license = with lib.licenses; [ mit asl20 ];
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
      "aarch64-darwin"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
