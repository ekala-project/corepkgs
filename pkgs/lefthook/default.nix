{
  lib,
  stdenv,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  nix-update-script,
  testers,
}:

buildGoModule (finalAttrs: {
  pname = "lefthook";
  version = "2.2.2";

  src = fetchFromGitHub {
    owner = "evilmartians";
    repo = "lefthook";
    tag = "v${finalAttrs.version}";
    hash = "sha256-8Gl+Q1xU3nPYWfPI9o+o5b29tZ5ca3eb0YeApnaQ2LI=";
  };

  vendorHash = "sha256-EbyzNWEEE85MawYQZUyHPvQJ13DcaCSXYv4JFC+GSac=";

  # The repository has a second main package at gen/, which builds a JSON
  # schema generator. Without this, the module builder discovers both and
  # ships $out/bin/gen alongside the real binary.
  subPackages = [ "." ];

  ldflags = [
    "-s"
    "-w"
  ];

  nativeBuildInputs = [ installShellFiles ];

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd lefthook \
      --bash <($out/bin/lefthook completion bash) \
      --fish <($out/bin/lefthook completion fish) \
      --zsh <($out/bin/lefthook completion zsh)
  '';

  passthru.tests.version = testers.testVersion {
    package = finalAttrs.finalPackage;
  };

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Fast and powerful Git hooks manager for any type of projects";
    homepage = "https://github.com/evilmartians/lefthook";
    changelog = "https://github.com/evilmartians/lefthook/raw/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "lefthook";
    platforms = lib.platforms.all;
  };
})
