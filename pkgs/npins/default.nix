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
  nix, # direct calls (nix.rs:20,:264) and nix-prefetch-git's nix-hash (corepkgs#211)
  nix-prefetch-git,
  nix-prefetch-docker,
  skopeo, # container pins; absent upstream, leaving `npins add container` broken
  git, # for `git ls-remote`
}:

let
  # openssh deliberately absent: npins sets GIT_SSH_COMMAND, so git resolves
  # `ssh` via PATH and callers supply it.
  runtimePath = lib.makeBinPath [
    nix
    nix-prefetch-git
    nix-prefetch-docker
    skopeo
    git
  ];

  # npins-completions only runs on a host that can execute what it just built.
  canRunCompletions = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
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
  ]
  ++ lib.optionals canRunCompletions [
    "-p"
    "npins-completions"
  ];

  nativeBuildInputs = [
    makeWrapper
    installShellFiles
  ];

  # built and removed together so the removal cannot drift ahead of the use
  postInstall = lib.optionalString canRunCompletions ''
    installShellCompletion --cmd npins \
      --bash <($out/bin/npins-completions bash) \
      --fish <(cat <($out/bin/npins-completions fish) $src/completions/pin-completions.fish) \
      --zsh <($out/bin/npins-completions zsh)

    rm -f $out/bin/npins-completions
  '';

  postFixup = ''
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
