{
  stdenv,
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  runCommand,
  runtimeShell,
  versionCheckHook,
  writableTmpDirAsHomeHook,
  installShellFiles,
}:

let
  package = buildGoModule rec {
    pname = "opentofu";
    version = "1.11.5";

    src = fetchFromGitHub {
      owner = "opentofu";
      repo = "opentofu";
      tag = "v${version}";
      hash = "sha256-XosT6Ccnp2qqrJyqeFawLx7ckpGAOhiMNLiw5LTLxg0=";
    };

    vendorHash = "sha256-WO5OtKwluks5nuSHJ4NO1+EKhtCrJE9MuMGmu5fYKM4=";
    ldflags = [
      "-s"
      "-w"
      "-X"
      "github.com/opentofu/opentofu/version.dev=no"
    ];

    postPatch = ''
      substituteInPlace go.mod --replace-fail 'go 1.25.6' 'go 1.25.4'
    '';

    nativeBuildInputs = [ installShellFiles ];
    patches = [ ./provider-path-0_15.patch ];

    # https://github.com/posener/complete/blob/9a4745ac49b29530e07dc2581745a218b646b7a3/cmd/install/bash.go#L8
    postInstall = ''
      installShellCompletion --bash --name tofu <(echo complete -C tofu tofu)
    '';

    __darwinAllowLocalNetworking = true;

    nativeCheckInputs = [
      writableTmpDirAsHomeHook
      versionCheckHook
    ];

    doInstallCheck = true;
    versionCheckProgramArg = "version";

    preCheck = ''
      export TF_SKIP_REMOTE_TESTS=1
    '';

    subPackages = [ "./cmd/..." ];

    meta = {
      description = "Tool for building, changing, and versioning infrastructure";
      homepage = "https://opentofu.org/";
      changelog = "https://github.com/opentofu/opentofu/blob/v${version}/CHANGELOG.md";
      license = lib.licenses.mpl20;
      maintainers = [ ];
      mainProgram = "tofu";
    };
  };
in
package
