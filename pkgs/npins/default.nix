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
  # Spawned directly by npins itself, so required on every invocation
  # (nix-prefetch-url libnpins/src/nix.rs:20, nix-instantiate :264). Also
  # supplies the nix-hash/nix-store that nix-prefetch-git's own wrapper omits
  # when --hash is passed without --builder (corepkgs#211). Only that second
  # half goes away if #211 is fixed; the direct calls do not.
  nix,
  # Spawned directly for container pins (libnpins/src/nix.rs:204). nixpkgs'
  # expression omits it and is latently broken for `npins add container`.
  skopeo,
  nix-prefetch-git,
  nix-prefetch-docker,
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

  # npins-completions is a build-time helper, not a shipped binary: it is only
  # useful on a host that can execute the npins it just built, so it is neither
  # built nor invoked when cross-compiling.
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

  # Generating completions and discarding the helper that generates them are
  # one guarded unit, so the removal cannot drift ahead of the use.
  postInstall = lib.optionalString canRunCompletions ''
    installShellCompletion --cmd npins \
      --bash <($out/bin/npins-completions bash) \
      --fish <(cat <($out/bin/npins-completions fish) $src/completions/pin-completions.fish) \
      --zsh <($out/bin/npins-completions zsh)

    rm -f $out/bin/npins-completions
  '';

  # NOTE: openssh is deliberately absent from runtimePath. npins sets
  # GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=yes", which git resolves
  # through the shell and therefore through PATH, so ssh:// pins work anywhere
  # openssh is provided by the caller's environment (any standard system) and
  # fail loudly with "ssh: command not found" where it is not. Add openssh to
  # runtimePath only if hermetic ssh support becomes a requirement.
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
