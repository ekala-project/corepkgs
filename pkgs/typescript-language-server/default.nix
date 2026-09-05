# typescript-language-server — LSP server for TypeScript/JavaScript
#
# Zero runtime npm dependencies — installed directly from the registry tarball.
{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  nodejs,
  typescript-go,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "typescript-language-server";
  version = "6.0.0";

  src = fetchurl {
    url = "https://registry.npmjs.org/typescript-language-server/-/typescript-language-server-${finalAttrs.version}.tgz";
    hash = "sha512-LXtzY3UZGfghWA5eRU6/T5j1+YiGRgy14mR3GOKyTKlE1op1TYKQnLVxwBsmnXeDhGLuvzZyIHBAqvrekAITYQ==";
  };

  sourceRoot = "package";

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/typescript-language-server $out/bin
    cp -r . $out/lib/typescript-language-server/

    makeWrapper ${nodejs}/bin/node $out/bin/typescript-language-server \
      --add-flags "$out/lib/typescript-language-server/lib/cli.mjs" \
      --prefix PATH : ${lib.makeBinPath [ typescript-go ]}

    runHook postInstall
  '';

  meta = {
    description = "TypeScript & JavaScript Language Server (LSP)";
    homepage = "https://github.com/typescript-language-server/typescript-language-server";
    license = lib.licenses.asl20;
    mainProgram = "typescript-language-server";
  };
})
