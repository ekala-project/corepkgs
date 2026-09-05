# opentofu — Infrastructure as code tool (Terraform fork)
{
  lib,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  go,
}:

# OpenTofu's vendored grpc uses http2.TrailerPrefix removed in Go 1.27
(buildGoModule.override { go = go.v1_26; }) rec {
  pname = "opentofu";
  version = "1.12.6";

  src = fetchFromGitHub {
    owner = "opentofu";
    repo = "opentofu";
    tag = "v${version}";
    hash = "sha256-gtbgfjnGrB1J+7smGpFGavP6r/IDrcd5MgI0hS5FzHw=";
  };

  vendorHash = "sha256-70b/19/kquvOwjDeB8+WH6IwB4J0nBTjIw4+rfvqzkI=";

  ldflags = [
    "-s"
    "-w"
    "-X"
    "github.com/opentofu/opentofu/version.dev=no"
  ];

  subPackages = [ "./cmd/..." ];

  nativeBuildInputs = [ installShellFiles ];

  postInstall = ''
    installShellCompletion --bash --name tofu <(echo complete -C tofu tofu)
  '';

  meta = {
    description = "Tool for building, changing, and versioning infrastructure";
    homepage = "https://opentofu.org/";
    license = lib.licenses.mpl20;
    mainProgram = "tofu";
  };
}
