# npins — simple and convenient dependency pinning for Nix
{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  makeWrapper,
  installShellFiles,
  testers,
  nix-update-script,

  # runtime dependencies — npins shells out to all of these
  nix,
  nix-prefetch-git,
  nix-prefetch-docker,
  skopeo,
  git, # for `git ls-remote`
}:

let
  runtimePath = lib.makeBinPath [
    nix
    nix-prefetch-git
    nix-prefetch-docker
    skopeo
    git
  ];
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "npins";
  version = "0.5.1";

  src = fetchFromGitHub {
    owner = "andir";
    repo = "npins";
    tag = finalAttrs.version;
    hash = "sha256-PRdGQlxpv8qXdQ6KwlP2Ky2HBHDY83lGTSiD6yljUxE=";
  };

  cargoHash = "sha256-N0Hurb/cmXCDS7EZlYCct9WPbUMXvU+0TK1cBY6+mYc=";

  cargoBuildFlags = [
    "-p"
    "npins"
    "-p"
    "npins-completions"
  ];

  nativeBuildInputs = [
    makeWrapper
    installShellFiles
  ];

  # NOTE: openssh is deliberately absent from runtimePath. npins sets
  # GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=yes", which git resolves
  # through the shell and therefore through PATH, so ssh:// pins work anywhere
  # openssh is provided by the caller's environment (any standard system) and
  # fail loudly with "ssh: command not found" where it is not. Add openssh to
  # runtimePath only if hermetic ssh support becomes a requirement.
  postFixup =
    lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
      installShellCompletion --cmd npins \
        --bash <($out/bin/npins-completions bash) \
        --fish <(cat <($out/bin/npins-completions fish) $src/completions/pin-completions.fish) \
        --zsh <($out/bin/npins-completions zsh)
    ''
    + ''
      # Generated above, but a build-time tool rather than a shipped binary —
      # removed unconditionally so it does not survive into cross builds.
      rm -f $out/bin/npins-completions

      wrapProgram $out/bin/npins --prefix PATH : "${runtimePath}"
    '';

  passthru.tests.version = testers.testVersion { package = finalAttrs.finalPackage; };
  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Simple and convenient dependency pinning for Nix";
    mainProgram = "npins";
    homepage = "https://github.com/andir/npins";
    license = lib.licenses.eupl12;
  };
})
