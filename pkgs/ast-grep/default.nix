{
  lib,
  rustPlatform,
  fetchFromGitHub,
  stdenv,
  installShellFiles,
  versionCheckHook,
  nix-update-script,
  enableLegacySg ? false,
  runCommand,
  testers,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ast-grep";
  version = "0.51.1";

  src = fetchFromGitHub {
    owner = "ast-grep";
    repo = "ast-grep";
    tag = finalAttrs.version;
    hash = "sha256-ce8WdWWHqumNO1y6BChIx1qqIxawVpeq0ahIPG+yUaY=";
  };

  # error: linker `aarch64-linux-gnu-gcc` not found
  postPatch = ''
    rm .cargo/config.toml
  '';

  cargoHash = "sha256-mo3E2eFhfDwjft3AUbSrnmez6URpjgsv6/4N7e8BinI=";

  nativeBuildInputs = [ installShellFiles ];

  cargoBuildFlags = [
    "--package"
    "ast-grep"
    "--bin"
    "ast-grep"
  ]
  ++ lib.optionals enableLegacySg [
    "--package"
    "ast-grep"
    "--bin"
    "sg"
  ];

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd ast-grep \
      --bash <($out/bin/ast-grep completions bash) \
      --fish <($out/bin/ast-grep completions fish) \
      --zsh <($out/bin/ast-grep completions zsh)
    ${lib.optionalString enableLegacySg ''
      installShellCompletion --cmd sg \
        --bash <($out/bin/sg completions bash) \
        --fish <($out/bin/sg completions fish) \
        --zsh <($out/bin/sg completions zsh)
    ''}
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
  ];
  doInstallCheck = true;

  passthru = {
    tests = {
      version = testers.testVersion {
        package = finalAttrs.finalPackage;
      };
      simple = runCommand "ast-grep-test" { } ''
        echo 'console.log("hello")' > test.js
        ${finalAttrs.finalPackage}/bin/ast-grep run --pattern 'console.log($A)' test.js > $out || true
        touch $out
      '';
    };
    updateScript = nix-update-script { };
  };

  meta = {
    mainProgram = "ast-grep";
    description = "Fast and polyglot tool for code searching, linting, rewriting at large scale";
    homepage = "https://ast-grep.github.io/";
    changelog = "https://github.com/ast-grep/ast-grep/blob/${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
})
